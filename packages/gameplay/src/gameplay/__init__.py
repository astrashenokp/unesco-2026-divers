"""Server-authoritative gameplay rules: XP, skills, streak and unlock.

This package is a pure domain library. It deliberately has no FastAPI, HTTP
or storage dependencies. Application services (Role 2) and persistence
adapters (Role 4) stay behind the protocols in ``gameplay.ports``.
"""

from gameplay.path import PathNodeStatus, node_status, unlock_sequence
from gameplay.ports import SkillStateStore, StreakStore, XpLedger
from gameplay.skills import SkillState, practice
from gameplay.streak import StreakState, pause, record_activity
from gameplay.value_objects import ProcessLevel, XpGrant
from gameplay.xp import award_xp, process_level_for

__all__ = [
    "PathNodeStatus",
    "ProcessLevel",
    "SkillState",
    "SkillStateStore",
    "StreakStore",
    "StreakState",
    "XpGrant",
    "XpLedger",
    "award_xp",
    "node_status",
    "pause",
    "practice",
    "process_level_for",
    "record_activity",
    "unlock_sequence",
]
