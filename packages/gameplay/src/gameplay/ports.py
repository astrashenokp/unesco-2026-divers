"""Persistence ports for server-authoritative gameplay state.

These protocols describe application boundaries only. Concrete PostgreSQL
adapters belong to the data-access package and must enforce retry and
idempotency invariants at the storage boundary.
"""

from __future__ import annotations

from typing import Protocol

from gameplay.skills import SkillState
from gameplay.streak import StreakState
from gameplay.value_objects import XpGrant


class XpLedger(Protocol):
    """Append a grant once for an attempt and stable rule code."""

    async def append(self, attempt_id: str, grant: XpGrant) -> None: ...


class SkillStateStore(Protocol):
    """Read and persist one learner skill projection."""

    async def get(self, learner_id: str, skill: str) -> SkillState | None: ...

    async def save(self, learner_id: str, state: SkillState) -> None: ...


class StreakStore(Protocol):
    """Read and persist the learner's non-punitive streak projection."""

    async def get(self, learner_id: str) -> StreakState | None: ...

    async def save(self, learner_id: str, state: StreakState) -> None: ...
