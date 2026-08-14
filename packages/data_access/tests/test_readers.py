import asyncio
from datetime import UTC, datetime

from sqlalchemy import insert
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from data_access.db import Database
from data_access.readers import SqlAlchemyProgressReader, SqlAlchemyReceiptReader
from data_access.readiness import DatabaseReadinessProbe
from data_access.schema import attempts, learner_progress, metadata, receipts, skill_states
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.receipt.model import EvidenceReceipt

DISCLAIMER = "This receipt records a learning process, not a universal truth verdict."


def run(coro):
    return asyncio.run(coro)


async def session_factory():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(metadata.create_all)
    return engine, async_sessionmaker(engine, expire_on_commit=False)


async def seed_receipt(session) -> None:
    now = datetime.now(UTC)
    await session.execute(
        insert(attempts).values(
            id="attempt-1",
            learner_id="learner-1",
            mission_id="mission-1",
            mission_version="v1",
            allows_no_evidence_conclusion=False,
            minimum_required_evidence_actions=1,
            state="completed",
            version=3,
            prediction_json={"reaction": "investigate", "confidence": {"status": "known", "value": 50}},
            evidence_action_refs=["check-source"],
            conclusion_json=None,
            created_at=now,
            updated_at=now,
        )
    )
    await session.execute(
        insert(receipts).values(
            id="receipt-1",
            attempt_id="attempt-1",
            mission_version="v1",
            payload_json={
                "id": "receipt-1",
                "attemptId": "attempt-1",
                "missionVersion": "v1",
                "evidenceRefs": ["check-source"],
                "assessments": [
                    {"label": "authentic", "confidence": 60},
                    {"label": "supported", "confidence": 60},
                    {"label": "accurate", "confidence": 60},
                ],
                "postConfidence": 55,
                "shareDecision": "do_not_share",
                "createdAt": now.isoformat(),
                "disclaimer": DISCLAIMER,
            },
            hash="a" * 64,
            created_at=now,
        )
    )


def test_receipt_reader_maps_owned_receipt_and_hides_foreign_and_missing() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        async with sessions() as session:
            async with session.begin():
                await seed_receipt(session)
            reader = SqlAlchemyReceiptReader(session)

            owned = await reader.get_for_learner("receipt-1", LearnerId("learner-1"))
            assert isinstance(owned, EvidenceReceipt)
            assert owned.id == "receipt-1"
            assert owned.attempt_id == "attempt-1"
            assert owned.mission_version == "v1"
            assert len(owned.assessments) == 3
            assert owned.assessments[0].label == "authentic"
            assert owned.assessments[0].confidence.value == 60
            assert owned.evidence_refs == ("check-source",)
            assert owned.hash == "a" * 64
            assert owned.disclaimer == DISCLAIMER

            assert await reader.get_for_learner("receipt-1", LearnerId("learner-2")) is None
            assert await reader.get_for_learner("receipt-missing", LearnerId("learner-1")) is None
        await engine.dispose()

    run(scenario())


def test_progress_reader_maps_learner_projection_and_zeroes_new_learners() -> None:
    async def scenario() -> None:
        engine, sessions = await session_factory()
        now = datetime.now(UTC)
        async with sessions() as session:
            async with session.begin():
                await session.execute(
                    insert(learner_progress).values(
                        learner_id="learner-1", total_xp=7, updated_at=now
                    )
                )
                await session.execute(
                    insert(skill_states).values(
                        learner_id="learner-1",
                        skill="bias",
                        mastery=0.2,
                        practices=1,
                        due_at=None,
                        algorithm_version=1,
                        updated_at=now,
                    )
                )
                await session.execute(
                    insert(skill_states).values(
                        learner_id="learner-1",
                        skill="verify-source",
                        mastery=0.5,
                        practices=2,
                        due_at=now,
                        algorithm_version=1,
                        updated_at=now,
                    )
                )
            reader = SqlAlchemyProgressReader(session)

            progress = await reader.get_for_learner(LearnerId("learner-1"))
            assert progress.total_xp == 7
            assert [item.skill for item in progress.skills] == ["bias", "verify-source"]
            assert progress.skills[0].mastery == 0.2
            assert progress.skills[1].due_at is not None

            fresh = await reader.get_for_learner(LearnerId("learner-new"))
            assert fresh.total_xp == 0
            assert fresh.skills == ()
        await engine.dispose()

    run(scenario())


def test_readiness_probe_reflects_database_availability() -> None:
    async def scenario() -> None:
        database = Database("sqlite+aiosqlite:///:memory:")
        probe = DatabaseReadinessProbe(database)
        assert await probe.is_ready()
        await database.dispose()
        unreachable = Database(
            "postgresql+asyncpg://evidence_gym:evidence_gym@127.0.0.1:1/evidence_gym"
        )
        assert await DatabaseReadinessProbe(unreachable).is_ready() is False
        await unreachable.dispose()

    run(scenario())
