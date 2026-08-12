"""Evidence provider boundary consumed by Backend & Domain use cases."""

from typing import Protocol

from evidence_gym_api.evidence.model import EvidenceResult
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class DeterministicEvidenceProvider(Protocol):
    async def get_result(
        self,
        mission_id: MissionId,
        mission_version: MissionVersion,
        action_id: str,
    ) -> EvidenceResult: ...

