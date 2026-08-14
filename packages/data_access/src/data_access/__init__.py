"""PostgreSQL persistence adapters for the Evidence Gym modular monolith."""

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.completion import SqlAlchemyAtomicCompletionWriter
from data_access.db import Database, SqlAlchemyTransactionManager
from data_access.idempotency import (
    SqlAlchemyCompletionIdempotencyRepository,
    SqlAlchemyEvidenceIdempotencyRepository,
    SqlAlchemyHintIdempotencyRepository,
    SqlAlchemyIdempotencyRepository,
    cleanup_expired_idempotency,
)
from data_access.readers import SqlAlchemyProgressReader, SqlAlchemyReceiptReader
from data_access.readiness import DatabaseReadinessProbe
from data_access.reports import (
    ReportRepository,
    SqlAlchemyReportRepository,
    StoredReportResult,
    SubmittedReport,
)

__all__ = [
    "Database",
    "DatabaseReadinessProbe",
    "ReportRepository",
    "SqlAlchemyAtomicCompletionWriter",
    "SqlAlchemyAttemptRepository",
    "SqlAlchemyCompletionIdempotencyRepository",
    "SqlAlchemyEvidenceIdempotencyRepository",
    "SqlAlchemyHintIdempotencyRepository",
    "SqlAlchemyIdempotencyRepository",
    "SqlAlchemyProgressReader",
    "SqlAlchemyReceiptReader",
    "SqlAlchemyReportRepository",
    "SqlAlchemyTransactionManager",
    "StoredReportResult",
    "SubmittedReport",
    "cleanup_expired_idempotency",
]
