"""Checks that scaffold behavior remains compatible with the normative contract."""

from copy import deepcopy
import json
from pathlib import Path

import jsonschema
import yaml
from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app

from conftest import REPOSITORY_ROOT

CONTRACT_PATH = REPOSITORY_ROOT / "contracts" / "openapi.yaml"
COACH_OUTPUT_SCHEMA_PATH = REPOSITORY_ROOT / "contracts" / "coach-output.schema.json"
MISSION_FIXTURE_SCHEMA_PATH = (
    REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json"
)
SCENARIO_PACK_SCHEMA_PATH = REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json"
COACH_EVALS_PATH = REPOSITORY_ROOT / "evals" / "coach" / "p0-eval-cases.json"
P0_MANIFEST_PATH = REPOSITORY_ROOT / "content" / "p0-demo-pack" / "manifest.json"
P0_MISSIONS_PATH = REPOSITORY_ROOT / "content" / "p0-demo-pack" / "missions"


def load_contract() -> dict:
    with CONTRACT_PATH.open(encoding="utf-8") as contract_file:
        return yaml.safe_load(contract_file)


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as json_file:
        return json.load(json_file)


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


def test_json_contracts_parse_as_objects() -> None:
    for path in (
        COACH_OUTPUT_SCHEMA_PATH,
        MISSION_FIXTURE_SCHEMA_PATH,
        SCENARIO_PACK_SCHEMA_PATH,
    ):
        schema = load_json(path)

        assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
        assert schema["type"] == "object"
        assert schema["additionalProperties"] is False


def test_json_schema_contracts_are_valid_draft_2020_12() -> None:
    validator = jsonschema.validators.Draft202012Validator

    for path in (
        COACH_OUTPUT_SCHEMA_PATH,
        MISSION_FIXTURE_SCHEMA_PATH,
        SCENARIO_PACK_SCHEMA_PATH,
    ):
        validator.check_schema(load_json(path))


def test_p0_pack_and_missions_validate_against_schemas() -> None:
    manifest_schema = load_json(SCENARIO_PACK_SCHEMA_PATH)
    mission_schema = load_json(MISSION_FIXTURE_SCHEMA_PATH)
    format_checker = jsonschema.FormatChecker()

    jsonschema.Draft202012Validator(
        manifest_schema,
        format_checker=format_checker,
    ).validate(load_json(P0_MANIFEST_PATH))
    for path in sorted(P0_MISSIONS_PATH.glob("*.json")):
        jsonschema.Draft202012Validator(
            mission_schema,
            format_checker=format_checker,
        ).validate(load_json(path))


def test_draft_review_metadata_is_schema_rejected_when_claiming_review() -> None:
    manifest_schema = load_json(SCENARIO_PACK_SCHEMA_PATH)
    mission_schema = load_json(MISSION_FIXTURE_SCHEMA_PATH)
    format_checker = jsonschema.FormatChecker()

    manifest_validator = jsonschema.Draft202012Validator(
        manifest_schema,
        format_checker=format_checker,
    )
    mission_validator = jsonschema.Draft202012Validator(
        mission_schema,
        format_checker=format_checker,
    )

    manifest = deepcopy(load_json(P0_MANIFEST_PATH))
    manifest["review"]["reviewedAt"] = "2026-08-11T09:00:00Z"
    assert list(manifest_validator.iter_errors(manifest))

    mission = deepcopy(load_json(sorted(P0_MISSIONS_PATH.glob("*.json"))[0]))
    mission["review"]["reviewedAt"] = "2026-08-11T09:00:00Z"
    assert list(mission_validator.iter_errors(mission))


def test_coach_eval_fixture_has_expected_release_gate_shape() -> None:
    evals = load_json(COACH_EVALS_PATH)

    assert evals["schemaVersion"] == 1
    assert isinstance(evals["thresholds"], dict)
    assert isinstance(evals["releaseBlockingCategories"], list)
    assert isinstance(evals["cases"], list)


def test_mission_fixture_schema_is_strict_demo_contract() -> None:
    schema = load_json(MISSION_FIXTURE_SCHEMA_PATH)

    assert schema["$id"].endswith("mission-fixture.v2.json")
    assert schema["properties"]["schemaVersion"] == {"const": 2}

    assert "testsCriticalIgnoring" in schema["required"]
    assert schema["properties"]["testsCriticalIgnoring"]["type"] == "boolean"
    assert schema["properties"]["testsCriticalIgnoring"]["default"] is False

    presentation = schema["properties"]["presentation"]
    assert "accessibility" in presentation["required"]
    assert presentation["properties"]["accessibility"] == {
        "$ref": "#/$defs/accessibility"
    }
    assert schema["$defs"]["accessibility"]["properties"]["interactionNotes"][
        "minItems"
    ] == 1

    rubric = schema["properties"]["rubric"]
    assert "evalHooks" in rubric["required"]
    assert rubric["properties"]["evalHooks"] == {"$ref": "#/$defs/evalHooks"}

    assert "forbiddenLeakageTerms" in schema["required"]
    assert schema["properties"]["forbiddenLeakageTerms"]["minItems"] == 1
    assert "default" not in schema["properties"]["forbiddenLeakageTerms"]

    media = schema["$defs"]["media"]
    assert media["if"]["properties"]["type"]["enum"] == ["image", "video", "audio"]
    assert media["then"] == {"required": ["url"]}

    evidence_action = schema["$defs"]["evidenceAction"]
    assert evidence_action["additionalProperties"] is False
    assert "deterministicResponse" in evidence_action["required"]

    deterministic_response = schema["$defs"]["deterministicEvidenceResponse"]
    assert deterministic_response["additionalProperties"] is False
    assert deterministic_response["required"] == [
        "actionId",
        "status",
        "items",
        "limitations",
    ]


def test_public_mission_projection_exposes_accessibility_contract() -> None:
    schemas = load_contract()["components"]["schemas"]
    mission = schemas["Mission"]
    accessibility = schemas["Accessibility"]

    assert "accessibility" in mission["required"]
    assert mission["properties"]["accessibility"] == {
        "$ref": "#/components/schemas/Accessibility"
    }
    assert accessibility["additionalProperties"] is False
    assert accessibility["required"] == [
        "plainLanguageSummary",
        "mediaAlternatives",
        "interactionNotes",
    ]
    assert accessibility["properties"]["plainLanguageSummary"]["minLength"] == 1
    assert accessibility["properties"]["mediaAlternatives"]["minItems"] == 1
    assert accessibility["properties"]["interactionNotes"]["minItems"] == 1


def test_coach_output_schema_is_bounded_and_policy_visible() -> None:
    schema = load_json(COACH_OUTPUT_SCHEMA_PATH)

    assert schema["additionalProperties"] is False
    assert schema["required"] == [
        "text",
        "level",
        "suggestedActionId",
        "evidenceRefs",
        "uncertainty",
        "safetyFlags",
        "fallback",
    ]
    assert schema["properties"]["level"] == {
        "type": "integer",
        "minimum": 1,
        "maximum": 5,
    }
    assert "prompt_injection_detected" in schema["properties"]["safetyFlags"]["items"][
        "enum"
    ]
    assert "none" not in schema["properties"]["safetyFlags"]["items"]["enum"]


def test_mission_fixture_schema_local_references_resolve() -> None:
    schema = load_json(MISSION_FIXTURE_SCHEMA_PATH)

    def visit(value):
        if isinstance(value, dict):
            reference = value.get("$ref")
            if reference is not None:
                assert reference.startswith("#/")
                target = schema
                for component in reference[2:].split("/"):
                    target = target[component]
            for child in value.values():
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(schema)


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
