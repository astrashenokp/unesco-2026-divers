"""Compassionate streak rules.

The streak is optional, non-punitive and pauseable (GAME_AND_LEARNING_DESIGN).
It never punishes missed crisis days: activity inside a paused window cannot
break the streak, and a single freeze protects exactly one missed day. The
streak is a profile signal only — it is never a learning scheduler and never
used to gate rewards.

Day arithmetic uses calendar dates (UTC), not timestamps.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import date


class StreakRuleError(ValueError):
    """Raised when a streak state cannot be produced."""


@dataclass(frozen=True, slots=True)
class StreakState:
    """Snapshot of a learner's compassionate streak."""

    current: int = 0
    last_active: date | None = None
    paused_until: date | None = None
    freeze_available: bool = True

    def __post_init__(self) -> None:
        if isinstance(self.current, bool) or not isinstance(self.current, int):
            raise StreakRuleError("current must be an integer")
        if self.current < 0:
            raise StreakRuleError("current must not be negative")


def pause(state: StreakState, until: date) -> StreakState:
    """Pause the streak: activity through ``until`` (inclusive) is excused."""
    return replace(state, paused_until=until)


def record_activity(state: StreakState, today: date) -> StreakState:
    """Record an active day and return the new streak state."""
    if state.paused_until is not None and today <= state.paused_until:
        return state

    if state.last_active is None:
        return replace(state, current=1, last_active=today)

    effective_last = state.last_active
    if state.paused_until is not None and state.paused_until > effective_last:
        effective_last = state.paused_until

    gap = (today - effective_last).days
    if gap == 0:
        return state
    if gap == 1:
        return replace(state, current=state.current + 1, last_active=today)
    if gap == 2 and state.freeze_available:
        return replace(
            state,
            current=state.current + 1,
            last_active=today,
            freeze_available=False,
        )
    return replace(state, current=1, last_active=today)
