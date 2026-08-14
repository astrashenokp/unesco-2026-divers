"""PostgreSQL runtime composition for learning, receipt, progress and reports.

Each HTTP request binds exactly one use case, so every request opens its
own ``AsyncSession`` and closes it once the response is sent. Heavy
providers (scorer, evidence, coach) are built once per factory and reused
across requests; only the SQLAlchemy adapters are bound per session.

``data_access`` imports are deferred to method bodies on purpose: the
package's own modules import ``evidence_gym_api`` (via the codec), so
importing them at module level here would form an import cycle.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession

from evidence_gym_api.coach.fixture_provider import FixtureCoachProvider
from evidence_gym_api.evidence import FixtureDeterministicEvidenceProvider
from evidence_gym_api.learning.gameplay_adapter import GameplayCompletionScorer
from evidence_gym_api.learning.in_memory import SystemClock
from evidence_gym_api.learning.use_cases import (
    CompleteAttempt,
    RequestHint,
    StartAttempt,
    SubmitPrediction,
    UseEvidenceAction,
)
from evidence_gym_api.learning.value_objects import AttemptId
from evidence_gym_api.progress.use_cases import GetMyProgress
from evidence_gym_api.receipt.use_cases import GetReceipt

if TYPE_CHECKING:
    from data_access.attempts import SqlAlchemyAttemptRepository
    from data_access.completion import SqlAlchemyAtomicCompletionWriter
    from data_access.db import SqlAlchemyTransactionManager
    from data_access.idempotency import (
        SqlAlchemyCompletionIdempotencyRepository,
        SqlAlchemyEvidenceIdempotencyRepository,
        SqlAlchemyHintIdempotencyRepository,
        SqlAlchemyIdempotencyRepository,
    )
    from data_access.readers import SqlAlchemyProgressReader, SqlAlchemyReceiptReader
    from evidence_gym_api.catalog import FileMissionPolicyReader
    from evidence_gym_api.learning.api import LearningServices
    from evidence_gym_api.progress.api import ProgressServices
    from evidence_gym_api.receipt.api import ReceiptServices
    from evidence_gym_api.trust.api import ReportServices


class UuidAttemptIdGenerator:
    """Globally unique attempt identifiers for durable persistence.

    A per-process counter would collide across app instances and restarts
    once attempts survive in PostgreSQL, so the persistent composition
    uses a UUID suffix.
    """

    def new(self) -> AttemptId:
        return AttemptId(f"attempt-pg-{uuid4().hex}")


class UuidReportIdGenerator:
    """Globally unique identifiers for durable learner reports."""

    def new(self) -> str:
        return f"report-{uuid4().hex}"


class ServicesFactory:
    """Build per-request services over one isolated PostgreSQL session."""

    def __init__(self, policy_reader: "FileMissionPolicyReader") -> None:
        self._policy_reader = policy_reader
        self._scorer = GameplayCompletionScorer(policy_reader)
        self._evidence_provider = FixtureDeterministicEvidenceProvider(policy_reader)
        self._coach_provider = FixtureCoachProvider(policy_reader)

    def learning(self, session: AsyncSession) -> "LearningServices":
        from data_access.attempts import SqlAlchemyAttemptRepository
        from data_access.completion import SqlAlchemyAtomicCompletionWriter
        from data_access.db import SqlAlchemyTransactionManager
        from data_access.idempotency import (
            SqlAlchemyCompletionIdempotencyRepository,
            SqlAlchemyEvidenceIdempotencyRepository,
            SqlAlchemyHintIdempotencyRepository,
            SqlAlchemyIdempotencyRepository,
        )
        from evidence_gym_api.learning.api import LearningServices

        attempts = SqlAlchemyAttemptRepository(session)
        idempotency = SqlAlchemyIdempotencyRepository(session)
        evidence_idempotency = SqlAlchemyEvidenceIdempotencyRepository(session)
        hint_idempotency = SqlAlchemyHintIdempotencyRepository(session)
        completion_idempotency = SqlAlchemyCompletionIdempotencyRepository(session)
        transactions = SqlAlchemyTransactionManager(session)
        clock = SystemClock()
        completion_writer = SqlAlchemyAtomicCompletionWriter(
            session, self._scorer, policies=self._policy_reader
        )
        return LearningServices(
            start_attempt=StartAttempt(
                attempts,
                self._policy_reader,
                idempotency,
                UuidAttemptIdGenerator(),
                transactions,
                clock,
            ),
            submit_prediction=SubmitPrediction(
                attempts, idempotency, transactions, clock
            ),
            use_evidence_action=UseEvidenceAction(
                attempts,
                self._evidence_provider,
                evidence_idempotency,
                transactions,
                clock,
            ),
            request_hint=RequestHint(
                attempts,
                self._policy_reader,
                self._coach_provider,
                hint_idempotency,
                transactions,
                clock,
            ),
            complete_attempt=CompleteAttempt(
                attempts,
                completion_writer,
                completion_idempotency,
                transactions,
                clock,
            ),
        )

    def receipt(self, session: AsyncSession) -> "ReceiptServices":
        from data_access.readers import SqlAlchemyReceiptReader
        from evidence_gym_api.receipt.api import ReceiptServices

        return ReceiptServices(
            get_receipt=GetReceipt(SqlAlchemyReceiptReader(session))
        )

    def progress(self, session: AsyncSession) -> "ProgressServices":
        from data_access.readers import SqlAlchemyProgressReader
        from evidence_gym_api.progress.api import ProgressServices

        return ProgressServices(
            get_my_progress=GetMyProgress(SqlAlchemyProgressReader(session))
        )

    def reports(self, session: AsyncSession) -> "ReportServices":
        from data_access.db import SqlAlchemyTransactionManager
        from data_access.reports import SqlAlchemyReportRepository
        from evidence_gym_api.trust.api import ReportServices
        from evidence_gym_api.trust.catalog_adapter import CatalogMissionVersionResolver
        from evidence_gym_api.trust.use_cases import SubmitReport

        return ReportServices(
            submit_report=SubmitReport(
                SqlAlchemyReportRepository(session),
                CatalogMissionVersionResolver(self._policy_reader),
                UuidReportIdGenerator(),
                SqlAlchemyTransactionManager(session),
                SystemClock(),
            )
        )
