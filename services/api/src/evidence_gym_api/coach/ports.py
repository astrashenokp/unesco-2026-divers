"""Role 3 coaching boundary consumed by Role 2 application logic."""

from dataclasses import dataclass
from typing import Protocol

from evidence_gym_api.coach.model import CoachHint
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


@dataclass(frozen=True, slots=True)
class CoachRequest:
    mission_id: MissionId
    mission_version: MissionVersion
    attempt_state: str
    level: int
    allowed_action_ids: tuple[str, ...]
    available_evidence_refs: tuple[str, ...]
    forbidden_terms: tuple[str, ...]


class CoachProvider(Protocol):
    async def request_hint(self, request: CoachRequest) -> CoachHint: ...


class CoachPolicyReader(Protocol):
    async def get_coach_request_data(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> tuple[tuple[str, ...], dict[str, tuple[str, ...]], tuple[str, ...]] | None: ...

    async def get_fallback_hint(
        self, mission_id: MissionId, mission_version: MissionVersion, level: int
    ) -> CoachHint | None: ...
