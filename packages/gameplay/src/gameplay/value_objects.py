"""Value objects for gameplay scoring and progression."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class XpGrant:
    """One deterministic, idempotent XP ledger entry.

    ``rule_code`` is stable so the append-only ``xp_ledger`` can enforce the
    ``UNIQUE (attempt_id, rule_code)`` invariant under retries: the same
    attempt and rule always produces the same grant.
    """

    rule_code: str
    amount: int
    level: int

    def __post_init__(self) -> None:
        if not self.rule_code or not self.rule_code.strip():
            raise ValueError("rule_code must not be blank")
        if isinstance(self.amount, bool) or not isinstance(self.amount, int):
            raise ValueError("amount must be an integer")
        if self.amount < 0:
            raise ValueError("amount must not be negative")
        if isinstance(self.level, bool) or not isinstance(self.level, int):
            raise ValueError("level must be an integer")
        if not 0 <= self.level <= 4:
            raise ValueError("level must be between 0 and 4")


@dataclass(frozen=True, slots=True)
class ProcessLevel:
    """One rubric process level (0..4) from a version-pinned mission fixture.

    The mission rubric is curated Role 3 content; gameplay reads it and never
    hard-codes XP values.
    """

    level: int
    xp_guidance: int
    skill_tags: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if isinstance(self.level, bool) or not isinstance(self.level, int):
            raise ValueError("level must be an integer")
        if not 0 <= self.level <= 4:
            raise ValueError("level must be between 0 and 4")
        if isinstance(self.xp_guidance, bool) or not isinstance(self.xp_guidance, int):
            raise ValueError("xp_guidance must be an integer")
        if self.xp_guidance < 0:
            raise ValueError("xp_guidance must not be negative")
