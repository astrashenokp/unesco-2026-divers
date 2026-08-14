"""Resolve the pinned public mission version without exposing fixture internals."""

from typing import Any, Protocol

from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class PublicMissionReader(Protocol):
    async def get_public_mission(self, mission_id: MissionId) -> dict[str, Any] | None: ...


class CatalogMissionVersionResolver:
    def __init__(self, reader: PublicMissionReader) -> None:
        self._reader = reader

    async def resolve(self, mission_id: MissionId) -> MissionVersion | None:
        mission = await self._reader.get_public_mission(mission_id)
        if mission is None:
            return None
        version = mission.get("version")
        if not isinstance(version, str) or not version.strip():
            return None
        return MissionVersion(version)
