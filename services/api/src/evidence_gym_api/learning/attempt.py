"""Pure domain model for a learner's mission attempt.

This module deliberately has no FastAPI, persistence, or provider dependencies.
Application services are responsible for authentication, optimistic concurrency,
idempotency-key storage, and transactions around these domain operations.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum


class DomainError(ValueError):
    """Base class for rejected domain operations."""


class InvalidConfidence(DomainError):
    """Raised when a confidence value is outside its domain."""


class IllegalAttemptTransition(DomainError):
    """Raised when a command is not valid in the attempt's current state."""


class AttemptState(StrEnum):
    READY = "ready"
    PREDICTED = "predicted"
    INVESTIGATING = "investigating"
    CONCLUDED = "concluded"
    REFLECTED = "reflected"
    COMPLETED = "completed"


class ConfidenceStatus(StrEnum):
    KNOWN = "known"
    UNKNOWN = "unknown"
    NOT_ASKED = "not_asked"


@dataclass(frozen=True, slots=True)
class Confidence:
    """A 0-100 confidence or an explicit absence state."""

    status: ConfidenceStatus
    value: int | None = None

    def __post_init__(self) -> None:
        if self.status is ConfidenceStatus.KNOWN:
            if isinstance(self.value, bool) or not isinstance(self.value, int):
                raise InvalidConfidence("known confidence must be an integer")
            if not 0 <= self.value <= 100:
                raise InvalidConfidence("confidence must be between 0 and 100")
        elif self.value is not None:
            raise InvalidConfidence("unknown or not-asked confidence cannot have a value")

    @classmethod
    def known(cls, value: int) -> Confidence:
        return cls(status=ConfidenceStatus.KNOWN, value=value)

    @classmethod
    def unknown(cls) -> Confidence:
        return cls(status=ConfidenceStatus.UNKNOWN)

    @classmethod
    def not_asked(cls) -> Confidence:
        return cls(status=ConfidenceStatus.NOT_ASKED)


class Reaction(StrEnum):
    TRUST = "trust"
    SUSPICIOUS = "suspicious"
    INVESTIGATE = "investigate"


class ShareDecision(StrEnum):
    DO_NOT_SHARE = "do_not_share"
    SHARE_WITH_CONTEXT = "share_with_context"
    CONTINUE_INVESTIGATING = "continue_investigating"


INSUFFICIENT_EVIDENCE = "insufficient_evidence"


@dataclass(frozen=True, slots=True)
class Prediction:
    reaction: Reaction
    confidence: Confidence

    def __post_init__(self) -> None:
        if self.confidence.status is not ConfidenceStatus.KNOWN:
            raise InvalidConfidence("prediction confidence must be known")


@dataclass(frozen=True, slots=True)
class AxisAssessment:
    """One independent conclusion axis; labels are scenario-contract values."""

    label: str
    confidence: Confidence
    rationale_ref: str | None = None

    def __post_init__(self) -> None:
        if not self.label or not self.label.strip():
            raise DomainError("axis label must not be blank")
        if self.confidence.status is not ConfidenceStatus.KNOWN:
            raise InvalidConfidence("axis confidence must be known")

    @property
    def is_insufficient_evidence(self) -> bool:
        return self.label == INSUFFICIENT_EVIDENCE


@dataclass(frozen=True, slots=True)
class Conclusion:
    authenticity: AxisAssessment
    claim_veracity: AxisAssessment
    context_integrity: AxisAssessment
    post_confidence: Confidence
    share_decision: ShareDecision

    def __post_init__(self) -> None:
        if self.post_confidence.status is not ConfidenceStatus.KNOWN:
            raise InvalidConfidence("post-confidence must be known")


@dataclass(slots=True)
class Attempt:
    """Aggregate that owns mission-version pinning and learning transitions."""

    id: str
    mission_id: str
    mission_version: str
    allows_no_evidence_conclusion: bool = False
    state: AttemptState = field(default=AttemptState.READY, init=False)
    version: int = field(default=1, init=False)
    prediction: Prediction | None = field(default=None, init=False)
    evidence_action_refs: tuple[str, ...] = field(default=(), init=False)
    conclusion: Conclusion | None = field(default=None, init=False)

    def __setattr__(self, name: str, value: object) -> None:
        if name in {"mission_id", "mission_version"} and hasattr(self, name):
            raise AttributeError(f"{name} is pinned when an attempt is created")
        object.__setattr__(self, name, value)

    def __post_init__(self) -> None:
        for name, value in (
            ("attempt id", self.id),
            ("mission id", self.mission_id),
            ("mission version", self.mission_version),
        ):
            if not value or not value.strip():
                raise DomainError(f"{name} must not be blank")

    def submit_prediction(self, prediction: Prediction) -> None:
        self._require_state(AttemptState.READY)
        self.prediction = prediction
        self.state = AttemptState.PREDICTED
        self.version += 1

    def record_evidence_action(self, action_ref: str) -> None:
        self._require_state(AttemptState.PREDICTED, AttemptState.INVESTIGATING)
        if not action_ref or not action_ref.strip():
            raise DomainError("evidence action reference must not be blank")
        self.evidence_action_refs = (*self.evidence_action_refs, action_ref)
        self.state = AttemptState.INVESTIGATING
        self.version += 1

    def submit_conclusion(self, conclusion: Conclusion) -> None:
        self._require_state(AttemptState.PREDICTED, AttemptState.INVESTIGATING)
        if not self.evidence_action_refs and not self.allows_no_evidence_conclusion:
            raise IllegalAttemptTransition(
                "conclusion requires at least one evidence action"
            )
        self.conclusion = conclusion
        self.state = AttemptState.CONCLUDED
        self.version += 1

    def complete(self) -> None:
        """Complete once; request replay belongs to the idempotency layer."""

        self._require_state(AttemptState.CONCLUDED)
        self.state = AttemptState.COMPLETED
        self.version += 1

    def _require_state(self, *allowed: AttemptState) -> None:
        if self.state not in allowed:
            expected = ", ".join(state.value for state in allowed)
            raise IllegalAttemptTransition(
                f"operation requires state {expected}; current state is {self.state.value}"
            )
