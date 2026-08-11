"""Verified application identity values."""

from dataclasses import dataclass, field

from evidence_gym_api.learning.value_objects import LearnerId


@dataclass(frozen=True, slots=True)
class Principal:
    """Identity established by a trusted server-side verifier."""

    subject: LearnerId
    roles: frozenset[str] = field(default_factory=frozenset)

