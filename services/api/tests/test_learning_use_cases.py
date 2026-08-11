import asyncio

import pytest

from evidence_gym_api.identity import Principal
from evidence_gym_api.identity.ports import IdentityVerificationError
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning import (
    AttemptId,
    AttemptState,
    Confidence,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
    Prediction,
    Reaction,
)
from evidence_gym_api.learning.errors import (
    AttemptAccessDenied,
    AttemptNotFound,
    IdempotencyConflict,
    MissionNotFound,
    RepositoryConflict,
    StaleAttemptVersion,
)
from evidence_gym_api.learning.ports import MissionPolicy
from evidence_gym_api.learning.testing import (
    InMemoryAttemptRepository,
    InMemoryIdempotencyRepository,
    InMemoryMissionPolicyReader,
    InMemoryTransactionManager,
    SequentialAttemptIdGenerator,
)
from evidence_gym_api.learning.use_cases import (
    StartAttempt,
    StartAttemptCommand,
    SubmitPrediction,
    SubmitPredictionCommand,
)


def run(coroutine):
    return asyncio.run(coroutine)


LEARNER = Principal(LearnerId("learner-test-1"))
OTHER_LEARNER = Principal(LearnerId("learner-test-2"))
MISSION_ID = MissionId("mission-test-1")
MISSION_VERSION = MissionVersion("1.2.3")


def make_dependencies():
    attempts = InMemoryAttemptRepository()
    idempotency = InMemoryIdempotencyRepository()
    missions = InMemoryMissionPolicyReader(
        (MissionPolicy(MISSION_ID, MISSION_VERSION),)
    )
    transactions = InMemoryTransactionManager()
    start = StartAttempt(
        attempts,
        missions,
        idempotency,
        SequentialAttemptIdGenerator(),
        transactions,
    )
    submit = SubmitPrediction(attempts, idempotency, transactions)
    return attempts, start, submit


def start_command(key: str = "start-key-0001") -> StartAttemptCommand:
    return StartAttemptCommand(
        MISSION_ID, MISSION_VERSION, IdempotencyKey(key)
    )


def prediction_command(
    attempt_id: AttemptId,
    *,
    key: str = "predict-key-001",
    version: int = 1,
    confidence: int = 60,
) -> SubmitPredictionCommand:
    return SubmitPredictionCommand(
        attempt_id=attempt_id,
        reaction=Reaction.INVESTIGATE,
        confidence=Confidence.known(confidence),
        version=version,
        idempotency_key=IdempotencyKey(key),
    )


def test_start_attempt_pins_exact_mission_and_server_identity() -> None:
    _, start, _ = make_dependencies()
    attempt = run(start.execute(LEARNER, start_command()))

    assert attempt.learner_id == LEARNER.subject
    assert attempt.mission_id == MISSION_ID
    assert attempt.mission_version == MISSION_VERSION
    assert attempt.state is AttemptState.READY


def test_start_attempt_replays_same_key_and_rejects_changed_request() -> None:
    _, start, _ = make_dependencies()
    first = run(start.execute(LEARNER, start_command()))
    replay = run(start.execute(LEARNER, start_command()))
    assert replay == first

    changed = StartAttemptCommand(
        MissionId("another-mission"), MISSION_VERSION, IdempotencyKey("start-key-0001")
    )
    with pytest.raises(IdempotencyConflict):
        run(start.execute(LEARNER, changed))


def test_concurrent_start_retries_create_one_attempt() -> None:
    attempts, start, _ = make_dependencies()

    async def concurrently_start():
        return await asyncio.gather(
            start.execute(LEARNER, start_command()),
            start.execute(LEARNER, start_command()),
        )

    first, second = run(concurrently_start())
    assert first == second
    assert run(attempts.get(first.id)) == first


def test_start_attempt_rejects_unknown_exact_mission_version() -> None:
    _, start, _ = make_dependencies()
    command = StartAttemptCommand(
        MISSION_ID, MissionVersion("9.9.9"), IdempotencyKey("unknown-key-01")
    )
    with pytest.raises(MissionNotFound):
        run(start.execute(LEARNER, command))


def test_submit_prediction_authorizes_owner_and_checks_version() -> None:
    _, start, submit = make_dependencies()
    attempt = run(start.execute(LEARNER, start_command()))

    with pytest.raises(AttemptAccessDenied):
        run(submit.execute(OTHER_LEARNER, prediction_command(attempt.id)))
    with pytest.raises(StaleAttemptVersion):
        run(
            submit.execute(
                LEARNER,
                prediction_command(attempt.id, key="stale-key-0001", version=2),
            )
        )


def test_submit_prediction_updates_once_and_replays_original_result() -> None:
    attempts, start, submit = make_dependencies()
    attempt = run(start.execute(LEARNER, start_command()))
    command = prediction_command(attempt.id)

    updated = run(submit.execute(LEARNER, command))
    replay = run(submit.execute(LEARNER, command))
    stored = run(attempts.get(attempt.id))

    assert updated.state is AttemptState.PREDICTED
    assert updated.version == 2
    assert replay == updated
    assert stored == updated


def test_submit_prediction_rejects_key_reuse_with_changed_payload() -> None:
    _, start, submit = make_dependencies()
    attempt = run(start.execute(LEARNER, start_command()))
    run(submit.execute(LEARNER, prediction_command(attempt.id)))

    with pytest.raises(IdempotencyConflict):
        run(submit.execute(LEARNER, prediction_command(attempt.id, confidence=90)))


def test_submit_prediction_rejects_unknown_attempt() -> None:
    _, _, submit = make_dependencies()
    with pytest.raises(AttemptNotFound):
        run(submit.execute(LEARNER, prediction_command(AttemptId("missing-attempt"))))


def test_in_memory_repository_enforces_optimistic_version() -> None:
    attempts, start, _ = make_dependencies()
    attempt = run(start.execute(LEARNER, start_command()))
    attempt.submit_prediction(Prediction(Reaction.INVESTIGATE, Confidence.known(60)))
    with pytest.raises(RepositoryConflict):
        run(attempts.save(attempt, expected_version=99))


def test_fake_identity_verifier_never_accepts_unknown_token() -> None:
    verifier = FakeIdentityVerifier({"valid-token": LEARNER})
    assert run(verifier.verify("valid-token")) == LEARNER
    with pytest.raises(IdentityVerificationError):
        run(verifier.verify("unknown-token"))
