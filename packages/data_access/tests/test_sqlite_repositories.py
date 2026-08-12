import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.idempotency import (
    SqlAlchemyIdempotencyRepository,
    cleanup_expired_idempotency,
)
from data_access.schema import metadata
from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    IdempotencyScope,
    StoredAttemptResult,
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
