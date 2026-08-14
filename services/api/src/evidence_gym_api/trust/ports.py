"""Application ports for learner content report submission."""

from typing import Protocol

from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class MissionVersionResolver(Protocol):
    async def resolve(self, mission_id: MissionId) -> MissionVersion | None: ...


class ReportIdGenerator(Protocol):
    def new(self) -> str: ...
