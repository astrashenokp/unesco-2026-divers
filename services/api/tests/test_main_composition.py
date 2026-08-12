"""Default ASGI composition tests."""

from fastapi.testclient import TestClient

from evidence_gym_api.identity import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.main import app


def test_default_asgi_entrypoint_wires_learning_services_and_coach_hint() -> None:
    previous_verifier = getattr(app.state, "identity_verifier", None)
    app.state.identity_verifier = FakeIdentityVerifier(
        {"local-test-token": Principal(LearnerId("local-test-learner"))}
    )
    try:
        with TestClient(app) as client:
            started = client.post(
                "/attempts",
                headers={
                    "Authorization": "Bearer local-test-token",
                    "Idempotency-Key": "main-start-key-0001",
                },
                json={
                    "missionId": "authentic-media-wrong-context",
                    "missionVersion": "0.1.0",
                },
            )
            attempt_id = started.json()["id"]
            predicted = client.post(
                f"/attempts/{attempt_id}/prediction",
                headers={
                    "Authorization": "Bearer local-test-token",
                    "Idempotency-Key": "main-predict-key-0001",
                },
                json={
                    "reaction": "investigate",
                    "confidence": 60,
                    "version": started.json()["version"],
                },
            )
            hinted = client.post(
                f"/attempts/{attempt_id}/hints",
                headers={
                    "Authorization": "Bearer local-test-token",
                    "Idempotency-Key": "main-hint-key-0001",
                },
            )
    finally:
        app.state.identity_verifier = previous_verifier

    assert started.status_code == 201
    assert predicted.status_code == 200
    assert hinted.status_code == 200
    assert hinted.json()["fallback"] is True
    assert hinted.json()["safetyFlags"] == ["provider_degraded"]
