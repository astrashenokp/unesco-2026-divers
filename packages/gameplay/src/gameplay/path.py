"""Unlock rules for the linear learning path.

P0 ships one linear learning path: the first mission is always available and
mission *N* unlocks only after mission *N-1* is completed. Path order is
defined by the catalog (``/catalog/path``); this module only decides the
state of a node given the completion set.
"""

from __future__ import annotations

from enum import StrEnum


class PathNodeStatus(StrEnum):
    LOCKED = "locked"
    AVAILABLE = "available"
    COMPLETED = "completed"


class PathRuleError(ValueError):
    """Raised when a path lookup is impossible."""


def node_status(
    mission_id: str,
    path_ids: tuple[str, ...],
    completed_ids: frozenset[str],
) -> PathNodeStatus:
    """Return the status of one mission on the linear path."""
    if not path_ids:
        raise PathRuleError("path must not be empty")
    if len(set(path_ids)) != len(path_ids):
        raise PathRuleError("path must not contain duplicate mission IDs")
    if mission_id not in path_ids:
        raise PathRuleError(f"mission {mission_id!r} is not on the path")
    if mission_id in completed_ids:
        return PathNodeStatus.COMPLETED

    index = path_ids.index(mission_id)
    if index == 0:
        return PathNodeStatus.AVAILABLE

    previous_completed = path_ids[index - 1] in completed_ids
    return PathNodeStatus.AVAILABLE if previous_completed else PathNodeStatus.LOCKED


def unlock_sequence(
    path_ids: tuple[str, ...],
    completed_ids: frozenset[str],
) -> tuple[tuple[str, PathNodeStatus], ...]:
    """Return the full path projection in catalog order."""
    return tuple(
        (mission_id, node_status(mission_id, path_ids, completed_ids))
        for mission_id in path_ids
    )
