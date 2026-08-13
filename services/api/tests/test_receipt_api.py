"""Authorized Evidence Receipt use-case and HTTP tests."""

from datetime import UTC, datetime

from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app
from evidence_gym_api.identity import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.attempt import AxisAssessment, Confidence
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.receipt.api import ReceiptServices
from evidence_gym_api.receipt.model import EvidenceReceipt
from evidence_gym_api.receipt.use_cases import GetReceipt


LEARNER = LearnerId("learner-receipt-owner")
OTHER_LEARNER = LearnerId("learner-receipt-other")
RECEIPT = EvidenceReceipt(
    id="receipt-attempt-1",
    attempt_id="attempt-1",
    mission_version="mission-v1",
    assessments=(
        AxisAssessment("authentic", Confidence.known(70)),
        AxisAssessment("supported", Confidence.known(60)),
        AxisAssessment("accurate_context", Confidence.known(80)),
    ),
    evidence_refs=("inspect-source",),
    created_at=datetime(2026, 8, 13, 12, 0, tzinfo=UTC),
    hash="receipt-hash",
    disclaimer="This receipt records a learning process, not a universal truth verdict.",
)


class OwnedReceiptReader:
    async def get_for_learner(self, receipt_id, learner_id):
        if receipt_id == RECEIPT.id and learner_id == LEARNER:
            return RECEIPT
        return None


def make_client() -> TestClient:
    verifier = FakeIdentityVerifier(
        {
            "owner-token": Principal(LEARNER),
            "other-token": Principal(OTHER_LEARNER),
        }
    )
    return TestClient(
        create_app(
            identity_verifier=verifier,
            receipt_services=ReceiptServices(GetReceipt(OwnedReceiptReader())),
        )
    )


def test_owned_receipt_matches_public_contract_shape() -> None:
    with make_client() as client:
        response = client.get(
            f"/receipts/{RECEIPT.id}",
            headers={"Authorization": "Bearer owner-token"},
        )

    assert response.status_code == 200
    assert response.json() == {
        "id": "receipt-attempt-1",
        "attemptId": "attempt-1",
        "missionVersion": "mission-v1",
        "assessments": [
            {"label": "authentic", "confidence": 70},
            {"label": "supported", "confidence": 60},
            {"label": "accurate_context", "confidence": 80},
        ],
        "evidenceRefs": ["inspect-source"],
        "createdAt": "2026-08-13T12:00:00Z",
        "hash": "receipt-hash",
        "disclaimer": RECEIPT.disclaimer,
    }


def test_missing_and_foreign_receipts_are_indistinguishable() -> None:
    with make_client() as client:
        missing = client.get(
            "/receipts/does-not-exist",
            headers={"Authorization": "Bearer owner-token"},
        )
        foreign = client.get(
            f"/receipts/{RECEIPT.id}",
            headers={"Authorization": "Bearer other-token"},
        )

    assert missing.status_code == foreign.status_code == 404
    assert missing.json()["code"] == foreign.json()["code"] == "receipt-not-found"
    assert missing.json()["detail"] == foreign.json()["detail"]


def test_receipt_requires_verified_identity() -> None:
    with make_client() as client:
        response = client.get(f"/receipts/{RECEIPT.id}")

    assert response.status_code == 401


def test_receipt_operation_id_matches_normative_contract() -> None:
    with make_client() as client:
        operation = client.app.openapi()["paths"]["/receipts/{receiptId}"]["get"]

    assert operation["operationId"] == "getReceipt"
