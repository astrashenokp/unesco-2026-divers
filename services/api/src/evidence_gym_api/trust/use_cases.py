"""Authenticated, idempotent learner content report submission."""

from dataclasses import dataclass
from datetime import timedelta
from hashlib import sha256
import json

from data_access.errors import DataAccessError
from data_access.reports import ReportRepository, StoredReportResult, SubmittedReport
from sqlalchemy.exc import SQLAlchemyError

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.errors import IdempotencyConflict, RepositoryConflict
from evidence_gym_api.learning.ports import Clock, IdempotencyScope, TransactionManager
from evidence_gym_api.learning.value_objects import IdempotencyKey, MissionId
from evidence_gym_api.trust.errors import ReportPersistenceUnavailable
from evidence_gym_api.trust.ports import MissionVersionResolver, ReportIdGenerator

REPORT_IDEMPOTENCY_RETENTION = timedelta(hours=24)


def _fingerprint(*, mission_id: MissionId, reason: str, detail: str | None) -> str:
    payload = {
        "detail": detail,
        "missionId": mission_id.value,
        "reason": reason,
    }
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return sha256(encoded).hexdigest()


@dataclass(frozen=True, slots=True)
class SubmitReportCommand:
    mission_id: MissionId
    reason: str
    detail: str | None
    idempotency_key: IdempotencyKey


class SubmitReport:
    """Durably accept a report and replay the original acceptance on retry."""

    def __init__(
        self,
        reports: ReportRepository,
        versions: MissionVersionResolver,
        ids: ReportIdGenerator,
        transactions: TransactionManager,
        clock: Clock,
    ) -> None:
        self._reports = reports
        self._versions = versions
        self._ids = ids
        self._transactions = transactions
        self._clock = clock

    async def execute(
        self, principal: Principal, command: SubmitReportCommand
    ) -> SubmittedReport:
        fingerprint = _fingerprint(
            mission_id=command.mission_id,
            reason=command.reason,
            detail=command.detail,
        )
        scope = IdempotencyScope(
            principal.subject,
            "/reports",
            command.idempotency_key,
        )
        try:
            async with self._transactions.transaction():
                now = self._clock.now()
                stored = await self._reports.get(scope, at=now)
                if stored is not None:
                    if stored.request_fingerprint != fingerprint:
                        raise IdempotencyConflict(
                            "idempotency key was reused with another report"
                        )
                    return stored.report

                mission_version = await self._versions.resolve(command.mission_id)
                report = SubmittedReport(
                    report_id=self._ids.new(),
                    reporter_id=principal.subject.value,
                    mission_id=command.mission_id.value,
                    mission_version=(
                        mission_version.value if mission_version is not None else None
                    ),
                    reason=command.reason,
                    detail=command.detail,
                    submitted_at=now,
                )
                await self._reports.put(
                    scope,
                    StoredReportResult(
                        request_fingerprint=fingerprint,
                        report=report,
                        expires_at=now + REPORT_IDEMPOTENCY_RETENTION,
                    ),
                )
                return report
        except RepositoryConflict as exc:
            raise IdempotencyConflict(
                "idempotency key was reused with another report"
            ) from exc
        except IdempotencyConflict:
            raise
        except (DataAccessError, SQLAlchemyError) as exc:
            raise ReportPersistenceUnavailable(
                "report could not be durably committed"
            ) from exc
