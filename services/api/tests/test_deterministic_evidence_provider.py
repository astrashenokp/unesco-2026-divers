"""Integration tests for Role 3 deterministic evidence responses."""

import asyncio
from datetime import UTC

import pytest

from conftest import REPOSITORY_ROOT
from evidence_gym_api.catalog import FileMissionPolicyReader
from evidence_gym_api.evidence import (
    EvidenceActionNotFound,
    EvidenceMissionNotFound,
    EvidenceStatus,
    FixtureDeterministicEvidenceProvider,
    VerificationStatus,
)
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


def run(coroutine):
    return asyncio.run(coroutine)


def provider() -> FixtureDeterministicEvidenceProvider:
    fixtures = FileMissionPolicyReader(
        pack_root=REPOSITORY_ROOT / "content" / "p0-demo-pack",
        manifest_schema_path=REPOSITORY_ROOT
        / "contracts"
        / "scenario-pack.schema.json",
        mission_schema_path=REPOSITORY_ROOT
        / "contracts"
        / "mission-fixture.schema.json",
    )
    return FixtureDeterministicEvidenceProvider(fixtures)


def test_provider_returns_normalized_curated_result_from_exact_mission() -> None:
    result = run(
        provider().get_result(
            MissionId("authentic-media-wrong-context"),
            MissionVersion("0.1.0"),
            "action-source-identity",
        )
    )

    assert result.action_id == "action-source-identity"
    assert result.status is EvidenceStatus.OK
    assert result.items
    assert result.items[0].verification_status is VerificationStatus.CURATED
    assert result.items[0].retrieved_at.tzinfo is UTC
    assert result.limitations


def test_not_found_remains_not_found_and_preserves_limitation() -> None:
    result = run(
        provider().get_result(
            MissionId("ai-citation-integrity"),
            MissionVersion("0.1.0"),
            "action-registry-lookup",
        )
    )

    assert result.status is EvidenceStatus.NOT_FOUND
    assert result.items == ()
    assert "does not prove fabrication" in " ".join(result.limitations).lower()


def test_provider_rejects_unknown_exact_mission_version() -> None:
    with pytest.raises(EvidenceMissionNotFound):
        run(
            provider().get_result(
                MissionId("ai-citation-integrity"),
                MissionVersion("0.2.0"),
                "action-registry-lookup",
            )
        )


def test_provider_rejects_action_not_allowed_by_pinned_mission() -> None:
    with pytest.raises(EvidenceActionNotFound):
        run(
            provider().get_result(
                MissionId("ai-citation-integrity"),
                MissionVersion("0.1.0"),
                "action-from-another-or-unknown-mission",
            )
        )


def test_provider_result_exposes_no_gold_or_scoring_fields() -> None:
    result = run(
        provider().get_result(
            MissionId("ai-citation-integrity"),
            MissionVersion("0.1.0"),
            "action-decompose-claim",
        )
    )

    assert set(result.__dataclass_fields__) == {
        "action_id",
        "status",
        "items",
        "limitations",
    }
    assert not hasattr(result, "accepted_assessments")
    assert not hasattr(result, "rubric")
    assert not hasattr(result, "gold_evidence_graph")


def test_result_is_immutable_and_cannot_modify_fixture_cache() -> None:
    evidence_provider = provider()
    first = run(
        evidence_provider.get_result(
            MissionId("ai-citation-integrity"),
            MissionVersion("0.1.0"),
            "action-decompose-claim",
        )
    )
    with pytest.raises(AttributeError):
        first.status = EvidenceStatus.BLOCKED  # type: ignore[misc]

    second = run(
        evidence_provider.get_result(
            MissionId("ai-citation-integrity"),
            MissionVersion("0.1.0"),
            "action-decompose-claim",
        )
    )
    assert second == first
