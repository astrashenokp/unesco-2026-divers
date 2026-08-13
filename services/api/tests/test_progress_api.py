"""Authenticated learner progress query tests."""

from datetime import UTC, datetime

from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app
from evidence_gym_api.identity import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.ports import ProgressResult, SkillProgress
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.progress.api import ProgressServices
from evidence_gym_api.progress.use_cases import GetMyProgress


LEARNER = LearnerId("learner-progress")


class LearnerProgressReader:
    async def get_for_learner(self, learner_id):
        if learner_id == LEARNER:
            return ProgressResult(
                total_xp=6,
                skills=(
                    SkillProgress(
                        skill="source-checking",
                        mastery=0.4,
                        due_at=datetime(2026, 8, 14, 12, 0, tzinfo=UTC),
                    ),
                ),
            )
        return ProgressResult(total_xp=0, skills=())


def make_client() -> TestClient:
    return TestClient(
        create_app(
            identity_verifier=FakeIdentityVerifier(
                {
                    "learner-token": Principal(LEARNER),
                    "new-learner-token": Principal(LearnerId("new-learner")),
                }
            ),
            progress_services=ProgressServices(
                GetMyProgress(LearnerProgressReader())
            ),
        )
    )


def test_progress_matches_public_contract_shape() -> None:
    with make_client() as client:
        response = client.get(
            "/me/progress",
            headers={"Authorization": "Bearer learner-token"},
        )

    assert response.status_code == 200
    assert response.json() == {
        "totalXp": 6,
        "skills": [
            {
                "skill": "source-checking",
                "mastery": 0.4,
                "dueAt": "2026-08-14T12:00:00Z",
            }
        ],
    }


def test_new_learner_receives_empty_zero_progress() -> None:
    with make_client() as client:
        response = client.get(
            "/me/progress",
            headers={"Authorization": "Bearer new-learner-token"},
        )

    assert response.status_code == 200
    assert response.json() == {"totalXp": 0, "skills": []}


def test_progress_requires_verified_identity() -> None:
    with make_client() as client:
        missing = client.get("/me/progress")
        invalid = client.get(
            "/me/progress",
            headers={"Authorization": "Bearer invalid-token"},
        )

    assert missing.status_code == invalid.status_code == 401


def test_progress_operation_id_matches_normative_contract() -> None:
    with make_client() as client:
        operation = client.app.openapi()["paths"]["/me/progress"]["get"]

    assert operation["operationId"] == "getMyProgress"
