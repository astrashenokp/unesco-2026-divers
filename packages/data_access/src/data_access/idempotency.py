"""TTL-bound idempotency repositories backed by PostgreSQL."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from data_access.codec import (
    decode_attempt,
    decode_coach_hint,
    decode_evidence_result,
    encode_attempt,
    encode_coach_hint,
    encode_evidence_result,
)
from data_access.schema import idempotency_results
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    EvidenceActionResult,
    IdempotencyScope,
    StoredAttemptResult,
    StoredEvidenceResult,
    StoredHintResult,
)


class _IdempotencyRepository:
    result_kind: str

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    @staticmethod
    def _utc(value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    async def _row(self, scope: IdempotencyScope, *, at: datetime) -> Any | None:
        result = await self.session.execute(
            select(idempotency_results).where(
                idempotency_results.c.route == scope.route,
                idempotency_results.c.learner_id == str(scope.learner_id),
                idempotency_results.c.key == str(scope.key),
                idempotency_results.c.expires_at > at,
            )
        )
        return result.mappings().one_or_none()

    async def _put(
        self,
        scope: IdempotencyScope,
        fingerprint: str,
        result_json: dict[str, Any],
        expires_at: datetime,
    ) -> None:
        now = datetime.now(UTC)
        existing = await self.session.execute(
            select(idempotency_results).where(
                idempotency_results.c.route == scope.route,
                idempotency_results.c.learner_id == str(scope.learner_id),
                idempotency_results.c.key == str(scope.key),
            )
        )
        row = existing.mappings().one_or_none()
        if row is not None and self._utc(row["expires_at"]) <= now:
            await self.session.execute(
                delete(idempotency_results).where(idempotency_results.c.id == row["id"])
            )
            row = None

        if row is not None:
            if row["request_fingerprint"] == fingerprint and row["result_json"] == result_json:
                return
            raise RepositoryConflict("idempotency scope already contains a different result")

        try:
            async with self.session.begin_nested():
                await self.session.execute(
                    idempotency_results.insert().values(
                        route=scope.route,
                        learner_id=str(scope.learner_id),
                        key=str(scope.key),
                        result_kind=self.result_kind,
                        request_fingerprint=fingerprint,
                        result_json=result_json,
                        expires_at=expires_at,
                        created_at=now,
                    )
                )
                await self.session.flush()
        except IntegrityError as exc:
            concurrent = await self.session.execute(
                select(idempotency_results).where(
                    idempotency_results.c.route == scope.route,
                    idempotency_results.c.learner_id == str(scope.learner_id),
                    idempotency_results.c.key == str(scope.key),
                )
            )
            concurrent_row = concurrent.mappings().one_or_none()
            if (
                concurrent_row is not None
                and concurrent_row["request_fingerprint"] == fingerprint
                and concurrent_row["result_json"] == result_json
            ):
                return
            raise RepositoryConflict("idempotency scope already exists") from exc


class SqlAlchemyIdempotencyRepository(_IdempotencyRepository):
    result_kind = "attempt"

    async def get(self, scope: IdempotencyScope, *, at: datetime) -> StoredAttemptResult | None:
        row = await self._row(scope, at=at)
        if row is None:
            return None
        return StoredAttemptResult(
            request_fingerprint=row["request_fingerprint"],
            attempt=decode_attempt(row["result_json"]["attempt"]),
            expires_at=self._utc(row["expires_at"]),
        )

    async def put(self, scope: IdempotencyScope, result: StoredAttemptResult) -> None:
        await self._put(
            scope,
            result.request_fingerprint,
            {"attempt": encode_attempt(result.attempt)},
            result.expires_at,
        )


class SqlAlchemyEvidenceIdempotencyRepository(_IdempotencyRepository):
    result_kind = "evidence"

    async def get_evidence(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredEvidenceResult | None:
        row = await self._row(scope, at=at)
        if row is None:
            return None
        value = row["result_json"]
        return StoredEvidenceResult(
            request_fingerprint=row["request_fingerprint"],
            result=EvidenceActionResult(
                evidence=decode_evidence_result(value["evidence"]),
                attempt_version=value["attempt_version"],
            ),
            expires_at=self._utc(row["expires_at"]),
        )

    async def put_evidence(self, scope: IdempotencyScope, result: StoredEvidenceResult) -> None:
        await self._put(
            scope,
            result.request_fingerprint,
            {
                "evidence": encode_evidence_result(result.result.evidence),
                "attempt_version": result.result.attempt_version,
            },
            result.expires_at,
        )


class SqlAlchemyHintIdempotencyRepository(_IdempotencyRepository):
    result_kind = "hint"

    async def get_hint(self, scope: IdempotencyScope, *, at: datetime) -> StoredHintResult | None:
        row = await self._row(scope, at=at)
        if row is None:
            return None
        return StoredHintResult(
            request_fingerprint=row["request_fingerprint"],
            result=decode_coach_hint(row["result_json"]["hint"]),
            expires_at=self._utc(row["expires_at"]),
        )

    async def put_hint(self, scope: IdempotencyScope, result: StoredHintResult) -> None:
        await self._put(
            scope,
            result.request_fingerprint,
            {"hint": encode_coach_hint(result.result)},
            result.expires_at,
        )


async def cleanup_expired_idempotency(session: AsyncSession, *, at: datetime) -> int:
    """Delete expired replay snapshots and return the affected row count."""
    result = await session.execute(
        delete(idempotency_results).where(idempotency_results.c.expires_at <= at)
    )
    await session.flush()
    return result.rowcount
