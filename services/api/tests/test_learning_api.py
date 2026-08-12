"""HTTP contract tests for the first learning mutations."""

from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app
from evidence_gym_api.identity import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.api import LearningServices
from evidence_gym_api.learning.ports import MissionPolicy
from evidence_gym_api.learning.testing import (
    FixedClock,
    InMemoryAttemptRepository,
    InMemoryIdempotencyRepository,
    InMemoryMissionPolicyReader,
    InMemoryTransactionManager,
    SequentialAttemptIdGenerator,
)
from evidence_gym_api.learning.use_cases import StartAttempt, SubmitPrediction
from evidence_gym_api.learning.use_cases import UseEvidenceAction, RequestHint
from evidence_gym_api.evidence import EvidenceResult, EvidenceStatus
from evidence_gym_api.coach import CoachHint, HintUncertainty
from evidence_gym_api.learning.value_objects import (
    LearnerId,
    MissionId,
    MissionVersion,
)

MISSION_ID = MissionId("mission-test-1")
MISSION_VERSION = MissionVersion("1.2.3")
LEARNER = Principal(LearnerId("learner-test-1"))
OTHER_LEARNER = Principal(LearnerId("learner-test-2"))


class StubEvidenceProvider:
    async def get_result(self, mission_id, mission_version, action_id):
        return EvidenceResult(action_id, EvidenceStatus.OK, (), ("fixture",))


class StubCoachPolicy:
    async def get_coach_request_data(self, mission_id, mission_version):
        return (("inspect-source",), {"inspect-source": ()})


class StubCoachProvider:
    async def request_hint(self, request):
        return CoachHint(
            "What source detail would you verify first?",
            request.level,
            "inspect-source",
            (),
            HintUncertainty.HIGH,
            ("provider_degraded",),
            True,
        )


def make_client() -> TestClient:
    attempts = InMemoryAttemptRepository()
    idempotency = InMemoryIdempotencyRepository()
    transactions = InMemoryTransactionManager()
    clock = FixedClock()
    missions = InMemoryMissionPolicyReader(
        (MissionPolicy(MISSION_ID, MISSION_VERSION),)
    )
    services = LearningServices(
        start_attempt=StartAttempt(
            attempts,
            missions,
            idempotency,
            SequentialAttemptIdGenerator(),
            transactions,
            clock,
        ),
        submit_prediction=SubmitPrediction(
            attempts, idempotency, transactions, clock
        ),
        use_evidence_action=UseEvidenceAction(
            attempts, StubEvidenceProvider(), idempotency, transactions, clock
        ),
        request_hint=RequestHint(
            attempts,
            StubCoachPolicy(),
            StubCoachProvider(),
            idempotency,
            transactions,
            clock,
        ),
    )
    verifier = FakeIdentityVerifier(
        {"learner-token": LEARNER, "other-token": OTHER_LEARNER}
    )
    return TestClient(
        create_app(identity_verifier=verifier, learning_services=services)
    )


def auth_headers(token: str = "learner-token", key: str = "start-key-0001"):
    return {"Authorization": f"Bearer {token}", "Idempotency-Key": key}


def start_attempt(client: TestClient, *, token: str = "learner-token"):
    return client.post(
        "/attempts",
        headers=auth_headers(token),
        json={"missionId": MISSION_ID.value, "missionVersion": MISSION_VERSION.value},
    )


def test_start_attempt_matches_openapi_shape_and_replays() -> None:
    with make_client() as client:
        first = start_attempt(client)
        replay = start_attempt(client)

    assert first.status_code == 201
    assert first.json() == {
        "id": "attempt-test-1",
        "missionId": MISSION_ID.value,
        "missionVersion": MISSION_VERSION.value,
        "state": "ready",
        "version": 1,
    }
    assert replay.status_code == 201
    assert replay.json() == first.json()


def test_implemented_route_templates_and_operation_ids_match_contract() -> None:
    with make_client() as client:
        generated = client.app.openapi()

    assert generated["paths"]["/attempts"]["post"]["operationId"] == "startAttempt"
    assert (
        generated["paths"]["/attempts/{attemptId}/prediction"]["post"][
            "operationId"
        ]
        == "submitPrediction"
    )
    assert (
        generated["paths"]["/attempts/{attemptId}/evidence-actions"]["post"][
            "operationId"
        ]
        == "useEvidenceAction"
    )
    assert (
        generated["paths"]["/attempts/{attemptId}/hints"]["post"]["operationId"]
        == "requestHint"
    )


def test_start_attempt_rejects_key_reuse_with_different_body() -> None:
    with make_client() as client:
        assert start_attempt(client).status_code == 201
        response = client.post(
            "/attempts",
            headers=auth_headers(),
            json={"missionId": "different", "missionVersion": "9.9.9"},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "idempotency-key-conflict"


def test_prediction_updates_attempt_and_replays() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client).json()["id"]
        headers = auth_headers(key="predict-key-001")
        body = {"reaction": "investigate", "confidence": 60, "version": 1}
        first = client.post(
            f"/attempts/{attempt_id}/prediction", headers=headers, json=body
        )
        replay = client.post(
            f"/attempts/{attempt_id}/prediction", headers=headers, json=body
        )

    assert first.status_code == 200
    assert first.json()["state"] == "predicted"
    assert first.json()["version"] == 2
    assert replay.json() == first.json()


def test_foreign_and_unknown_attempt_return_identical_non_leaking_404() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client, token="other-token").json()["id"]
        body = {"reaction": "trust", "confidence": 50, "version": 1}
        foreign = client.post(
            f"/attempts/{attempt_id}/prediction",
            headers=auth_headers(key="foreign-key-001"),
            json=body,
        )
        unknown = client.post(
            "/attempts/missing-attempt/prediction",
            headers=auth_headers(key="unknown-key-001"),
            json=body,
        )

    assert foreign.status_code == unknown.status_code == 404
    assert foreign.json()["code"] == unknown.json()["code"] == "attempt-not-found"
    assert foreign.json()["detail"] == unknown.json()["detail"]


def test_prediction_stale_version_returns_contract_conflict() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client).json()["id"]
        response = client.post(
            f"/attempts/{attempt_id}/prediction",
            headers=auth_headers(key="stale-key-0001"),
            json={"reaction": "trust", "confidence": 50, "version": 2},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "stale-attempt-version"


def test_evidence_action_returns_new_version_and_replays() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client).json()["id"]
        predicted = client.post(
            f"/attempts/{attempt_id}/prediction",
            headers=auth_headers(key="predict-key-001"),
            json={"reaction": "investigate", "confidence": 60, "version": 1},
        )
        body = {"actionId": "inspect-source", "input": {}, "version": 2}
        headers = auth_headers(key="evidence-key-001")
        first = client.post(
            f"/attempts/{attempt_id}/evidence-actions", headers=headers, json=body
        )
        replay = client.post(
            f"/attempts/{attempt_id}/evidence-actions", headers=headers, json=body
        )

    assert predicted.status_code == 200
    assert first.status_code == 200
    assert first.json() == {
        "actionId": "inspect-source",
        "status": "ok",
        "items": [],
        "limitations": ["fixture"],
        "attemptVersion": 3,
    }
    assert replay.json() == first.json()


def test_evidence_action_stale_version_and_changed_retry_return_409() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client).json()["id"]
        client.post(
            f"/attempts/{attempt_id}/prediction",
            headers=auth_headers(key="predict-key-001"),
            json={"reaction": "investigate", "confidence": 60, "version": 1},
        )
        stale = client.post(
            f"/attempts/{attempt_id}/evidence-actions",
            headers=auth_headers(key="stale-evidence-001"),
            json={"actionId": "inspect-source", "version": 1},
        )
        headers = auth_headers(key="evidence-key-001")
        client.post(
            f"/attempts/{attempt_id}/evidence-actions",
            headers=headers,
            json={"actionId": "inspect-source", "version": 2},
        )
        changed = client.post(
            f"/attempts/{attempt_id}/evidence-actions",
            headers=headers,
            json={"actionId": "different-action", "version": 2},
        )

    assert stale.status_code == 409
    assert stale.json()["code"] == "stale-attempt-version"
    assert changed.status_code == 409
    assert changed.json()["code"] == "idempotency-key-conflict"


def test_hint_returns_fallback_without_advancing_attempt_version() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client).json()["id"]
        client.post(
            f"/attempts/{attempt_id}/prediction",
            headers=auth_headers(key="predict-key-001"),
            json={"reaction": "investigate", "confidence": 60, "version": 1},
        )
        headers = auth_headers(key="hint-key-0001")
        first = client.post(f"/attempts/{attempt_id}/hints", headers=headers)
        replay = client.post(f"/attempts/{attempt_id}/hints", headers=headers)
        evidence = client.post(
            f"/attempts/{attempt_id}/evidence-actions",
            headers=auth_headers(key="after-hint-evidence"),
            json={"actionId": "inspect-source", "version": 2},
        )

    assert first.status_code == 200
    assert first.json() == {
        "text": "What source detail would you verify first?",
        "level": 1,
        "suggestedActionId": "inspect-source",
        "evidenceRefs": [],
        "uncertainty": "high",
        "fallback": True,
    }
    assert replay.json() == first.json()
    assert evidence.status_code == 200
    assert evidence.json()["attemptVersion"] == 3


def test_hint_hides_foreign_attempt_and_rejects_illegal_state() -> None:
    with make_client() as client:
        attempt_id = start_attempt(client, token="other-token").json()["id"]
        foreign = client.post(
            f"/attempts/{attempt_id}/hints",
            headers=auth_headers(key="foreign-hint-001"),
        )
        ready_id = start_attempt(client).json()["id"]
        ready = client.post(
            f"/attempts/{ready_id}/hints",
            headers=auth_headers(key="ready-hint-0001"),
        )

    assert foreign.status_code == 404
    assert foreign.json()["code"] == "attempt-not-found"
    assert ready.status_code == 409
    assert ready.json()["code"] == "attempt-conflict"


def test_learning_mutations_require_verified_bearer_token() -> None:
    with make_client() as client:
        missing = client.post(
            "/attempts",
            headers={"Idempotency-Key": "missing-auth-001"},
            json={"missionId": MISSION_ID.value, "missionVersion": MISSION_VERSION.value},
        )
        invalid = client.post(
            "/attempts",
            headers=auth_headers("invalid-token", "invalid-auth-001"),
            json={"missionId": MISSION_ID.value, "missionVersion": MISSION_VERSION.value},
        )

    assert missing.status_code == invalid.status_code == 401
    assert "traceId" in missing.json()
    assert "traceId" in invalid.json()


def test_request_models_reject_unknown_fields() -> None:
    with make_client() as client:
        response = client.post(
            "/attempts",
            headers=auth_headers(),
            json={
                "missionId": MISSION_ID.value,
                "missionVersion": MISSION_VERSION.value,
                "learnerId": "client-must-not-select-owner",
            },
        )

    assert response.status_code == 422
    assert response.json()["code"] == "request_validation_failed"


def test_start_attempt_missing_idempotency_key_returns_422() -> None:
    with make_client() as client:
        response = client.post(
            "/attempts",
            headers={"Authorization": "Bearer learner-token"},
            json={"missionId": MISSION_ID.value, "missionVersion": MISSION_VERSION.value},
        )

    assert response.status_code == 422


def test_start_attempt_with_unknown_mission_returns_409() -> None:
    with make_client() as client:
        response = client.post(
            "/attempts",
            headers=auth_headers(key="unknown-mission-key-001"),
            json={"missionId": "does-not-exist", "missionVersion": "1.0.0"},
        )

    assert response.status_code == 409
    assert response.json()["code"] == "mission-version-unavailable"
