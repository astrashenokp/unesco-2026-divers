import asyncio
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy import insert
from sqlalchemy import select

from data_access.completion import SqlAlchemyAtomicCompletionWriter
from data_access.schema import attempts, metadata, receipts
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Confidence,
    Conclusion,
    Prediction,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.learning.ports import XpAward
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    LearnerId,
    MissionId,
    MissionVersion,
)


class StubScorer:
    async def award(self, mission_id, mission_version, used_evidence_actions):
        return XpAward("process-xp:1", 2, 1)


def test_completion_writer_persists_final_snapshot_and_effects() -> None:
    async def scenario() -> None:
        engine = create_async_engine("sqlite+aiosqlite:///:memory:")
        async with engine.begin() as connection:
            await connection.run_sync(metadata.create_all)
        sessions = async_sessionmaker(engine, expire_on_commit=False)
        async with sessions() as session:
            attempt = Attempt(
                AttemptId("attempt-complete"),
                LearnerId("learner-complete"),
                MissionId("mission-complete"),
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
            writer = SqlAlchemyAtomicCompletionWriter(session, StubScorer())
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
                        prediction_json=None,
                        evidence_action_refs=list(attempt.evidence_action_refs),
                        conclusion_json=None,
                        created_at=datetime.now(UTC),
                        updated_at=datetime.now(UTC),
                    )
                )
                result = await writer.complete(
                    attempt,
                    conclusion,
                    expected_version=attempt.version,
                    completed_at=datetime.now(UTC),
                )
            assert result.receipt_id == "receipt-attempt-complete"
            assert result.xp_awarded == 2
            receipt = (
                await session.execute(
                    select(receipts.c.payload_json).where(receipts.c.id == result.receipt_id)
                )
            ).scalar_one()
            assert "rationaleRef" not in receipt["assessments"][0]
        await engine.dispose()

    asyncio.run(scenario())
