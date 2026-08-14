"""End-to-end proof that the deployed composition persists in PostgreSQL."""

import os
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from conftest import REPOSITORY_ROOT
from data_access.db import Database
from data_access.readiness import DatabaseReadinessProbe
from evidence_gym_api.app import create_app
from evidence_gym_api.catalog import FileMissionPolicyReader
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.persistence import ServicesFactory

pytestmark = pytest.mark.skipif(
    not os.getenv("DATABASE_URL"),
    reason="set DATABASE_URL to run the PostgreSQL API wiring tests",
)

PACK_ROOT = REPOSITORY_ROOT / "content" / "p0-demo-pack"
MANIFEST_SCHEMA = REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json"
MISSION_SCHEMA = REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json"

MISSION_ID = "authentic-media-wrong-context"
MISSION_VERSION = "0.1.0"
OWNER = Principal(LearnerId("wiring-learner"))
OTHER = Principal(LearnerId("wiring-other-learner"))


def auth_headers(token: str, key: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Idempotency-Key": key}


def make_app() -> TestClient:
    fixture_reader = FileMissionPolicyReader(
        pack_root=PACK_ROOT,
        manifest_schema_path=MANIFEST_SCHEMA,
        mission_schema_path=MISSION_SCHEMA,
    )
    database = Database(os.environ["DATABASE_URL"])
    app = create_app(
        catalog_reader=fixture_reader,
        services_factory=ServicesFactory(fixture_reader),
        database=database,
        readiness_probe=DatabaseReadinessProbe(database),
        identity_verifier=FakeIdentityVerifier({"owner-token": OWNER, "other-token": OTHER}),
        path_prefix="/v1",
    )
    return TestClient(app)


def complete_learning_flow(client: TestClient, run_id: str) -> str:
    started = client.post(
        "/v1/attempts",
        headers=auth_headers("owner-token", f"wiring-start-{run_id}"),
        json={"missionId": MISSION_ID, "missionVersion": MISSION_VERSION},
    )
    assert started.status_code == 201
    attempt_id = started.json()["id"]

    predicted = client.post(
        f"/v1/attempts/{attempt_id}/prediction",
        headers=auth_headers("owner-token", f"wiring-predict-{run_id}"),
        json={"reaction": "investigate", "confidence": 60, "version": 1},
    )
    assert predicted.status_code == 200

    evidence = client.post(
        f"/v1/attempts/{attempt_id}/evidence-actions",
        headers=auth_headers("owner-token", f"wiring-evidence-{run_id}"),
        json={"actionId": "action-source-identity", "input": {}, "version": 2},
    )
    assert evidence.status_code == 200

    completed = client.post(
        f"/v1/attempts/{attempt_id}/conclusion",
        headers=auth_headers("owner-token", f"wiring-complete-{run_id}"),
        json={
            "authenticity": {"label": "authentic", "confidence": 80},
            "claimVeracity": {"label": "insufficient_evidence", "confidence": 65},
            "contextIntegrity": {"label": "misleading_context", "confidence": 85},
            "postConfidence": 75,
            "shareDecision": "share_with_context",
            "version": 3,
        },
    )
    assert completed.status_code == 200
    assert completed.json()["xpAwarded"] > 0
    return completed.json()["receiptId"]


def test_pg_wired_app_readiness_and_completion_flow() -> None:
    with make_app() as client:
        ready = client.get("/ready")
        assert ready.status_code == 200
        assert ready.json() == {"status": "ready"}

        run_id = uuid4().hex
        receipt_id = complete_learning_flow(client, run_id)

        owned = client.get(
            f"/v1/receipts/{receipt_id}",
            headers={"Authorization": "Bearer owner-token"},
        )
        assert owned.status_code == 200
        body = owned.json()
        assert body["id"] == receipt_id
        assert len(body["assessments"]) == 3
        assert body["evidenceRefs"] == ["action-source-identity"]
        assert body["disclaimer"].startswith(
            "This receipt records a learning process, not a universal truth verdict."
        )

        foreign = client.get(
            f"/v1/receipts/{receipt_id}",
            headers={"Authorization": "Bearer other-token"},
        )
        assert foreign.status_code == 404
        assert foreign.json()["code"] == "receipt-not-found"

        progress = client.get(
            "/v1/me/progress",
            headers={"Authorization": "Bearer owner-token"},
        )
        assert progress.status_code == 200
        assert progress.json()["totalXp"] > 0
        assert isinstance(progress.json()["skills"], list)

        report_headers = auth_headers("owner-token", f"wiring-report-{run_id}")
        report_body = {
            "missionId": MISSION_ID,
            "reason": "outdated",
            "detail": "The published context may need an update.",
        }
        reported = client.post(
            "/v1/reports",
            headers=report_headers,
            json=report_body,
        )
        replayed = client.post(
            "/v1/reports",
            headers=report_headers,
            json=report_body,
        )
        conflicting = client.post(
            "/v1/reports",
            headers=report_headers,
            json={**report_body, "reason": "incorrect"},
        )

        assert reported.status_code == replayed.status_code == 202
        assert reported.content == replayed.content == b""
        assert conflicting.status_code == 409
        assert conflicting.json()["code"] == "idempotency-key-conflict"
