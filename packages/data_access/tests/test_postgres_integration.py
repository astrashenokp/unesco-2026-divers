import os
import asyncio
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.db import Database
from data_access.idempotency import SqlAlchemyIdempotencyRepository
from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import IdempotencyScope, StoredAttemptResult
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)

pytestmark = pytest.mark.skipif(
    not os.getenv("DATABASE_URL"),
    reason="set DATABASE_URL to run PostgreSQL integration tests",
)


def test_postgres_repositories_round_trip_after_migration() -> None:
    """Exercise the real adapter against an explicitly supplied test database."""

    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = Attempt(
            AttemptId(f"integration-attempt-{run_id}"),
            LearnerId(f"integration-learner-{run_id}"),
            MissionId(f"integration-mission-{run_id}"),
            MissionVersion("v1"),
        )
        now = datetime.now(UTC)
        async with database.session() as session:
            attempts = SqlAlchemyAttemptRepository(session)
            idempotency = SqlAlchemyIdempotencyRepository(session)
            async with session.begin():
                await attempts.add(attempt)
                await idempotency.put(
                    IdempotencyScope(
                        attempt.learner_id,
                        "/integration/attempts",
                        IdempotencyKey(f"key-{run_id}"),
                    ),
                    StoredAttemptResult("integration-fingerprint", attempt, now + timedelta(hours=24)),
                )
            restored = await attempts.get(attempt.id)
            replay = await idempotency.get(
                IdempotencyScope(
                    attempt.learner_id,
                    "/integration/attempts",
                    IdempotencyKey(f"key-{run_id}"),
                ),
                at=now,
            )
            assert restored is not None
            assert restored.version == 1
            assert replay is not None
            assert replay.attempt.id == attempt.id
        await database.dispose()

    asyncio.run(scenario())


def test_postgres_optimistic_lock_rejects_stale_writer() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = Attempt(
            AttemptId(f"race-attempt-{run_id}"),
            LearnerId(f"race-learner-{run_id}"),
            MissionId(f"race-mission-{run_id}"),
            MissionVersion("v1"),
        )
        async with database.session() as setup_session:
            async with setup_session.begin():
                await SqlAlchemyAttemptRepository(setup_session).add(attempt)

        async with database.session() as first_session, database.session() as second_session:
            first_repository = SqlAlchemyAttemptRepository(first_session)
            second_repository = SqlAlchemyAttemptRepository(second_session)
            first = await first_repository.get(attempt.id)
            second = await second_repository.get(attempt.id)
            assert first is not None and second is not None
            await first_session.commit()
            await second_session.commit()
            first.version = 2
            second.version = 2
            async with first_session.begin():
                await first_repository.save(first, expected_version=1)
            async with second_session.begin():
                with pytest.raises(RepositoryConflict, match="version changed concurrently"):
                    await second_repository.save(second, expected_version=1)
        await database.dispose()

    asyncio.run(scenario())
