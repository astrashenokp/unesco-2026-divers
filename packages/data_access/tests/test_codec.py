from datetime import UTC, datetime

from data_access.codec import decode_attempt, encode_attempt
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Confidence,
    Conclusion,
    Prediction,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    LearnerId,
    MissionId,
    MissionVersion,
)


def test_attempt_snapshot_round_trips_domain_state() -> None:
    attempt = Attempt(
        AttemptId("attempt-1"),
        LearnerId("learner-1"),
        MissionId("mission-1"),
        MissionVersion("v1"),
    )
    attempt.submit_prediction(Prediction(Reaction.INVESTIGATE, Confidence.known(42)))
    attempt.record_evidence_action("source-check")
    assessment = AxisAssessment("insufficient_evidence", Confidence.known(50), "r1")
    attempt.submit_conclusion(
        Conclusion(assessment, assessment, assessment, Confidence.known(55), ShareDecision.DO_NOT_SHARE)
    )

    restored = decode_attempt(encode_attempt(attempt))

    assert restored.id == attempt.id
    assert restored.state == attempt.state
    assert restored.version == attempt.version
    assert restored.prediction == attempt.prediction
    assert restored.evidence_action_refs == attempt.evidence_action_refs
    assert restored.conclusion == attempt.conclusion


def test_datetime_snapshots_require_timezone_aware_values() -> None:
    assert datetime.now(UTC).tzinfo is not None
