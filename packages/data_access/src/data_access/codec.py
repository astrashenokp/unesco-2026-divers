"""Safe JSON snapshots for persistence replay and aggregate hydration."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from evidence_gym_api.coach.model import CoachHint, HintUncertainty
from evidence_gym_api.evidence.model import (
    EvidenceItem,
    EvidenceResult,
    EvidenceStatus,
    VerificationStatus,
)
from evidence_gym_api.learning.attempt import (
    Attempt,
    AttemptState,
    AxisAssessment,
    Conclusion,
    Confidence,
    ConfidenceStatus,
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
from evidence_gym_api.learning.ports import CompletionResult, ProgressResult, SkillProgress


def _datetime(value: datetime) -> str:
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("snapshot datetime must be timezone-aware")
    return value.isoformat()


def _confidence(value: Confidence) -> dict[str, Any]:
    return {"status": value.status.value, "value": value.value}


def _decode_confidence(value: dict[str, Any]) -> Confidence:
    return Confidence(ConfidenceStatus(value["status"]), value.get("value"))


def _axis(value: AxisAssessment) -> dict[str, Any]:
    return {
        "label": value.label,
        "confidence": _confidence(value.confidence),
    }


def encode_attempt(attempt: Attempt) -> dict[str, Any]:
    prediction = None
    if attempt.prediction is not None:
        prediction = {
            "reaction": attempt.prediction.reaction.value,
            "confidence": _confidence(attempt.prediction.confidence),
        }

    conclusion = None
    if attempt.conclusion is not None:
        conclusion = {
            "authenticity": _axis(attempt.conclusion.authenticity),
            "claim_veracity": _axis(attempt.conclusion.claim_veracity),
            "context_integrity": _axis(attempt.conclusion.context_integrity),
            "post_confidence": _confidence(attempt.conclusion.post_confidence),
            "share_decision": attempt.conclusion.share_decision.value,
        }

    return {
        "id": str(attempt.id),
        "learner_id": str(attempt.learner_id),
        "mission_id": str(attempt.mission_id),
        "mission_version": str(attempt.mission_version),
        "allows_no_evidence_conclusion": attempt.allows_no_evidence_conclusion,
        "minimum_required_evidence_actions": attempt.minimum_required_evidence_actions,
        "state": attempt.state.value,
        "version": attempt.version,
        "prediction": prediction,
        "evidence_action_refs": list(attempt.evidence_action_refs),
        "conclusion": conclusion,
    }


def _decode_axis(value: dict[str, Any]) -> AxisAssessment:
    return AxisAssessment(
        label=value["label"],
        confidence=_decode_confidence(value["confidence"]),
        rationale_ref=value.get("rationale_ref"),
    )


def decode_attempt(value: dict[str, Any]) -> Attempt:
    attempt = Attempt(
        id=AttemptId(value["id"]),
        learner_id=LearnerId(value["learner_id"]),
        mission_id=MissionId(value["mission_id"]),
        mission_version=MissionVersion(value["mission_version"]),
        allows_no_evidence_conclusion=value["allows_no_evidence_conclusion"],
        minimum_required_evidence_actions=value["minimum_required_evidence_actions"],
    )
    prediction = value.get("prediction")
    if prediction is not None:
        attempt.prediction = Prediction(
            reaction=Reaction(prediction["reaction"]),
            confidence=_decode_confidence(prediction["confidence"]),
        )
    conclusion = value.get("conclusion")
    if conclusion is not None:
        attempt.conclusion = Conclusion(
            authenticity=_decode_axis(conclusion["authenticity"]),
            claim_veracity=_decode_axis(conclusion["claim_veracity"]),
            context_integrity=_decode_axis(conclusion["context_integrity"]),
            post_confidence=_decode_confidence(conclusion["post_confidence"]),
            share_decision=ShareDecision(conclusion["share_decision"]),
        )
    attempt.state = AttemptState(value["state"])
    attempt.version = value["version"]
    attempt.evidence_action_refs = tuple(value["evidence_action_refs"])
    return attempt


def encode_evidence_result(result: EvidenceResult) -> dict[str, Any]:
    return {
        "action_id": result.action_id,
        "status": result.status.value,
        "items": [
            {
                "evidence_id": item.evidence_id,
                "type": item.type,
                "title": item.title,
                "retrieved_at": _datetime(item.retrieved_at),
                "verification_status": item.verification_status.value,
                "source_url": item.source_url,
            }
            for item in result.items
        ],
        "limitations": list(result.limitations),
    }


def decode_evidence_result(value: dict[str, Any]) -> EvidenceResult:
    return EvidenceResult(
        action_id=value["action_id"],
        status=EvidenceStatus(value["status"]),
        items=tuple(
            EvidenceItem(
                evidence_id=item["evidence_id"],
                type=item["type"],
                title=item["title"],
                retrieved_at=datetime.fromisoformat(item["retrieved_at"]),
                verification_status=VerificationStatus(item["verification_status"]),
                source_url=item.get("source_url"),
            )
            for item in value["items"]
        ),
        limitations=tuple(value["limitations"]),
    )


def encode_coach_hint(result: CoachHint) -> dict[str, Any]:
    return {
        "text": result.text,
        "level": result.level,
        "suggested_action_id": result.suggested_action_id,
        "evidence_refs": list(result.evidence_refs),
        "uncertainty": result.uncertainty.value,
        "safety_flags": list(result.safety_flags),
        "fallback": result.fallback,
    }


def decode_coach_hint(value: dict[str, Any]) -> CoachHint:
    return CoachHint(
        text=value["text"],
        level=value["level"],
        suggested_action_id=value.get("suggested_action_id"),
        evidence_refs=tuple(value["evidence_refs"]),
        uncertainty=HintUncertainty(value["uncertainty"]),
        safety_flags=tuple(value["safety_flags"]),
        fallback=value["fallback"],
    )


def encode_completion_result(result: CompletionResult) -> dict[str, Any]:
    return {
        "receipt_id": result.receipt_id,
        "xp_awarded": result.xp_awarded,
        "progress": {
            "total_xp": result.progress.total_xp,
            "skills": [
                {"skill": item.skill, "mastery": item.mastery, "due_at": _datetime(item.due_at) if item.due_at else None}
                for item in result.progress.skills
            ],
        },
    }


def decode_completion_result(value: dict[str, Any]) -> CompletionResult:
    return CompletionResult(
        receipt_id=value["receipt_id"],
        xp_awarded=value["xp_awarded"],
        progress=ProgressResult(
            total_xp=value["progress"]["total_xp"],
            skills=tuple(
                SkillProgress(
                    skill=item["skill"],
                    mastery=item["mastery"],
                    due_at=datetime.fromisoformat(item["due_at"]) if item["due_at"] else None,
                )
                for item in value["progress"]["skills"]
            ),
        ),
    )
