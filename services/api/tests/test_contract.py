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


def operations(contract: dict):
    for path, path_item in contract["paths"].items():
        for method, operation in path_item.items():
            if method.lower() in {"get", "post", "put", "patch", "delete"}:
                yield path, method.lower(), operation


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


def test_operation_ids_are_unique() -> None:
    operation_ids = [item[2]["operationId"] for item in operations(load_contract())]
    assert len(operation_ids) == len(set(operation_ids))


def test_every_mutation_requires_idempotency_key() -> None:
    contract = load_contract()
    expected_reference = "#/components/parameters/IdempotencyKey"
    for path, method, operation in operations(contract):
        if method in {"post", "put", "patch", "delete"}:
            references = {item.get("$ref") for item in operation.get("parameters", [])}
            assert expected_reference in references, f"{method.upper()} {path}"


def test_only_public_catalog_operations_disable_authentication() -> None:
    contract = load_contract()
    public_operations = {("/catalog/path", "get"), ("/missions/{missionId}", "get")}
    for path, method, operation in operations(contract):
        if (path, method) in public_operations:
            assert operation.get("security") == []
        else:
            assert operation.get("security", contract["security"])


def test_all_local_references_resolve() -> None:
    contract = load_contract()

    def visit(value):
        if isinstance(value, dict):
            reference = value.get("$ref")
            if reference is not None:
                assert reference.startswith("#/")
                target = contract
                for component in reference[2:].split("/"):
                    target = target[component]
            for child in value.values():
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(contract)


def test_documented_error_responses_use_problem_component() -> None:
    for path, method, operation in operations(load_contract()):
        for status, response in operation.get("responses", {}).items():
            if str(status).startswith(("4", "5")):
                assert response == {"$ref": "#/components/responses/Problem"}, (
                    f"{method.upper()} {path} {status}"
                )


class UnavailableProbe:
    async def is_ready(self) -> bool:
        return False
