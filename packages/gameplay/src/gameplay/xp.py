"""Process XP: deterministic award from the mission rubric.

The rubric (``rubric.processLevels``) is curated, version-pinned Role 3
content. Gameplay only decides *which level the evidence behaviour earned*;
the XP value always comes from the rubric, never from a hard-coded table.

Rule: process level = ``min(used_evidence_actions, 4)``. Zero actions is level
0 (instinct only). XP never depends on whether the conclusion was correct —
process is rewarded, not being right, and a wrong initial prediction is not
punished when the learner investigates well. ``insufficient_evidence`` can earn
top process XP when it follows a strong investigation. AI/model output is not an
input to this module.
"""

from __future__ import annotations

from gameplay.value_objects import ProcessLevel, XpGrant

MAX_PROCESS_LEVEL = 4


class XpRuleError(ValueError):
    """Raised when XP cannot be computed from the given facts."""


def process_level_for(used_evidence_actions: int) -> int:
    """Map the number of evidence actions used to a process level 0..4."""
    if isinstance(used_evidence_actions, bool) or not isinstance(
        used_evidence_actions, int
    ):
        raise XpRuleError("used_evidence_actions must be an integer")
    if used_evidence_actions < 0:
        raise XpRuleError("used_evidence_actions must not be negative")
    return min(used_evidence_actions, MAX_PROCESS_LEVEL)


def _index_by_level(process_levels: tuple[ProcessLevel, ...]) -> dict[int, ProcessLevel]:
    index: dict[int, ProcessLevel] = {}
    for entry in process_levels:
        if entry.level in index:
            raise XpRuleError(f"rubric has duplicate process level {entry.level}")
        index[entry.level] = entry
    for expected in range(MAX_PROCESS_LEVEL + 1):
        if expected not in index:
            raise XpRuleError(f"rubric is missing process level {expected}")
    guidance = [index[level].xp_guidance for level in range(MAX_PROCESS_LEVEL + 1)]
    if any(a > b for a, b in zip(guidance, guidance[1:])):
        raise XpRuleError("rubric xp_guidance must be monotonic by level")
    return index


def award_xp(
    process_levels: tuple[ProcessLevel, ...],
    used_evidence_actions: int,
) -> tuple[XpGrant, ...]:
    """Return the idempotent XP grants for a completed attempt.

    Level is derived from evidence behaviour; the XP amount is the rubric's
    own ``xp_guidance`` for that level. The rule code is stable per
    ``(attempt, process level)`` so a retry can never duplicate XP.
    """
    level = process_level_for(used_evidence_actions)
    index = _index_by_level(process_levels)
    guidance = index[level].xp_guidance
    return (XpGrant(rule_code=f"process-xp:{level}", amount=guidance, level=level),)
