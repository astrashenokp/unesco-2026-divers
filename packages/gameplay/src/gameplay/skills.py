"""Skill mastery and an explainable spaced-review schedule.

Algorithm version 1: each evidence action whose type matches a mission skill
tag adds ``MASTERY_PER_HIT`` (0.25) up to a 1.0 cap, matching the demo-scale
mirror the client already uses (four solid checks read as mastery). ``due_at``
follows doubling review intervals (1, 2, 4, 8 days) so recall is scheduled
explicitly — the streak is never used as the scheduler.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import datetime, timedelta

ALGORITHM_VERSION = 1
MASTERY_PER_HIT = 0.25
BASE_INTERVAL_DAYS = 1


class SkillRuleError(ValueError):
    """Raised when a skill state cannot be produced."""


@dataclass(frozen=True, slots=True)
class SkillState:
    """Snapshot of one skill's mastery and next review time."""

    skill: str
    mastery: float
    practices: int = 0
    due_at: datetime | None = None
    algorithm_version: int = ALGORITHM_VERSION

    def __post_init__(self) -> None:
        if not self.skill or not self.skill.strip():
            raise SkillRuleError("skill must not be blank")
        if isinstance(self.mastery, bool) or not isinstance(self.mastery, (int, float)):
            raise SkillRuleError("mastery must be a number")
        if not 0.0 <= self.mastery <= 1.0:
            raise SkillRuleError("mastery must be within [0, 1]")
        if isinstance(self.practices, bool) or not isinstance(self.practices, int):
            raise SkillRuleError("practices must be an integer")
        if self.practices < 0:
            raise SkillRuleError("practices must not be negative")


def practice(skill_state: SkillState, at: datetime) -> SkillState:
    """Record one evidence practice of the skill at ``at`` (UTC)."""
    if skill_state.algorithm_version != ALGORITHM_VERSION:
        raise SkillRuleError(
            f"unsupported algorithm_version {skill_state.algorithm_version}"
        )
    if at.tzinfo is None or at.utcoffset() is None:
        raise SkillRuleError("at must be timezone-aware")
    mastery = min(1.0, skill_state.mastery + MASTERY_PER_HIT)
    practices = skill_state.practices + 1
    due_at = _next_due(at, practices)
    return replace(
        skill_state, mastery=mastery, practices=practices, due_at=due_at
    )


def _next_due(at: datetime, practices: int) -> datetime:
    interval_days = BASE_INTERVAL_DAYS * (1 << (practices - 1))
    return at + timedelta(days=interval_days)
