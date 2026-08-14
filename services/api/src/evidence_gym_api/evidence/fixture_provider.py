"""Offline deterministic evidence provider backed by Role 3 fixtures."""

from datetime import datetime

from evidence_gym_api.catalog.mission_fixture_reader import FileMissionPolicyReader
from evidence_gym_api.evidence.errors import (
    EvidenceActionNotFound,
    EvidenceMissionNotFound,
)
from evidence_gym_api.evidence.model import (
    EvidenceItem,
    EvidenceLicense,
    EvidenceResult,
    EvidenceSource,
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
                    source=_source_from_document(_required_document(item["source"])),
                    source_url=_optional_string(item, "sourceUrl"),
                    retrieved_at=_required_datetime(item["retrievedAt"]),
                    verification_status=VerificationStatus(
                        item["verificationStatus"]
                    ),
                )
                for item in document["items"]
            ),
            limitations=tuple(document["limitations"]),
        )


def _parse_datetime(value: str | None) -> datetime | None:
    if value is None:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _required_datetime(value: str) -> datetime:
    parsed = _parse_datetime(value)
    assert parsed is not None
    return parsed


def _optional_string(document: dict[str, object], key: str) -> str | None:
    value = document.get(key)
    return value if isinstance(value, str) else None


def _required_document(value: object) -> dict[str, object]:
    assert isinstance(value, dict)
    return value


def _source_from_document(source: dict[str, object]) -> EvidenceSource:
    license_document = _required_document(source["license"])
    return EvidenceSource(
        source_type=str(source["sourceType"]),
        publisher=str(source["publisher"]),
        author=_optional_string(source, "author"),
        canonical_url=_optional_string(source, "canonicalUrl"),
        canonical_id=_optional_string(source, "canonicalId"),
        published_at=_parse_datetime(_optional_string(source, "publishedAt")),
        retrieved_at=_required_datetime(str(source["retrievedAt"])),
        snapshot_hash=_optional_string(source, "snapshotHash"),
        license=EvidenceLicense(
            identifier=str(license_document["identifier"]),
            attribution=str(license_document["attribution"]),
            use_basis=str(license_document["useBasis"]),
        ),
        limitations=tuple(
            item for item in source["limitations"] if isinstance(item, str)
        ),
    )
