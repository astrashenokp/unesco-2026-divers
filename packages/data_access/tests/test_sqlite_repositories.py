import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.db import SqlAlchemyTransactionManager
from data_access.idempotency import (
    SqlAlchemyCompletionIdempotencyRepository,
    SqlAlchemyIdempotencyRepository,
    cleanup_expired_idempotency,
)
from data_access.reports import (
    SqlAlchemyReportRepository,
    StoredReportResult,
    SubmittedReport,
)
from data_access.schema import metadata, outbox, reports
from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.attempt import Confidence, Prediction, Reaction
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    CompletionResult,
    IdempotencyScope,
    ProgressResult,
    StoredAttemptResult,
    StoredCompletionResult,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)


def run(coro):
    return asyncio.run(coro)


async def session_factory():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(metadata.create_all)
    return engine, async_sessionmaker(engine, expire_on_commit=False)


def make_attempt() -> Attempt:
    return Attempt(
        AttemptId("attempt-1"),
        LearnerId("learner-1"),
        MissionId("mission-1"),
        MissionVersion("v1"),
    )


def test_attempt_repository_round_trip_and_stale_version() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        async with sessions() as session:
            repository = SqlAlchemyAttemptRepository(session)
            attempt = make_attempt()
            async with session.begin():
                await repository.add(attempt)

            stored = await repository.get(attempt.id)
            assert stored is not None
            await session.commit()
            stored.version = 2
            async with session.begin():
                await repository.save(stored, expected_version=1)

            stored.version = 2
            async with session.begin():
                try:
                    await repository.save(stored, expected_version=1)
                except RepositoryConflict:
                    pass
                else:
                    raise AssertionError("stale version was accepted")
        await engine.dispose()

    run(scenario())


def test_idempotency_replays_conflicts_and_cleans_expired_rows() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        scope = IdempotencyScope(LearnerId("learner-1"), "/v1/attempts", IdempotencyKey("key-1234"))
        now = datetime.now(UTC)
        result = StoredAttemptResult("fingerprint-a", make_attempt(), now + timedelta(hours=24))
        async with sessions() as session:
            repository = SqlAlchemyIdempotencyRepository(session)
            async with session.begin():
                await repository.put(scope, result)
            replay = await repository.get(scope, at=now)
            assert replay is not None
            assert replay.request_fingerprint == result.request_fingerprint
            await session.commit()
            async with session.begin():
                try:
                    await repository.put(
                        scope,
                        StoredAttemptResult("fingerprint-b", make_attempt(), result.expires_at),
                    )
                except RepositoryConflict:
                    pass
                else:
                    raise AssertionError("fingerprint conflict was not raised")
            async with session.begin():
                deleted = await cleanup_expired_idempotency(session, at=now + timedelta(days=2))
            assert deleted == 1
            assert await repository.get(scope, at=now + timedelta(days=2)) is None
        await engine.dispose()

    run(scenario())


def test_transaction_manager_rolls_back_attempt_and_action_rows() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        async with sessions() as session:
            repository = SqlAlchemyAttemptRepository(session)
            manager = SqlAlchemyTransactionManager(session)
            try:
                async with manager.transaction():
                    attempt = make_attempt()
                    await repository.add(attempt)
                    attempt.submit_prediction(Prediction(Reaction.INVESTIGATE, Confidence.known(50)))
                    await repository.save(attempt, expected_version=1)
                    attempt.record_evidence_action("rollback-action")
                    await repository.save(attempt, expected_version=2)
                    raise RuntimeError("forced rollback")
            except RuntimeError:
                pass
            assert await repository.get(AttemptId("attempt-1")) is None
        await engine.dispose()

    run(scenario())


def test_completion_idempotency_round_trips_response_snapshot() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        now = datetime.now(UTC)
        scope = IdempotencyScope(
            LearnerId("learner-completion"),
            "/v1/attempts/{attemptId}/conclusion",
            IdempotencyKey("completion-key"),
        )
        stored = StoredCompletionResult(
            "completion-fingerprint",
            CompletionResult("receipt-1", 2, ProgressResult(2, ())),
            now + timedelta(hours=24),
        )
        async with sessions() as session:
            repository = SqlAlchemyCompletionIdempotencyRepository(session)
            async with session.begin():
                await repository.put_completion(scope, stored)
            replay = await repository.get_completion(scope, at=now)
            assert replay == stored
        await engine.dispose()

    run(scenario())


def make_report(report_id: str = "report-1") -> SubmittedReport:
    return SubmittedReport(
        report_id=report_id,
        reporter_id="learner-1",
        mission_id="mission-1",
        mission_version="v1",
        reason="harmful",
        detail="learner-supplied detail",
        submitted_at=datetime.now(UTC),
    )


def test_report_repository_commits_report_idempotency_and_outbox_atomically() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        scope = IdempotencyScope(
            LearnerId("learner-1"), "/v1/reports", IdempotencyKey("report-key-123")
        )
        now = datetime.now(UTC)
        stored = StoredReportResult("report-fingerprint", make_report(), now + timedelta(hours=24))
        async with sessions() as session:
            repository = SqlAlchemyReportRepository(session)
            async with session.begin():
                await repository.put(scope, stored)
            replay = await repository.get(scope, at=now)
            assert replay is not None
            assert replay.request_fingerprint == stored.request_fingerprint
            assert replay.report.report_id == stored.report.report_id
            assert replay.report.detail == stored.report.detail
            report_count = int(
                (await session.execute(select(func.count()).select_from(reports))).scalar_one()
            )
            event_count = int(
                (await session.execute(select(func.count()).select_from(outbox))).scalar_one()
            )
            assert report_count == 1
            assert event_count == 1
            await session.commit()

            async with session.begin():
                try:
                    await repository.put(
                        scope,
                        StoredReportResult("other-fingerprint", make_report(), stored.expires_at),
                    )
                except RepositoryConflict:
                    pass
                else:
                    raise AssertionError("report fingerprint conflict was not raised")

            async with session.begin():
                await repository.put(scope, stored)
            async with session.begin():
                report_count = int(
                    (await session.execute(select(func.count()).select_from(reports))).scalar_one()
                )
                event_count = int(
                    (await session.execute(select(func.count()).select_from(outbox))).scalar_one()
                )
            assert report_count == 1
            assert event_count == 1
        await engine.dispose()

    run(scenario())
