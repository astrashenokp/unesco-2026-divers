"""Contract checks for P0 mission fixtures shared by Role 1/2/3/4."""

from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path

from conftest import REPOSITORY_ROOT


PACK_ROOT = REPOSITORY_ROOT / "content" / "p0-demo-pack"
MANIFEST_PATH = PACK_ROOT / "manifest.json"
COACH_EVALS_PATH = REPOSITORY_ROOT / "evals" / "coach" / "p0-eval-cases.json"


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


def test_p0_demo_manifest_does_not_claim_public_review() -> None:
    manifest = load_json(MANIFEST_PATH)
    review = manifest["review"]

    assert review["status"] == "draft"
    assert "draftedAt" in review
    assert "reviewedAt" not in review
    assert review["reviewerIds"] == []


def test_p0_missions_have_explicit_critical_ignoring_policy() -> None:
    for path in mission_paths():
        mission = load_json(path)

        assert mission["schemaVersion"] == 2, mission["id"]
        assert isinstance(mission["testsCriticalIgnoring"], bool), mission["id"]


def test_draft_p0_missions_do_not_claim_review_completion() -> None:
    for path in mission_paths():
        mission = load_json(path)
        review = mission["review"]

        assert review["status"] == "draft", mission["id"]
        assert "draftedAt" in review, mission["id"]
        assert "reviewedAt" not in review, mission["id"]
        assert review["reviewerIds"] == [], mission["id"]


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


def test_p0_missions_have_accessibility_contract_fields() -> None:
    for path in mission_paths():
        mission = load_json(path)
        accessibility = mission["presentation"]["accessibility"]

        assert accessibility["plainLanguageSummary"], mission["id"]
        assert accessibility["mediaAlternatives"], mission["id"]
        assert accessibility["interactionNotes"], mission["id"]


def test_p0_mission_media_asset_urls_resolve_to_checked_in_files() -> None:
    manifest = load_json(MANIFEST_PATH)
    asset_prefix = f"asset://{manifest['id']}/"
    pack_root = PACK_ROOT.resolve()

    for path in mission_paths():
        mission = load_json(path)
        media = mission["presentation"]["media"]
        if media["type"] not in {"image", "video", "audio"}:
            continue

        media_url = media["url"]
        assert media_url.startswith(asset_prefix), mission["id"]
        asset_path = (PACK_ROOT / media_url.removeprefix(asset_prefix)).resolve()
        assert asset_path.is_relative_to(pack_root), mission["id"]
        assert asset_path.is_file(), (mission["id"], media_url)
        assert asset_path.stat().st_size > 0, (mission["id"], media_url)


def test_p0_mission_contract_invariants_are_unambiguous() -> None:
    for path in mission_paths():
        mission = load_json(path)

        action_ids = [action["id"] for action in mission["evidenceActions"]]
        assert len(action_ids) == len(set(action_ids)), mission["id"]

        evidence_ids = [
            evidence["evidenceId"]
            for evidence in mission["goldEvidenceGraph"]["evidence"]
        ]
        assert len(evidence_ids) == len(set(evidence_ids)), mission["id"]

        assert [hint["level"] for hint in mission["hintLadder"]] == [
            1,
            2,
            3,
            4,
            5,
        ], mission["id"]
        assert [level["level"] for level in mission["rubric"]["processLevels"]] == [
            0,
            1,
            2,
            3,
            4,
        ], mission["id"]

        for axis_name, axis in mission["acceptedAssessments"].items():
            confidence_range = axis["confidenceRange"]
            assert confidence_range["minimum"] <= confidence_range["maximum"], (
                mission["id"],
                axis_name,
            )


def test_p0_mission_eval_hooks_reference_known_coach_cases() -> None:
    eval_cases = {case["id"]: case for case in load_json(COACH_EVALS_PATH)["cases"]}

    for path in mission_paths():
        mission = load_json(path)
        eval_hooks = mission["rubric"]["evalHooks"]

        assert eval_hooks["observableSignals"], mission["id"]
        assert eval_hooks["blockingFailureSignals"], mission["id"]
        for case_ref in eval_hooks["coachEvalCaseRefs"]:
            assert case_ref in eval_cases, (mission["id"], case_ref)
            assert eval_cases[case_ref]["missionId"] == mission["id"], (
                mission["id"],
                case_ref,
            )


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
                gold_evidence = next(
                    evidence
                    for evidence in mission["goldEvidenceGraph"]["evidence"]
                    if evidence["evidenceId"] == item["evidenceId"]
                )
                assert item["type"] == gold_evidence["type"], (
                    mission["id"],
                    item["evidenceId"],
                )
                assert item["title"] == gold_evidence["title"], (
                    mission["id"],
                    item["evidenceId"],
                )
                assert item["retrievedAt"] == gold_evidence["source"]["retrievedAt"], (
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


def test_citation_not_found_registry_lookup_is_citable_limited_evidence() -> None:
    mission = load_json(PACK_ROOT / "missions/ai-citation-integrity.json")
    registry_action = next(
        action
        for action in mission["evidenceActions"]
        if action["id"] == "action-registry-lookup"
    )
    response = registry_action["deterministicResponse"]
    gold_by_id = {
        evidence["evidenceId"]: evidence
        for evidence in mission["goldEvidenceGraph"]["evidence"]
    }

    assert response["status"] == "not_found"
    assert [item["evidenceId"] for item in response["items"]] == [
        "E-DOI-NOT-FOUND"
    ]

    doi_not_found = gold_by_id["E-DOI-NOT-FOUND"]
    assert doi_not_found["type"] == "registry_record"
    assert doi_not_found["claimRelationship"] == "not_found_in_queried_sources"
    assert doi_not_found["source"]["sourceType"] == "academic_registry"
    assert doi_not_found["source"]["retrievedAt"] == response["items"][0]["retrievedAt"]

    source_limitations = " ".join(doi_not_found["source"]["limitations"]).lower()
    assert "not proof" in source_limitations
    assert "fabricated" in source_limitations

    for axis_name in ("claimVeracity", "contextIntegrity"):
        refs = mission["acceptedAssessments"][axis_name]["rationaleEvidenceRefs"]
        assert "E-DOI-NOT-FOUND" in refs


def test_citation_rubric_requires_multiple_distinct_checks() -> None:
    mission = load_json(PACK_ROOT / "missions/ai-citation-integrity.json")

    assert mission["rubric"]["minimumCompletionEvidence"] >= 3
