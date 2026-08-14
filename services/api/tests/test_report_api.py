"""HTTP contract tests for authenticated learner content reports."""

from contextlib import asynccontextmanager
from copy import deepcopy
from datetime import UTC, datetime

from fastapi.testclient import TestClient

from data_access.errors import DataAccessError
from evidence_gym_api.app import create_app
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.in_memory import FixedClock
from evidence_gym_api.learning.value_objects import LearnerId, MissionId, MissionVersion
from evidence_gym_api.trust.api import ReportServices
from evidence_gym_api.trust.use_cases import SubmitReport


class HttpReportRepository:
    def __init__(self) -> None:
        self.results = {}
        self.accepted = []
        self.failure: Exception | None = None

    async def get(self, scope, *, at):
        if self.failure is not None:
            raise self.failure
        return deepcopy(self.results.get(scope))

    async def put(self, scope, result):
        if self.failure is not None:
            raise self.failure
        existing = self.results.get(scope)
        if existing is not None and existing.request_fingerprint != result.request_fingerprint:
            raise RepositoryConflict("different report already exists")
        self.results[scope] = deepcopy(result)
        self.accepted.append(deepcopy(result.report))


class HttpVersionResolver:
    async def resolve(self, mission_id):
        if mission_id == MissionId("mission-one"):
            return MissionVersion("0.1.0")
        return None


class HttpReportIds:
    def __init__(self) -> None:
        self.value = 0

    def new(self) -> str:
        self.value += 1
        return f"report-http-{self.value}"


class HttpTransactions:
    @asynccontextmanager
    async def transaction(self):
        yield


def make_client(repository: HttpReportRepository | None = None) -> tuple[TestClient, HttpReportRepository]:
    repository = repository or HttpReportRepository()
    services = ReportServices(
        submit_report=SubmitReport(
            repository,
            HttpVersionResolver(),
            HttpReportIds(),
            HttpTransactions(),
            FixedClock(datetime(2026, 8, 14, 12, 0, tzinfo=UTC)),
        )
    )
    app = create_app(
        identity_verifier=FakeIdentityVerifier(
            {"reporter-token": Principal(LearnerId("verified-reporter"))}
        ),
        report_services=services,
    )
    return TestClient(app), repository


def headers(key: str = "report-key-one") -> dict[str, str]:
    return {
        "Authorization": "Bearer reporter-token",
        "Idempotency-Key": key,
    }


def body(**overrides):
    value = {
        "missionId": "mission-one",
        "reason": "harmful",
        "detail": "This may need review.",
    }
    value.update(overrides)
    return value


def test_report_returns_empty_202_and_uses_verified_reporter() -> None:
    client, repository = make_client()
    with client:
        response = client.post("/reports", headers=headers(), json=body())

    assert response.status_code == 202
    assert response.content == b""
    assert len(repository.accepted) == 1
    report = repository.accepted[0]
    assert report.reporter_id == "verified-reporter"
    assert report.mission_version == "0.1.0"


def test_report_requires_verified_identity() -> None:
    client, repository = make_client()
    with client:
        missing = client.post(
            "/reports",
            headers={"Idempotency-Key": "report-key-one"},
            json=body(),
        )
        invalid = client.post(
            "/reports",
            headers={
                "Authorization": "Bearer invalid-token",
                "Idempotency-Key": "report-key-one",
            },
            json=body(),
        )

    assert missing.status_code == invalid.status_code == 401
    assert repository.accepted == []


def test_report_rejects_invalid_body_and_idempotency_header() -> None:
    client, repository = make_client()
    cases = [
        ({"missionId": "mission-one", "reason": "unsupported"}, headers()),
        (body(detail="x" * 1001), headers()),
        (body(detail=None), headers()),
        (body(extra="not-allowed"), headers()),
        (body(), headers("short")),
    ]
    with client:
        responses = [
            client.post("/reports", headers=request_headers, json=request_body)
            for request_body, request_headers in cases
        ]

    assert all(response.status_code == 422 for response in responses)
    assert repository.accepted == []


def test_report_same_key_replays_without_duplicate_effects() -> None:
    client, repository = make_client()
    with client:
        first = client.post("/reports", headers=headers(), json=body())
        replay = client.post("/reports", headers=headers(), json=body())

    assert first.status_code == replay.status_code == 202
    assert first.content == replay.content == b""
    assert len(repository.accepted) == 1


def test_report_same_key_with_different_content_returns_stable_409() -> None:
    client, repository = make_client()
    with client:
        first = client.post("/reports", headers=headers(), json=body())
        conflict = client.post(
            "/reports",
            headers=headers(),
            json=body(detail="Different content"),
        )

    assert first.status_code == 202
    assert conflict.status_code == 409
    assert conflict.json()["code"] == "idempotency-key-conflict"
    assert len(repository.accepted) == 1


def test_report_persistence_failure_returns_safe_503() -> None:
    repository = HttpReportRepository()
    repository.failure = DataAccessError("database host and query details")
    client, _ = make_client(repository)
    with client:
        response = client.post("/reports", headers=headers(), json=body())

    assert response.status_code == 503
    assert response.json()["code"] == "report-persistence-unavailable"
    assert "database host" not in response.text


def test_report_service_without_durable_repository_returns_503() -> None:
    app = create_app(
        identity_verifier=FakeIdentityVerifier(
            {"reporter-token": Principal(LearnerId("verified-reporter"))}
        )
    )
    with TestClient(app) as client:
        response = client.post("/reports", headers=headers(), json=body())

    assert response.status_code == 503
    assert response.json()["code"] == "report-service-unavailable"


def test_report_operation_matches_normative_contract() -> None:
    client, _ = make_client()
    with client:
        operation = client.app.openapi()["paths"]["/reports"]["post"]

    assert operation["operationId"] == "reportContent"
    assert "202" in operation["responses"]
