"""Attempt repository backed by SQLAlchemy Core."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import delete, insert, select, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from data_access.codec import decode_attempt, encode_attempt
from data_access.schema import attempts, evidence_actions
from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.value_objects import AttemptId


def _row_to_attempt(row: dict[str, object], action_refs: tuple[str, ...]) -> Attempt:
    snapshot = {
        "id": row["id"],
        "learner_id": row["learner_id"],
        "mission_id": row["mission_id"],
        "mission_version": row["mission_version"],
        "allows_no_evidence_conclusion": row["allows_no_evidence_conclusion"],
        "minimum_required_evidence_actions": row["minimum_required_evidence_actions"],
        "state": row["state"],
        "version": row["version"],
        "prediction": row["prediction_json"],
        "evidence_action_refs": list(action_refs),
        "conclusion": row["conclusion_json"],
    }
    return decode_attempt(snapshot)


class SqlAlchemyAttemptRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, attempt_id: AttemptId) -> Attempt | None:
        result = await self.session.execute(
            select(attempts).where(attempts.c.id == str(attempt_id))
        )
        row = result.mappings().one_or_none()
        if row is None:
            return None
        actions = await self.session.execute(
            select(evidence_actions.c.action_ref)
            .where(evidence_actions.c.attempt_id == str(attempt_id))
            .order_by(evidence_actions.c.ordinal)
        )
        return _row_to_attempt(row, tuple(item[0] for item in actions.all()))

    async def add(self, attempt: Attempt) -> None:
        snapshot = encode_attempt(attempt)
        now = datetime.now(UTC)
        values = {
            "id": str(attempt.id),
            "learner_id": str(attempt.learner_id),
            "mission_id": str(attempt.mission_id),
            "mission_version": str(attempt.mission_version),
            "allows_no_evidence_conclusion": attempt.allows_no_evidence_conclusion,
            "minimum_required_evidence_actions": attempt.minimum_required_evidence_actions,
            "state": attempt.state.value,
            "version": attempt.version,
            "prediction_json": snapshot["prediction"],
            "evidence_action_refs": snapshot["evidence_action_refs"],
            "conclusion_json": snapshot["conclusion"],
            "created_at": now,
            "updated_at": now,
        }
        try:
            await self.session.execute(insert(attempts).values(**values))
            await self._replace_action_refs(attempt, now)
            await self.session.flush()
        except IntegrityError as exc:
            raise RepositoryConflict("attempt already exists or violates a constraint") from exc
        except SQLAlchemyError as exc:
            raise RepositoryConflict("attempt could not be stored") from exc

    async def save(self, attempt: Attempt, *, expected_version: int) -> None:
        if attempt.version != expected_version + 1:
            raise RepositoryConflict("attempt version must advance exactly once")
        snapshot = encode_attempt(attempt)
        now = datetime.now(UTC)
        statement = (
            update(attempts)
            .where(attempts.c.id == str(attempt.id), attempts.c.version == expected_version)
            .values(
                state=attempt.state.value,
                version=attempt.version,
                prediction_json=snapshot["prediction"],
                evidence_action_refs=snapshot["evidence_action_refs"],
                conclusion_json=snapshot["conclusion"],
                updated_at=now,
            )
        )
        try:
            result = await self.session.execute(statement)
            if result.rowcount != 1:
                raise RepositoryConflict("attempt version changed concurrently")
            await self._replace_action_refs(attempt, now)
            await self.session.flush()
        except RepositoryConflict:
            raise
        except IntegrityError as exc:
            raise RepositoryConflict("attempt violates a constraint") from exc
        except SQLAlchemyError as exc:
            raise RepositoryConflict("attempt could not be saved") from exc

    async def _replace_action_refs(self, attempt: Attempt, now: datetime) -> None:
        await self.session.execute(
            delete(evidence_actions).where(evidence_actions.c.attempt_id == str(attempt.id))
        )
        if attempt.evidence_action_refs:
            await self.session.execute(
                insert(evidence_actions),
                [
                    {
                        "attempt_id": str(attempt.id),
                        "action_ref": action_ref,
                        "ordinal": ordinal,
                        "created_at": now,
                    }
                    for ordinal, action_ref in enumerate(attempt.evidence_action_refs)
                ],
            )
