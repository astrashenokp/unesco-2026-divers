"""Contract checks for P0 mission fixtures shared by Role 1/2/3/4."""

from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path

from conftest import REPOSITORY_ROOT


PACK_ROOT = REPOSITORY_ROOT / "content" / "p0-demo-pack"
MANIFEST_PATH = PACK_ROOT / "manifest.json"


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as json_file:
        return json.load(json_file)


def mission_paths() -> list[Path]:
    manifest = load_json(MANIFEST_PATH)
    return [PACK_ROOT / mission["file"] for mission in manifest["missions"]]


def test_p0_demo_manifest_hashes_match_mission_files() -> None:
    manifest = load_json(MANIFEST_PATH)

    for mission in manifest["missions"]:
        path = PACK_ROOT / mission["file"]
        digest = sha256(path.read_bytes()).hexdigest()

        assert digest == mission["sha256"], mission["id"]


def test_p0_missions_have_explicit_critical_ignoring_policy() -> None:
    for path in mission_paths():
        mission = load_json(path)

        assert isinstance(mission["testsCriticalIgnoring"], bool), mission["id"]


def test_every_p0_evidence_action_has_deterministic_response() -> None:
    for path in mission_paths():
        mission = load_json(path)
        actions = mission["evidenceActions"]

        assert 4 <= len(actions) <= 6, mission["id"]
        for action in actions:
            response = action["deterministicResponse"]

            assert response["actionId"] == action["id"]
            assert response["status"] in {"ok", "not_found", "unavailable", "blocked"}
            assert isinstance(response["items"], list)
            assert isinstance(response["limitations"], list)


def test_p0_mission_references_only_defined_evidence_and_actions() -> None:
    for path in mission_paths():
        mission = load_json(path)
        action_ids = {action["id"] for action in mission["evidenceActions"]}
        evidence_ids = {
            evidence["evidenceId"]
            for evidence in mission["goldEvidenceGraph"]["evidence"]
        }

        for action in mission["evidenceActions"]:
            for item in action["deterministicResponse"]["items"]:
                assert item["evidenceId"] in evidence_ids, (
                    mission["id"],
                    item["evidenceId"],
                )

        for axis in mission["acceptedAssessments"].values():
            for evidence_ref in axis["rationaleEvidenceRefs"]:
                assert evidence_ref in evidence_ids, (mission["id"], evidence_ref)

        for hint in mission["hintLadder"]:
            suggested_action_id = hint["suggestedActionId"]
            if suggested_action_id is not None:
                assert suggested_action_id in action_ids, (
                    mission["id"],
                    suggested_action_id,
                )
            for evidence_ref in hint["evidenceRefs"]:
                assert evidence_ref in evidence_ids, (mission["id"], evidence_ref)

        for relationship in mission["goldEvidenceGraph"]["relationships"]:
            assert relationship["fromEvidenceId"] in evidence_ids
            assert relationship["toEvidenceId"] in evidence_ids


def test_not_found_responses_preserve_uncertainty_not_fabrication() -> None:
    for path in mission_paths():
        mission = load_json(path)
        for action in mission["evidenceActions"]:
            response = action["deterministicResponse"]
            if response["status"] != "not_found":
                continue

            limitations = " ".join(response["limitations"]).lower()
            assert "does not prove fabrication" in limitations
