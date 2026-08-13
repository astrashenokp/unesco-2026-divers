"""Single-transaction PostgreSQL completion writer."""

from __future__ import annotations

from datetime import UTC, datetime
from hashlib import sha256
import json
from uuid import uuid4
from typing import Protocol

from sqlalchemy import insert, select, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from data_access.codec import encode_attempt
from data_access.schema import (
    attempts,
    conclusions,
    learner_progress,
    outbox,
    receipts,
    skill_states,
    xp_ledger,
)
from evidence_gym_api.learning.attempt import Attempt, Conclusion
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    CompletionResult,
    CompletionScorer,
    SkillProgress,
    ProgressResult,
)
from gameplay import SkillState, practice


class ProcessPolicyReader(Protocol):
    async def get_process_levels(self, mission_id, mission_version): ...


class SqlAlchemyAtomicCompletionWriter:
    """Persist the final completion snapshot without durable intermediate states."""

    def __init__(
        self,
        session: AsyncSession,
        scorer: CompletionScorer,
        policies: ProcessPolicyReader | None = None,
    ) -> None:
        self.session = session
        self.scorer = scorer
        self.policies = policies

    async def complete(
        self,
        attempt: Attempt,
        conclusion: Conclusion,
        *,
        expected_version: int,
        completed_at: datetime,
    ) -> CompletionResult:
        if attempt.version != expected_version:
            raise RepositoryConflict("attempt version changed before completion")

        attempt.submit_conclusion(conclusion)
        attempt.complete()
        award = await self.scorer.award(
            attempt.mission_id,
            attempt.mission_version,
            len(attempt.evidence_action_refs),
        )
        now = self._utc(completed_at)
        receipt_id = f"receipt-{attempt.id.value}"
        receipt_payload = self._receipt_payload(attempt, conclusion, receipt_id, now)
        receipt_hash = sha256(
            json.dumps(receipt_payload, sort_keys=True, separators=(",", ":")).encode()
        ).hexdigest()

        snapshot = encode_attempt(attempt)
        try:
            result = await self.session.execute(
                update(attempts)
                .where(attempts.c.id == str(attempt.id), attempts.c.version == expected_version)
                .values(
                    state="completed",
                    version=attempt.version,
                    prediction_json=snapshot["prediction"],
                    evidence_action_refs=snapshot["evidence_action_refs"],
                    conclusion_json=snapshot["conclusion"],
                    updated_at=now,
                )
            )
            if result.rowcount != 1:
                raise RepositoryConflict("attempt version changed concurrently")

            await self.session.execute(
                insert(conclusions).values(
                    attempt_id=str(attempt.id),
                    mission_version=str(attempt.mission_version),
                    authenticity_json=self._axis(conclusion.authenticity),
                    claim_veracity_json=self._axis(conclusion.claim_veracity),
                    context_integrity_json=self._axis(conclusion.context_integrity),
                    post_confidence=conclusion.post_confidence.value,
                    share_decision=conclusion.share_decision.value,
                    created_at=now,
                )
            )
            await self.session.execute(
                insert(xp_ledger).values(
                    learner_id=str(attempt.learner_id),
                    attempt_id=str(attempt.id),
                    rule_code=award.rule_code,
                    amount=award.amount,
                    level=award.level,
                    created_at=now,
                )
            )
            skills = await self._update_skills(attempt, award.level, now)
            total_xp = await self._update_progress(str(attempt.learner_id), award.amount, now)
            await self.session.execute(
                insert(receipts).values(
                    id=receipt_id,
                    attempt_id=str(attempt.id),
                    mission_version=str(attempt.mission_version),
                    payload_json={**receipt_payload, "hash": receipt_hash},
                    hash=receipt_hash,
                    created_at=now,
                )
            )
            await self.session.execute(
                insert(outbox).values(
                    event_id=str(uuid4()),
                    event_type="mission.completed.v1",
                    occurred_at=now,
                    producer="learning",
                    subject_id=str(attempt.id),
                    correlation_id=f"completion:{attempt.id}",
                    schema_version=1,
                    payload={
                        "attemptId": str(attempt.id),
                        "missionId": str(attempt.mission_id),
                        "missionVersion": str(attempt.mission_version),
                        "xp": {
                            "ruleCode": award.rule_code,
                            "amount": award.amount,
                            "level": award.level,
                        },
                    },
                )
            )
            await self.session.flush()
        except RepositoryConflict:
            raise
        except IntegrityError as exc:
            raise RepositoryConflict("completion violates a persistence constraint") from exc
        except SQLAlchemyError as exc:
            raise RepositoryConflict("completion could not be persisted") from exc

        return CompletionResult(
            receipt_id=receipt_id,
            xp_awarded=award.amount,
            progress=ProgressResult(total_xp=total_xp, skills=skills),
        )

    async def _update_skills(
        self, attempt: Attempt, level: int, now: datetime
    ) -> tuple[SkillProgress, ...]:
        if self.policies is None:
            return ()
        levels = await self.policies.get_process_levels(
            attempt.mission_id, attempt.mission_version
        )
        if levels is None or level >= len(levels):
            return ()
        tags = tuple(dict.fromkeys(levels[level].skill_tags))
        progress: list[SkillProgress] = []
        for skill in tags:
            result = await self.session.execute(
                select(skill_states)
                .where(
                    skill_states.c.learner_id == str(attempt.learner_id),
                    skill_states.c.skill == skill,
                )
                .with_for_update()
            )
            row = result.mappings().one_or_none()
            if row is None:
                state = SkillState(skill=skill, mastery=0.0)
            else:
                state = SkillState(
                    skill=skill,
                    mastery=float(row["mastery"]),
                    practices=row["practices"],
                    due_at=row["due_at"],
                    algorithm_version=row["algorithm_version"],
                )
            updated = practice(state, now)
            values = {
                "learner_id": str(attempt.learner_id),
                "skill": updated.skill,
                "mastery": updated.mastery,
                "practices": updated.practices,
                "due_at": updated.due_at,
                "algorithm_version": updated.algorithm_version,
                "updated_at": now,
            }
            if row is None:
                await self.session.execute(insert(skill_states).values(**values))
            else:
                await self.session.execute(
                    update(skill_states)
                    .where(
                        skill_states.c.learner_id == str(attempt.learner_id),
                        skill_states.c.skill == skill,
                    )
                    .values(**values)
                )
            progress.append(
                SkillProgress(skill=updated.skill, mastery=updated.mastery, due_at=updated.due_at)
            )
        return tuple(progress)

    async def _update_progress(self, learner_id: str, amount: int, now: datetime) -> int:
        existing = await self.session.execute(
            select(learner_progress)
            .where(learner_progress.c.learner_id == learner_id)
            .with_for_update()
        )
        row = existing.mappings().one_or_none()
        if row is None:
            total = amount
            await self.session.execute(
                insert(learner_progress).values(
                    learner_id=learner_id,
                    total_xp=total,
                    updated_at=now,
                )
            )
            return total
        total = row["total_xp"] + amount
        await self.session.execute(
            update(learner_progress)
            .where(learner_progress.c.learner_id == learner_id)
            .values(total_xp=total, updated_at=now)
        )
        return total

    @staticmethod
    def _utc(value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _axis(axis: object) -> dict[str, object]:
        return {
            "label": axis.label,
            "confidence": axis.confidence.value,
        }

    @classmethod
    def _receipt_payload(
        cls, attempt: Attempt, conclusion: Conclusion, receipt_id: str, created_at: datetime
    ) -> dict[str, object]:
        return {
            "id": receipt_id,
            "attemptId": str(attempt.id),
            "missionVersion": str(attempt.mission_version),
            "evidenceRefs": list(attempt.evidence_action_refs),
            "assessments": [
                cls._axis(conclusion.authenticity),
                cls._axis(conclusion.claim_veracity),
                cls._axis(conclusion.context_integrity),
            ],
            "postConfidence": conclusion.post_confidence.value,
            "shareDecision": conclusion.share_decision.value,
            "createdAt": created_at.isoformat(),
            "disclaimer": "This receipt records a learning process, not a universal truth verdict.",
        }
