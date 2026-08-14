"""Application tests for durable learner report submission."""

from contextlib import asynccontextmanager
from copy import deepcopy
from datetime import UTC, datetime
import asyncio

import pytest

from data_access.errors import DataAccessError
from data_access.reports import StoredReportResult
from sqlalchemy.exc import SQLAlchemyError
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.errors import IdempotencyConflict, RepositoryConflict
from evidence_gym_api.learning.in_memory import FixedClock
from evidence_gym_api.learning.value_objects import (
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)
from evidence_gym_api.trust.errors import ReportPersistenceUnavailable
from evidence_gym_api.trust.use_cases import SubmitReport, SubmitReportCommand


class MemoryReportRepository:
    def __init__(self) -> None:
        self.results = {}
        self.put_calls = 0
        self.failure: Exception | None = None

    async def get(self, scope, *, at):
        if self.failure is not None:
            raise self.failure
        result = self.results.get(scope)
        if result is not None and result.expires_at <= at:
            del self.results[scope]
            return None
        return deepcopy(result)

    async def put(self, scope, result: StoredReportResult) -> None:
        if self.failure is not None:
            raise self.failure
        self.put_calls += 1
        existing = self.results.get(scope)
        if existing is not None and existing.request_fingerprint != result.request_fingerprint:
            raise RepositoryConflict("different report already exists")
        self.results[scope] = deepcopy(result)


class FixedVersionResolver:
    async def resolve(self, mission_id):
        if mission_id == MissionId("mission-one"):
            return MissionVersion("0.1.0")
        return None


class SequentialReportIds:
    def __init__(self) -> None:
        self.value = 0

    def new(self) -> str:
        self.value += 1
        return f"report-{self.value}"


class RecordingTransactions:
    def __init__(self) -> None:
        self.entries = 0

    @asynccontextmanager
    async def transaction(self):
        self.entries += 1
        yield


def command(*, detail: str | None = "Needs review") -> SubmitReportCommand:
    return SubmitReportCommand(
        mission_id=MissionId("mission-one"),
        reason="incorrect",
        detail=detail,
        idempotency_key=IdempotencyKey("report-key-one"),
    )


def use_case(repository: MemoryReportRepository):
    transactions = RecordingTransactions()
    return (
        SubmitReport(
            repository,
            FixedVersionResolver(),
            SequentialReportIds(),
            transactions,
            FixedClock(datetime(2026, 8, 14, 12, 0, tzinfo=UTC)),
        ),
        transactions,
    )


def test_submit_report_derives_reporter_and_pins_catalog_version() -> None:
    repository = MemoryReportRepository()
    submit, transactions = use_case(repository)

    report = asyncio.run(
        submit.execute(Principal(LearnerId("verified-learner")), command())
    )

    assert report.reporter_id == "verified-learner"
    assert report.mission_id == "mission-one"
    assert report.mission_version == "0.1.0"
    assert report.reason == "incorrect"
    assert report.detail == "Needs review"
    assert repository.put_calls == 1
    assert transactions.entries == 1


def test_same_key_and_content_replays_original_report() -> None:
    repository = MemoryReportRepository()
    submit, _ = use_case(repository)
    principal = Principal(LearnerId("verified-learner"))

    first = asyncio.run(submit.execute(principal, command()))
    replay = asyncio.run(submit.execute(principal, command()))

    assert replay == first
    assert repository.put_calls == 1


def test_same_key_with_different_content_is_conflict() -> None:
    repository = MemoryReportRepository()
    submit, _ = use_case(repository)
    principal = Principal(LearnerId("verified-learner"))
    asyncio.run(submit.execute(principal, command()))

    with pytest.raises(IdempotencyConflict):
        asyncio.run(submit.execute(principal, command(detail="Different content")))

    assert repository.put_calls == 1


def test_repository_race_conflict_maps_to_idempotency_conflict() -> None:
    repository = MemoryReportRepository()
    repository.failure = RepositoryConflict("concurrent key conflict")
    submit, _ = use_case(repository)

    with pytest.raises(IdempotencyConflict):
        asyncio.run(
            submit.execute(Principal(LearnerId("verified-learner")), command())
        )


def test_persistence_failure_maps_to_safe_report_failure() -> None:
    repository = MemoryReportRepository()
    repository.failure = DataAccessError("database contains sensitive diagnostics")
    submit, _ = use_case(repository)

    with pytest.raises(ReportPersistenceUnavailable) as raised:
        asyncio.run(
            submit.execute(Principal(LearnerId("verified-learner")), command())
        )

    assert "sensitive diagnostics" not in str(raised.value)


def test_raw_database_failure_during_lookup_maps_to_safe_report_failure() -> None:
    repository = MemoryReportRepository()
    repository.failure = SQLAlchemyError("database connection diagnostics")
    submit, _ = use_case(repository)

    with pytest.raises(ReportPersistenceUnavailable) as raised:
        asyncio.run(
            submit.execute(Principal(LearnerId("verified-learner")), command())
        )

    assert "connection diagnostics" not in str(raised.value)
