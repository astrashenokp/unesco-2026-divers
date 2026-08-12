"""Offline deterministic evidence provider backed by Role 3 fixtures."""

from datetime import datetime

from evidence_gym_api.catalog.mission_fixture_reader import FileMissionPolicyReader
from evidence_gym_api.evidence.errors import (
    EvidenceActionNotFound,
    EvidenceMissionNotFound,
)
from evidence_gym_api.evidence.model import (
    EvidenceItem,
    EvidenceResult,
    EvidenceStatus,
    VerificationStatus,
)
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class FixtureDeterministicEvidenceProvider:
    """Return only schema-validated responses; never call a live provider."""

    def __init__(self, fixtures: FileMissionPolicyReader) -> None:
        self._fixtures = fixtures

    async def get_result(
        self,
        mission_id: MissionId,
        mission_version: MissionVersion,
        action_id: str,
    ) -> EvidenceResult:
        if await self._fixtures.get_policy(mission_id, mission_version) is None:
            raise EvidenceMissionNotFound("exact mission version is unavailable")
        document = await self._fixtures.get_deterministic_evidence_document(
            mission_id, mission_version, action_id
        )
        if document is None:
            raise EvidenceActionNotFound("action is not defined by the mission")

        return EvidenceResult(
            action_id=document["actionId"],
            status=EvidenceStatus(document["status"]),
            items=tuple(
                EvidenceItem(
                    evidence_id=item["evidenceId"],
                    type=item["type"],
                    title=item["title"],
                    source_url=item.get("sourceUrl"),
                    retrieved_at=datetime.fromisoformat(
                        item["retrievedAt"].replace("Z", "+00:00")
                    ),
                    verification_status=VerificationStatus(
                        item["verificationStatus"]
                    ),
                )
                for item in document["items"]
            ),
            limitations=tuple(document["limitations"]),
        )
