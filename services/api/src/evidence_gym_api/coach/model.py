"""Validated learner-facing Socratic hint values."""

from dataclasses import dataclass
from enum import StrEnum


class HintUncertainty(StrEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


@dataclass(frozen=True, slots=True)
class CoachHint:
    text: str
    level: int
    suggested_action_id: str | None
    evidence_refs: tuple[str, ...]
    uncertainty: HintUncertainty
    safety_flags: tuple[str, ...] = ()
    fallback: bool = False
