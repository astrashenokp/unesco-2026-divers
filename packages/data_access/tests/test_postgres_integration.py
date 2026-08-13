import os
import asyncio
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy import func, insert, select

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.completion import SqlAlchemyAtomicCompletionWriter
from data_access.db import Database
from data_access.db import SqlAlchemyTransactionManager
from data_access.idempotency import (
    SqlAlchemyCompletionIdempotencyRepository,
    SqlAlchemyIdempotencyRepository,
)
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Confidence,
    Conclusion,
    Prediction,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    CompletionResult,
    IdempotencyScope,
    ProgressResult,
    StoredAttemptResult,
    StoredCompletionResult,
    XpAward,
)
from evidence_gym_api.learning.testing import FixedClock
from evidence_gym_api.learning.use_cases import CompleteAttempt, CompleteAttemptCommand
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)
from data_access.schema import (
    attempts,
    conclusions,
    idempotency_results,
    learner_progress,
    outbox,
    receipts,
    xp_ledger,
)

pytestmark = pytest.mark.skipif(
    not os.getenv("DATABASE_URL"),
    reason="set DATABASE_URL to run PostgreSQL integration tests",
)


class IntegrationScorer:
    async def award(self, mission_id, mission_version, used_evidence_actions):
        return XpAward("process-xp:1", 2, 1)


def conclusion_for(attempt: Attempt) -> CompleteAttemptCommand:
    return CompleteAttemptCommand(
        attempt_id=attempt.id,
        authenticity=AxisAssessment("authentic", Confidence.known(60)),
        claim_veracity=AxisAssessment("supported", Confidence.known(60)),
        context_integrity=AxisAssessment("accurate", Confidence.known(60)),
        post_confidence=Confidence.known(55),
        share_decision=ShareDecision.DO_NOT_SHARE,
        version=attempt.version,
        idempotency_key=IdempotencyKey("completion-key"),
    )


async def seed_completion_attempt(database: Database, run_id: str) -> Attempt:
    attempt = Attempt(
        AttemptId(f"seed-attempt-{run_id}"),
        LearnerId(f"seed-learner-{run_id}"),
        MissionId(f"seed-mission-{run_id}"),
        MissionVersion("v1"),
    )
    async with database.session() as session:
        repository = SqlAlchemyAttemptRepository(session)
        async with session.begin():
            await repository.add(attempt)
        attempt.submit_prediction(Prediction(Reaction.INVESTIGATE, Confidence.known(50)))
        async with session.begin():
            await repository.save(attempt, expected_version=1)
        attempt.record_evidence_action("check-source")
        async with session.begin():
            await repository.save(attempt, expected_version=2)
    return attempt


async def count_rows(session, table, column, value) -> int:
    return int(
        (
            await session.execute(
                select(func.count()).select_from(table).where(column == value)
            )
        ).scalar_one()
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


def test_postgres_completion_writer_commits_receipt_xp_progress_and_outbox() -> None:
    class Scorer:
        async def award(self, mission_id, mission_version, used_evidence_actions):
            return XpAward("process-xp:1", 2, 1)

    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = Attempt(
            AttemptId(f"completion-attempt-{run_id}"),
            LearnerId(f"completion-learner-{run_id}"),
            MissionId(f"completion-mission-{run_id}"),
            MissionVersion("v1"),
        )
        attempt.submit_prediction(Prediction(Reaction.INVESTIGATE, Confidence.known(50)))
        attempt.record_evidence_action("check-source")
        conclusion = Conclusion(
            AxisAssessment("authentic", Confidence.known(60)),
            AxisAssessment("supported", Confidence.known(60)),
            AxisAssessment("accurate", Confidence.known(60)),
            Confidence.known(55),
            ShareDecision.DO_NOT_SHARE,
        )
        async with database.session() as session:
            async with session.begin():
                await session.execute(
                    insert(attempts).values(
                        id=str(attempt.id),
                        learner_id=str(attempt.learner_id),
                        mission_id=str(attempt.mission_id),
                        mission_version=str(attempt.mission_version),
                        allows_no_evidence_conclusion=False,
                        minimum_required_evidence_actions=1,
                        state="investigating",
                        version=attempt.version,
                        prediction_json={"reaction": "investigate", "confidence": {"status": "known", "value": 50}},
                        evidence_action_refs=["check-source"],
                        conclusion_json=None,
                        created_at=datetime.now(UTC),
                        updated_at=datetime.now(UTC),
                    )
                )
                result = await SqlAlchemyAtomicCompletionWriter(session, Scorer()).complete(
                    attempt,
                    conclusion,
                    expected_version=attempt.version,
                    completed_at=datetime.now(UTC),
                )
            assert result.xp_awarded == 2
            assert result.receipt_id.startswith("receipt-")
        await database.dispose()

    asyncio.run(scenario())


def test_postgres_completion_rolls_back_all_effects() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = await seed_completion_attempt(database, run_id)
        command = conclusion_for(attempt)
        try:
            async with database.session() as session:
                writer = SqlAlchemyAtomicCompletionWriter(session, IntegrationScorer())
                completion_idempotency = SqlAlchemyCompletionIdempotencyRepository(session)
                async with session.begin():
                    result = await writer.complete(
                        attempt,
                        Conclusion(
                            command.authenticity,
                            command.claim_veracity,
                            command.context_integrity,
                            command.post_confidence,
                            command.share_decision,
                        ),
                        expected_version=command.version,
                        completed_at=datetime.now(UTC),
                    )
                    await completion_idempotency.put_completion(
                        IdempotencyScope(
                            attempt.learner_id,
                            "/attempts/{attemptId}/conclusion",
                            command.idempotency_key,
                        ),
                        StoredCompletionResult(
                            "rollback-fingerprint",
                            result,
                            datetime.now(UTC) + timedelta(hours=24),
                        ),
                    )
                    raise RuntimeError("forced completion rollback")
        except RuntimeError:
            pass

        async with database.session() as session:
            stored = await SqlAlchemyAttemptRepository(session).get(attempt.id)
            assert stored is not None
            assert stored.state.value == "investigating"
            assert stored.version == command.version
            assert await count_rows(session, conclusions, conclusions.c.attempt_id, str(attempt.id)) == 0
            assert await count_rows(session, xp_ledger, xp_ledger.c.attempt_id, str(attempt.id)) == 0
            assert await count_rows(session, receipts, receipts.c.attempt_id, str(attempt.id)) == 0
            assert await count_rows(session, outbox, outbox.c.subject_id, str(attempt.id)) == 0
            assert await count_rows(
                session, learner_progress, learner_progress.c.learner_id, str(attempt.learner_id)
            ) == 0
            assert await count_rows(
                session, idempotency_results, idempotency_results.c.learner_id, str(attempt.learner_id)
            ) == 0
        await database.dispose()

    asyncio.run(scenario())


def test_postgres_same_key_retry_has_no_duplicate_completion_effects() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = await seed_completion_attempt(database, run_id)
        async with database.session() as session:
            use_case = CompleteAttempt(
                SqlAlchemyAttemptRepository(session),
                SqlAlchemyAtomicCompletionWriter(session, IntegrationScorer()),
                SqlAlchemyCompletionIdempotencyRepository(session),
                SqlAlchemyTransactionManager(session),
                FixedClock(),
            )
            principal = Principal(attempt.learner_id)
            command = conclusion_for(attempt)
            first = await use_case.execute(principal, command)
            replay = await use_case.execute(principal, command)
            assert first == replay

        async with database.session() as session:
            assert await count_rows(session, conclusions, conclusions.c.attempt_id, str(attempt.id)) == 1
            assert await count_rows(session, xp_ledger, xp_ledger.c.attempt_id, str(attempt.id)) == 1
            assert await count_rows(session, receipts, receipts.c.attempt_id, str(attempt.id)) == 1
            assert await count_rows(session, outbox, outbox.c.subject_id, str(attempt.id)) == 1
            assert await count_rows(
                session, learner_progress, learner_progress.c.learner_id, str(attempt.learner_id)
            ) == 1
            assert await count_rows(
                session, idempotency_results, idempotency_results.c.learner_id, str(attempt.learner_id)
            ) == 1
        await database.dispose()

    asyncio.run(scenario())
