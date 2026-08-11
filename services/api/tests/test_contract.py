"""Checks that scaffold behavior remains compatible with the normative contract."""

from pathlib import Path

import yaml
from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app

from conftest import REPOSITORY_ROOT

CONTRACT_PATH = REPOSITORY_ROOT / "contracts" / "openapi.yaml"


def load_contract() -> dict:
    with CONTRACT_PATH.open(encoding="utf-8") as contract_file:
        return yaml.safe_load(contract_file)


def test_normative_contract_is_openapi_31_and_exposes_v1_server() -> None:
    contract = load_contract()

    assert contract["openapi"] == "3.1.0"
    assert contract["servers"][0]["url"].endswith("/v1")


def test_problem_response_has_contract_required_fields() -> None:
    required_fields = set(
        load_contract()["components"]["schemas"]["Problem"]["required"]
    )
    with TestClient(create_app(readiness_probe=UnavailableProbe())) as client:
        response = client.get("/ready")

    assert required_fields <= response.json().keys()
    assert response.headers["content-type"].startswith(
        "application/problem+json"
    )


def test_unknown_route_uses_problem_contract_and_trace_header() -> None:
    with TestClient(create_app()) as client:
        response = client.get("/does-not-exist")

    assert response.status_code == 404
    assert response.json()["code"] == "route_not_found"
    assert response.json()["traceId"] == response.headers["X-Trace-ID"]


class UnavailableProbe:
    async def is_ready(self) -> bool:
        return False

