import os
import asyncio
from datetime import UTC, datetime
from uuid import uuid4

import pytest

from data_access.attempts import SqlAlchemyAttemptRepository
from data_access.completion import SqlAlchemyAtomicCompletionWriter
from data_access.db import Database
from data_access.db import SqlAlchemyTransactionManager
from data_access.idempotency import SqlAlchemyCompletionIdempotencyRepository
from data_access.readers import SqlAlchemyProgressReader, SqlAlchemyReceiptReader
from data_access.readiness import DatabaseReadinessProbe
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Confidence,
    Conclusion,
    Prediction,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.learning.ports import ProcessLevelPolicy, XpAward
from evidence_gym_api.learning.testing import FixedClock
from evidence_gym_api.learning.use_cases import CompleteAttempt, CompleteAttemptCommand
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


class IntegrationScorer:
    async def award(self, mission_id, mission_version, used_evidence_actions):
        return XpAward("process-xp:1", 2, 1)


class IntegrationPolicies:
    async def get_process_levels(self, mission_id, mission_version):
        return (
            ProcessLevelPolicy(
                level=0,
                xp_guidance=0,
                skill_tags=(),
            ),
            ProcessLevelPolicy(
                level=1,
                xp_guidance=2,
                skill_tags=("verify-source",),
            ),
        )


def conclusion_for(attempt: Attempt) -> CompleteAttemptCommand:
    return CompleteAttemptCommand(
        attempt_id=attempt.id,
        authenticity=AxisAssessment("authentic", Confidence.known(60)),
        claim_veracity=AxisAssessment("supported", Confidence.known(60)),
        context_integrity=AxisAssessment("accurate", Confidence.known(60)),
        post_confidence=Confidence.known(55),
        share_decision=ShareDecision.DO_NOT_SHARE,
        version=attempt.version,
        idempotency_key=IdempotencyKey("reader-completion-key"),
    )


async def seed_completion_attempt(database: Database, run_id: str) -> Attempt:
    attempt = Attempt(
        AttemptId(f"reader-attempt-{run_id}"),
        LearnerId(f"reader-learner-{run_id}"),
        MissionId(f"reader-mission-{run_id}"),
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


def test_postgres_receipt_reader_returns_owned_receipt_only() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = await seed_completion_attempt(database, run_id)
        async with database.session() as session:
            use_case = CompleteAttempt(
                SqlAlchemyAttemptRepository(session),
                SqlAlchemyAtomicCompletionWriter(
                    session, IntegrationScorer(), policies=IntegrationPolicies()
                ),
                SqlAlchemyCompletionIdempotencyRepository(session),
                SqlAlchemyTransactionManager(session),
                FixedClock(),
            )
            result = await use_case.execute(
                Principal(attempt.learner_id), conclusion_for(attempt)
            )
        assert result.receipt_id == f"receipt-{attempt.id.value}"

        async with database.session() as session:
            reader = SqlAlchemyReceiptReader(session)
            receipt = await reader.get_for_learner(
                result.receipt_id, attempt.learner_id
            )
            assert receipt is not None
            assert receipt.attempt_id == str(attempt.id)
            assert receipt.mission_version == "v1"
            assert [axis.label for axis in receipt.assessments] == [
                "authentic",
                "supported",
                "accurate",
            ]
            assert all(axis.confidence.value == 60 for axis in receipt.assessments)
            assert receipt.evidence_refs == ("check-source",)
            assert len(receipt.hash) == 64
            assert receipt.disclaimer.startswith(
                "This receipt records a learning process, not a universal truth verdict."
            )

            foreign = await reader.get_for_learner(
                result.receipt_id, LearnerId(f"reader-other-{run_id}")
            )
            assert foreign is None
            missing = await reader.get_for_learner(
                f"receipt-missing-{run_id}", attempt.learner_id
            )
            assert missing is None
        await database.dispose()

    asyncio.run(scenario())


def test_postgres_progress_reader_returns_xp_and_skill_states() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        run_id = uuid4().hex
        attempt = await seed_completion_attempt(database, run_id)
        async with database.session() as session:
            use_case = CompleteAttempt(
                SqlAlchemyAttemptRepository(session),
                SqlAlchemyAtomicCompletionWriter(
                    session, IntegrationScorer(), policies=IntegrationPolicies()
                ),
                SqlAlchemyCompletionIdempotencyRepository(session),
                SqlAlchemyTransactionManager(session),
                FixedClock(),
            )
            await use_case.execute(Principal(attempt.learner_id), conclusion_for(attempt))

        async with database.session() as session:
            reader = SqlAlchemyProgressReader(session)
            progress = await reader.get_for_learner(attempt.learner_id)
            assert progress.total_xp == 2
            assert [item.skill for item in progress.skills] == ["verify-source"]
            assert progress.skills[0].mastery > 0

            fresh = await reader.get_for_learner(
                LearnerId(f"reader-fresh-{run_id}")
            )
            assert fresh.total_xp == 0
            assert fresh.skills == ()
        await database.dispose()

    asyncio.run(scenario())


def test_postgres_readiness_probe_reports_ready() -> None:
    async def scenario() -> None:
        database = Database(os.environ["DATABASE_URL"])
        probe = DatabaseReadinessProbe(database)
        assert await probe.is_ready()
        await database.dispose()

    asyncio.run(scenario())
