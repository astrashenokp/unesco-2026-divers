"""HTTP contract tests for public catalog and mission projections."""

from fastapi.testclient import TestClient

from conftest import REPOSITORY_ROOT
from evidence_gym_api.app import create_app
from evidence_gym_api.catalog import FileMissionPolicyReader

PACK_ROOT = REPOSITORY_ROOT / "content" / "p0-demo-pack"
MANIFEST_SCHEMA = REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json"
MISSION_SCHEMA = REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json"


def make_reader() -> FileMissionPolicyReader:
    return FileMissionPolicyReader(
        pack_root=PACK_ROOT,
        manifest_schema_path=MANIFEST_SCHEMA,
        mission_schema_path=MISSION_SCHEMA,
    )


def make_client() -> TestClient:
    return TestClient(create_app(catalog_reader=make_reader()))


def test_catalog_path_returns_p0_demo_missions_without_auth() -> None:
    with make_client() as client:
        response = client.get("/catalog/path")

    assert response.status_code == 200
    assert response.json() == {
        "version": "0.1.0",
        "locale": "en",
        "nodes": [
            {
                "missionId": "authentic-media-wrong-context",
                "title": "Real Image, Wrong Story",
                "state": "available",
            },
            {
                "missionId": "ai-citation-integrity",
                "title": "The Citation That Sounds Real",
                "state": "available",
            },
        ],
    }


def test_mission_projection_exposes_accessibility_and_no_gold_material() -> None:
    with make_client() as client:
        response = client.get("/missions/authentic-media-wrong-context")

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "authentic-media-wrong-context"
    assert body["version"] == "0.1.0"
    assert body["media"] == {
        "type": "image",
        "url": "asset://p0-demo-pack/media/flood-context-card.jpg",
        "altText": (
            "A red car and other vehicles are partly submerged on a flooded city "
            "street during heavy rain."
        ),
    }
    assert body["accessibility"]["plainLanguageSummary"]
    assert body["accessibility"]["mediaAlternatives"]
    assert body["accessibility"]["interactionNotes"]
    assert [action["id"] for action in body["evidenceActions"]] == [
        "action-source-identity",
        "action-provenance-scan",
        "action-primary-source",
        "action-context-check",
        "action-corroboration",
    ]

    serialized = str(body)
    assert "goldEvidenceGraph" not in serialized
    assert "acceptedAssessments" not in serialized
    assert "deterministicResponse" not in serialized
    assert "hintLadder" not in serialized
    assert "rubric" not in serialized
    assert "E-ORIGINAL-CAPTION" not in serialized


def test_unknown_public_mission_returns_problem_404() -> None:
    with make_client() as client:
        response = client.get("/missions/missing-mission")

    assert response.status_code == 404
    assert response.json()["code"] == "mission-not-found"


def test_public_catalog_routes_match_contract_operation_ids() -> None:
    with make_client() as client:
        generated = client.app.openapi()

    assert generated["paths"]["/catalog/path"]["get"]["operationId"] == (
        "getLearningPath"
    )
    assert generated["paths"]["/missions/{missionId}"]["get"]["operationId"] == (
        "getMission"
    )


def test_default_asgi_entrypoint_serves_checked_in_catalog() -> None:
    from evidence_gym_api.main import app

    with TestClient(app) as client:
        response = client.get("/catalog/path")

    assert response.status_code == 200
    assert response.json()["nodes"][0]["missionId"] == "authentic-media-wrong-context"
