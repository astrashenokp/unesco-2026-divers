"""Single-transaction durable persistence for learner content reports.

A submitted report, its idempotency record and a `report.submitted.v1` outbox
event are written in one database transaction. A `202` may only be returned
after this transaction commits; when persistence is unavailable the adapter
raises `DataAccessError` so the application boundary can answer `503` instead
of accepting a report it cannot stand behind.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any, Protocol
from uuid import uuid4

from sqlalchemy import delete, insert, select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from data_access.errors import DataAccessError
from data_access.schema import idempotency_results, outbox, reports
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import IdempotencyScope

REPORT_REASONS = ("incorrect", "harmful", "outdated", "copyright", "accessibility", "other")
REPORT_DETAIL_LIMIT = 1000


@dataclass(frozen=True)
class SubmittedReport:
    """Durable record of an accepted learner report."""

    report_id: str
    reporter_id: str
    mission_id: str
    mission_version: str | None
    reason: str
    detail: str | None
    submitted_at: datetime


@dataclass(frozen=True)
class StoredReportResult:
    """Replay snapshot bound to an idempotency scope."""

    request_fingerprint: str
    report: SubmittedReport
    expires_at: datetime


class ReportRepository(Protocol):
    """Persistence port Role 2 consumes from the trust application boundary."""

    async def get(self, scope: IdempotencyScope, *, at: datetime) -> StoredReportResult | None: ...

    async def put(self, scope: IdempotencyScope, result: StoredReportResult) -> None: ...


def _encode_report(report: SubmittedReport) -> dict[str, Any]:
    if report.submitted_at.tzinfo is None or report.submitted_at.utcoffset() is None:
        raise ValueError("report timestamp must be timezone-aware")
    return {
        "report_id": report.report_id,
        "reporter_id": report.reporter_id,
        "mission_id": report.mission_id,
        "mission_version": report.mission_version,
        "reason": report.reason,
        "detail": report.detail,
        "submitted_at": report.submitted_at.isoformat(),
    }


def _decode_report(value: dict[str, Any]) -> SubmittedReport:
    return SubmittedReport(
        report_id=value["report_id"],
        reporter_id=value["reporter_id"],
        mission_id=value["mission_id"],
        mission_version=value.get("mission_version"),
        reason=value["reason"],
        detail=value.get("detail"),
        submitted_at=datetime.fromisoformat(value["submitted_at"]),
    )


class SqlAlchemyReportRepository:
    """PostgreSQL adapter for durable report submission with idempotency."""

    result_kind = "report"

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, scope: IdempotencyScope, *, at: datetime) -> StoredReportResult | None:
        row = await self._row(scope, at=at)
        if row is None:
            return None
        return StoredReportResult(
            request_fingerprint=row["request_fingerprint"],
            report=_decode_report(row["result_json"]["report"]),
            expires_at=self._utc(row["expires_at"]),
        )

    async def put(self, scope: IdempotencyScope, result: StoredReportResult) -> None:
        self._validate(result.report)
        now = datetime.now(UTC)
        result_json = {"report": _encode_report(result.report)}

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
            if row["request_fingerprint"] == result.request_fingerprint:
                return
            raise RepositoryConflict("idempotency scope already contains a different report")

        try:
            async with self.session.begin_nested():
                await self._insert_report(result.report, now)
                await self._insert_event(result.report, now)
                await self.session.execute(
                    idempotency_results.insert().values(
                        route=scope.route,
                        learner_id=str(scope.learner_id),
                        key=str(scope.key),
                        result_kind=self.result_kind,
                        request_fingerprint=result.request_fingerprint,
                        result_json=result_json,
                        expires_at=result.expires_at,
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
                and concurrent_row["request_fingerprint"] == result.request_fingerprint
            ):
                return
            raise RepositoryConflict(
                "idempotency scope already contains a different report"
            ) from exc
        except SQLAlchemyError as exc:
            raise DataAccessError("report could not be durably stored") from exc

    async def _insert_report(self, report: SubmittedReport, now: datetime) -> None:
        await self.session.execute(
            insert(reports).values(
                id=report.report_id,
                reporter_id=report.reporter_id,
                mission_id=report.mission_id,
                mission_version=report.mission_version,
                reason=report.reason,
                detail=report.detail,
                status="pending",
                created_at=now,
            )
        )

    async def _insert_event(self, report: SubmittedReport, now: datetime) -> None:
        await self.session.execute(
            insert(outbox).values(
                event_id=str(uuid4()),
                event_type="report.submitted.v1",
                occurred_at=now,
                producer="trust",
                subject_id=report.report_id,
                correlation_id=f"report:{report.report_id}",
                schema_version=1,
                payload={
                    "reportId": report.report_id,
                    "missionId": report.mission_id,
                    "missionVersion": report.mission_version,
                    "reason": report.reason,
                    "submittedAt": now.isoformat(),
                },
            )
        )

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

    @staticmethod
    def _utc(value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _validate(report: SubmittedReport) -> None:
        if report.reason not in REPORT_REASONS:
            raise ValueError(f"unsupported report reason: {report.reason!r}")
        if report.detail is not None and len(report.detail) > REPORT_DETAIL_LIMIT:
            raise ValueError("report detail exceeds the allowed length")
