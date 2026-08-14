import pytest

from evidence_gym_api.learning import (
    INSUFFICIENT_EVIDENCE,
    Attempt,
    AttemptId,
    AttemptState,
    AxisAssessment,
    Conclusion,
    Confidence,
    ConfidenceStatus,
    DomainError,
    EvidenceActionAlreadyUsed,
    IdempotencyKey,
    IllegalAttemptTransition,
    InvalidConfidence,
    LearnerId,
    MissionId,
    MissionVersion,
    Prediction,
    Reaction,
    ShareDecision,
)


def new_attempt(
    *,
    allows_no_evidence_conclusion: bool = False,
    minimum_required_evidence_actions: int = 1,
) -> Attempt:
    return Attempt(
        AttemptId("attempt-1"),
        LearnerId("learner-1"),
        MissionId("mission-1"),
        MissionVersion("1.2.3"),
        allows_no_evidence_conclusion=allows_no_evidence_conclusion,
        minimum_required_evidence_actions=minimum_required_evidence_actions,
    )


def prediction() -> Prediction:
    return Prediction(Reaction.INVESTIGATE, Confidence.known(60))


def conclusion() -> Conclusion:
    return Conclusion(
        authenticity=AxisAssessment("authentic", Confidence.known(80)),
        claim_veracity=AxisAssessment(INSUFFICIENT_EVIDENCE, Confidence.known(45)),
        context_integrity=AxisAssessment("missing_context", Confidence.known(75)),
        post_confidence=Confidence.known(70),
        share_decision=ShareDecision.CONTINUE_INVESTIGATING,
    )


def investigating_attempt() -> Attempt:
    attempt = new_attempt()
    attempt.submit_prediction(prediction())
    attempt.record_evidence_action("evidence-action-1")
    return attempt


@pytest.mark.parametrize("value", [0, 1, 50, 99, 100])
def test_confidence_accepts_full_closed_range(value: int) -> None:
    confidence = Confidence.known(value)
    assert confidence.value == value
    assert confidence.status is ConfidenceStatus.KNOWN


@pytest.mark.parametrize("value", [-1, 101, 1.5, True, "50"])
def test_confidence_rejects_values_outside_integer_domain(value: object) -> None:
    with pytest.raises(InvalidConfidence):
        Confidence.known(value)  # type: ignore[arg-type]


def test_confidence_models_unknown_and_not_asked_explicitly() -> None:
    assert Confidence.unknown() == Confidence(ConfidenceStatus.UNKNOWN)
    assert Confidence.not_asked() == Confidence(ConfidenceStatus.NOT_ASKED)
    with pytest.raises(InvalidConfidence):
        Confidence(ConfidenceStatus.UNKNOWN, 0)


@pytest.mark.parametrize("absent", [Confidence.unknown(), Confidence.not_asked()])
def test_required_attempt_confidences_must_be_known(absent: Confidence) -> None:
    with pytest.raises(InvalidConfidence):
        Prediction(Reaction.TRUST, absent)
    with pytest.raises(InvalidConfidence):
        AxisAssessment("authentic", absent)


def test_happy_path_preserves_pinned_mission_and_independent_axes() -> None:
    attempt = new_attempt()
    pinned = (attempt.mission_id, attempt.mission_version)

    attempt.submit_prediction(prediction())
    assert (attempt.state, attempt.version) == (AttemptState.PREDICTED, 2)

    attempt.record_evidence_action("action-1")
    assert (attempt.state, attempt.version) == (AttemptState.INVESTIGATING, 3)

    result = conclusion()
    attempt.submit_conclusion(result)
    assert (attempt.state, attempt.version) == (AttemptState.CONCLUDED, 4)
    assert attempt.conclusion is result
    assert result.authenticity.label == "authentic"
    assert result.claim_veracity.is_insufficient_evidence
    assert result.claim_veracity.label != "false"
    assert result.context_integrity.label == "missing_context"

    attempt.complete()
    assert (attempt.state, attempt.version) == (AttemptState.COMPLETED, 5)
    assert (attempt.mission_id, attempt.mission_version) == pinned


@pytest.mark.parametrize(
    "field",
    [
        "id",
        "learner_id",
        "mission_id",
        "mission_version",
        "allows_no_evidence_conclusion",
        "minimum_required_evidence_actions",
    ],
)
def test_attempt_identity_and_mission_policy_are_pinned_at_creation(field: str) -> None:
    attempt = new_attempt()
    with pytest.raises(AttributeError, match="pinned"):
        setattr(attempt, field, "replacement")
    assert (attempt.mission_id, attempt.mission_version) == (
        MissionId("mission-1"),
        MissionVersion("1.2.3"),
    )


def test_repeated_evidence_action_is_rejected_without_advancing_attempt() -> None:
    attempt = investigating_attempt()
    version = attempt.version
    state = attempt.state

    with pytest.raises(EvidenceActionAlreadyUsed):
        attempt.record_evidence_action("evidence-action-1")

    assert attempt.evidence_action_refs == ("evidence-action-1",)
    assert attempt.state is state
    assert attempt.version == version


def test_repeated_domain_completion_is_rejected() -> None:
    attempt = investigating_attempt()
    attempt.submit_conclusion(conclusion())
    attempt.complete()
    version = attempt.version
    with pytest.raises(IllegalAttemptTransition):
        attempt.complete()
    assert attempt.state is AttemptState.COMPLETED
    assert attempt.version == version


def test_explicit_mission_rule_can_allow_conclusion_without_evidence() -> None:
    attempt = new_attempt(
        allows_no_evidence_conclusion=True,
        minimum_required_evidence_actions=3,
    )
    attempt.submit_prediction(prediction())
    attempt.submit_conclusion(conclusion())
    assert attempt.state is AttemptState.CONCLUDED


def test_conclusion_requires_configured_minimum_evidence_actions() -> None:
    attempt = new_attempt(minimum_required_evidence_actions=3)
    attempt.submit_prediction(prediction())
    attempt.record_evidence_action("action-1")
    attempt.record_evidence_action("action-2")
    version = attempt.version

    with pytest.raises(
        IllegalAttemptTransition, match="at least 3 evidence actions"
    ):
        attempt.submit_conclusion(conclusion())

    assert attempt.state is AttemptState.INVESTIGATING
    assert attempt.conclusion is None
    assert attempt.version == version

    attempt.record_evidence_action("action-3")
    attempt.submit_conclusion(conclusion())
    assert attempt.state is AttemptState.CONCLUDED


@pytest.mark.parametrize("minimum", [-1, 7, 1.5, True, "3"])
def test_minimum_required_evidence_actions_is_bounded_integer(
    minimum: object,
) -> None:
    with pytest.raises(DomainError):
        new_attempt(minimum_required_evidence_actions=minimum)  # type: ignore[arg-type]


@pytest.mark.parametrize(
    ("operation", "starting_state"),
    [
        ("prediction", AttemptState.PREDICTED),
        ("prediction", AttemptState.INVESTIGATING),
        ("prediction", AttemptState.CONCLUDED),
        ("prediction", AttemptState.REFLECTED),
        ("prediction", AttemptState.COMPLETED),
        ("evidence", AttemptState.READY),
        ("evidence", AttemptState.CONCLUDED),
        ("evidence", AttemptState.REFLECTED),
        ("evidence", AttemptState.COMPLETED),
        ("conclusion", AttemptState.READY),
        ("conclusion", AttemptState.CONCLUDED),
        ("conclusion", AttemptState.REFLECTED),
        ("conclusion", AttemptState.COMPLETED),
        ("completion", AttemptState.READY),
        ("completion", AttemptState.PREDICTED),
        ("completion", AttemptState.INVESTIGATING),
        ("completion", AttemptState.REFLECTED),
    ],
)
def test_illegal_transitions_are_rejected_without_mutation(
    operation: str, starting_state: AttemptState
) -> None:
    attempt = new_attempt()
    attempt.state = starting_state
    version = attempt.version

    with pytest.raises(IllegalAttemptTransition):
        if operation == "prediction":
            attempt.submit_prediction(prediction())
        elif operation == "evidence":
            attempt.record_evidence_action("action-1")
        elif operation == "conclusion":
            attempt.submit_conclusion(conclusion())
        else:
            attempt.complete()

    assert attempt.state is starting_state
    assert attempt.version == version


def test_conclusion_requires_evidence_by_default() -> None:
    attempt = new_attempt()
    attempt.submit_prediction(prediction())
    version = attempt.version
    with pytest.raises(IllegalAttemptTransition, match="at least one evidence action"):
        attempt.submit_conclusion(conclusion())
    assert attempt.state is AttemptState.PREDICTED
    assert attempt.conclusion is None
    assert attempt.version == version


@pytest.mark.parametrize(
    "value_type", [AttemptId, LearnerId, MissionId, MissionVersion]
)
def test_typed_identifiers_cannot_be_blank(value_type: type) -> None:
    with pytest.raises(DomainError):
        value_type(" ")


@pytest.mark.parametrize("value", ["short", "x" * 129])
def test_idempotency_key_enforces_contract_length(value: str) -> None:
    with pytest.raises(DomainError):
        IdempotencyKey(value)


def test_axis_label_cannot_be_blank() -> None:
    with pytest.raises(DomainError):
        AxisAssessment(" ", Confidence.known(50))
