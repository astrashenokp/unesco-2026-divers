"""Authorized read-side adapters for receipt and progress projections."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from data_access.schema import attempts, learner_progress, receipts, skill_states
from evidence_gym_api.learning.attempt import AxisAssessment, Confidence
from evidence_gym_api.learning.ports import ProgressResult, SkillProgress
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.receipt.model import EvidenceReceipt


class SqlAlchemyReceiptReader:
    """Read a receipt only when the caller owns its attempt.

    The ownership filter is applied inside the query, so a missing and a
    foreign receipt both surface as ``None`` and never reveal whether a
    receipt exists under another learner.
    """

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_for_learner(
        self, receipt_id: str, learner_id: LearnerId
    ) -> EvidenceReceipt | None:
        result = await self.session.execute(
            select(receipts, attempts.c.learner_id)
            .join(attempts, attempts.c.id == receipts.c.attempt_id)
            .where(receipts.c.id == receipt_id, attempts.c.learner_id == str(learner_id))
        )
        row = result.mappings().one_or_none()
        if row is None:
            return None
        payload = row["payload_json"]
        return EvidenceReceipt(
            id=row["id"],
            attempt_id=row["attempt_id"],
            mission_version=row["mission_version"],
            assessments=tuple(
                AxisAssessment(item["label"], Confidence.known(int(item["confidence"])))
                for item in payload["assessments"]
            ),
            evidence_refs=tuple(payload["evidenceRefs"]),
            created_at=row["created_at"],
            hash=row["hash"],
            disclaimer=payload["disclaimer"],
        )


class SqlAlchemyProgressReader:
    """Project cumulative XP and skill states for one learner."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_for_learner(self, learner_id: LearnerId) -> ProgressResult:
        total_row = await self.session.execute(
            select(learner_progress.c.total_xp).where(
                learner_progress.c.learner_id == str(learner_id)
            )
        )
        total_xp = total_row.scalar_one_or_none() or 0
        skills_result = await self.session.execute(
            select(skill_states)
            .where(skill_states.c.learner_id == str(learner_id))
            .order_by(skill_states.c.skill)
        )
        skills = tuple(
            SkillProgress(
                skill=row["skill"],
                mastery=row["mastery"],
                due_at=row["due_at"],
            )
            for row in skills_result.mappings()
        )
        return ProgressResult(total_xp=total_xp, skills=skills)
