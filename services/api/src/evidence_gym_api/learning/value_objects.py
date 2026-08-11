"""Typed, persistence-agnostic learning identifiers."""

from dataclasses import dataclass

from evidence_gym_api.learning.attempt import DomainError


@dataclass(frozen=True, slots=True)
class _OpaqueValue:
    value: str

    def __post_init__(self) -> None:
        if not isinstance(self.value, str) or not self.value.strip():
            raise DomainError(f"{type(self).__name__} must not be blank")

    def __str__(self) -> str:
        return self.value


class AttemptId(_OpaqueValue):
    """Opaque attempt identifier."""


class MissionId(_OpaqueValue):
    """Opaque mission identifier."""


class MissionVersion(_OpaqueValue):
    """Exact immutable mission version selected for an attempt."""


class LearnerId(_OpaqueValue):
    """Server-derived learner subject identifier."""


@dataclass(frozen=True, slots=True)
class IdempotencyKey(_OpaqueValue):
    """Opaque retry key constrained by the normative API contract."""

    def __post_init__(self) -> None:
        super(IdempotencyKey, self).__post_init__()
        if not 8 <= len(self.value) <= 128:
            raise DomainError("IdempotencyKey must contain 8 to 128 characters")
