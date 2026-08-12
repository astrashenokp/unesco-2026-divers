import asyncio
from datetime import timedelta

import pytest
from evidence_gym_api.evidence import EvidenceResult, EvidenceStatus
from evidence_gym_api.evidence import EvidenceActionNotFound
from evidence_gym_api.coach import CoachHint, HintUncertainty

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
    FixedClock,
    SequentialAttemptIdGenerator,
)
from evidence_gym_api.learning.use_cases import (
    StartAttempt,
    StartAttemptCommand,
    SubmitPrediction,
    SubmitPredictionCommand,
    UseEvidenceAction,
    UseEvidenceActionCommand,
    RequestHint,
    RequestHintCommand,
)


class StubEvidenceProvider:
    async def get_result(self, mission_id, mission_version, action_id):
        return EvidenceResult(action_id, EvidenceStatus.OK, (), ("fixture",))


class MissingEvidenceProvider:
    async def get_result(self, mission_id, mission_version, action_id):
        raise EvidenceActionNotFound("action is not defined by the mission")


class StubCoachPolicy:
    async def get_coach_request_data(self, mission_id, mission_version):
        return (("inspect-source",), {"inspect-source": ("E-SOURCE",)})


class SafeFallbackCoach:
    async def request_hint(self, request):
        return CoachHint(
            "Which source property should you inspect next?",
            request.level,
            "inspect-source",
            (),
            HintUncertainty.HIGH,
            ("provider_degraded",),
            True,
        )


class UnsafeCoach:
    async def request_hint(self, request):
        return CoachHint(
            "The gold label is false.",
            request.level,
            "not-allowlisted",
            ("E-INVENTED",),
            HintUncertainty.LOW,
            ("possible_leakage",),
            False,
        )


def run(coroutine):
    return asyncio.run(coroutine)


LEARNER = Principal(LearnerId("learner-test-1"))
OTHER_LEARNER = Principal(LearnerId("learner-test-2"))
MISSION_ID = MissionId("mission-test-1")
MISSION_VERSION = MissionVersion("1.2.3")


def make_dependencies(clock: FixedClock | None = None):
    attempts = InMemoryAttemptRepository()
    idempotency = InMemoryIdempotencyRepository()
    missions = InMemoryMissionPolicyReader(
        (MissionPolicy(MISSION_ID, MISSION_VERSION),)
    )
    transactions = InMemoryTransactionManager()
    clock = clock or FixedClock()
    start = StartAttempt(
        attempts,
        missions,
        idempotency,
        SequentialAttemptIdGenerator(),
        transactions,
        clock,
    )
    submit = SubmitPrediction(attempts, idempotency, transactions, clock)
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


def evidence_command(
    attempt_id: AttemptId,
    *,
    key: str = "evidence-key-001",
    version: int = 2,
    action_id: str = "inspect-source",
) -> UseEvidenceActionCommand:
    return UseEvidenceActionCommand(
        attempt_id=attempt_id,
        action_id=action_id,
        input={},
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
    assert attempt.minimum_required_evidence_actions == 1


def test_start_attempt_pins_mission_minimum_completion_evidence() -> None:
    attempts = InMemoryAttemptRepository()
    idempotency = InMemoryIdempotencyRepository()
    missions = InMemoryMissionPolicyReader(
        (
            MissionPolicy(
                MISSION_ID,
                MISSION_VERSION,
                minimum_completion_evidence=3,
            ),
        )
    )
    start = StartAttempt(
        attempts,
        missions,
        idempotency,
        SequentialAttemptIdGenerator(),
        InMemoryTransactionManager(),
        FixedClock(),
    )

    attempt = run(start.execute(LEARNER, start_command()))

    assert attempt.minimum_required_evidence_actions == 3
    assert run(attempts.get(attempt.id)) == attempt


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


def test_idempotency_key_can_be_reused_after_24_hour_retention() -> None:
    clock = FixedClock()
    _, start, _ = make_dependencies(clock)
    first = run(start.execute(LEARNER, start_command()))

    clock.current += timedelta(hours=24)
    second = run(start.execute(LEARNER, start_command()))

    assert second.id != first.id


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


def test_prediction_key_is_scoped_to_route_not_individual_attempt() -> None:
    _, start, submit = make_dependencies()
    first = run(start.execute(LEARNER, start_command("start-key-0001")))
    second = run(start.execute(LEARNER, start_command("start-key-0002")))
    run(submit.execute(LEARNER, prediction_command(first.id)))

    with pytest.raises(IdempotencyConflict):
        run(submit.execute(LEARNER, prediction_command(second.id)))


def test_submit_prediction_rejects_unknown_attempt() -> None:
    _, _, submit = make_dependencies()
    with pytest.raises(AttemptNotFound):
        run(submit.execute(LEARNER, prediction_command(AttemptId("missing-attempt"))))


def test_use_evidence_action_updates_attempt_and_replays_original_result() -> None:
    attempts, start, submit = make_dependencies()
    idempotency = InMemoryIdempotencyRepository()
    use_evidence = UseEvidenceAction(
        attempts,
        StubEvidenceProvider(),
        idempotency,
        InMemoryTransactionManager(),
        FixedClock(),
    )
    attempt = run(start.execute(LEARNER, start_command()))
    predicted = run(submit.execute(LEARNER, prediction_command(attempt.id)))
    command = evidence_command(predicted.id)

    first = run(use_evidence.execute(LEARNER, command))
    replay = run(use_evidence.execute(LEARNER, command))
    stored = run(attempts.get(predicted.id))

    assert first == replay
    assert first.evidence.action_id == "inspect-source"
    assert first.attempt_version == 3
    assert stored is not None
    assert stored.state is AttemptState.INVESTIGATING
    assert stored.evidence_action_refs == ("inspect-source",)


def test_use_evidence_action_checks_owner_version_and_idempotency_payload() -> None:
    attempts, start, submit = make_dependencies()
    idempotency = InMemoryIdempotencyRepository()
    use_evidence = UseEvidenceAction(
        attempts,
        StubEvidenceProvider(),
        idempotency,
        InMemoryTransactionManager(),
        FixedClock(),
    )
    attempt = run(start.execute(LEARNER, start_command()))
    predicted = run(submit.execute(LEARNER, prediction_command(attempt.id)))

    with pytest.raises(AttemptAccessDenied):
        run(use_evidence.execute(OTHER_LEARNER, evidence_command(predicted.id)))
    with pytest.raises(StaleAttemptVersion):
        run(use_evidence.execute(LEARNER, evidence_command(predicted.id, version=1)))

    command = evidence_command(predicted.id)
    run(use_evidence.execute(LEARNER, command))
    with pytest.raises(IdempotencyConflict):
        run(
            use_evidence.execute(
                LEARNER,
                evidence_command(predicted.id, action_id="different-action"),
            )
        )


def test_evidence_provider_failure_does_not_mutate_attempt() -> None:
    attempts, start, submit = make_dependencies()
    use_evidence = UseEvidenceAction(
        attempts,
        MissingEvidenceProvider(),
        InMemoryIdempotencyRepository(),
        InMemoryTransactionManager(),
        FixedClock(),
    )
    attempt = run(start.execute(LEARNER, start_command()))
    predicted = run(submit.execute(LEARNER, prediction_command(attempt.id)))

    with pytest.raises(EvidenceActionNotFound):
        run(use_evidence.execute(LEARNER, evidence_command(predicted.id)))

    assert run(attempts.get(predicted.id)) == predicted


def test_request_hint_rejects_unsafe_provider_output_and_uses_fallback() -> None:
    attempts, start, submit = make_dependencies()
    idempotency = InMemoryIdempotencyRepository()
    hints = RequestHint(
        attempts,
        StubCoachPolicy(),
        SafeFallbackCoach(),
        idempotency,
        InMemoryTransactionManager(),
        FixedClock(),
        provider=UnsafeCoach(),
    )
    attempt = run(start.execute(LEARNER, start_command()))
    predicted = run(submit.execute(LEARNER, prediction_command(attempt.id)))
    command = RequestHintCommand(predicted.id, IdempotencyKey("hint-key-0001"))

    hint = run(hints.execute(LEARNER, command))
    replay = run(hints.execute(LEARNER, command))
    stored = run(attempts.get(predicted.id))

    assert hint == replay
    assert hint.fallback is True
    assert hint.safety_flags == ("provider_degraded",)
    assert stored == predicted


def test_request_hint_authorizes_owner_and_scopes_key_across_attempts() -> None:
    attempts, start, submit = make_dependencies()
    hints = RequestHint(
        attempts,
        StubCoachPolicy(),
        SafeFallbackCoach(),
        InMemoryIdempotencyRepository(),
        InMemoryTransactionManager(),
        FixedClock(),
    )
    first = run(start.execute(LEARNER, start_command("start-key-0001")))
    second = run(start.execute(LEARNER, start_command("start-key-0002")))
    first = run(submit.execute(LEARNER, prediction_command(first.id, key="pred-key-0001")))
    second = run(submit.execute(LEARNER, prediction_command(second.id, key="pred-key-0002")))

    with pytest.raises(AttemptAccessDenied):
        run(
            hints.execute(
                OTHER_LEARNER,
                RequestHintCommand(first.id, IdempotencyKey("foreign-hint-01")),
            )
        )

    key = IdempotencyKey("shared-hint-key")
    run(hints.execute(LEARNER, RequestHintCommand(first.id, key)))
    with pytest.raises(IdempotencyConflict):
        run(hints.execute(LEARNER, RequestHintCommand(second.id, key)))


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
