"""Executable checks for the Socratic coach eval gate runner."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

from conftest import REPOSITORY_ROOT


SUITE_PATH = REPOSITORY_ROOT / "evals" / "coach" / "p0-eval-cases.json"
RUNNER_PATH = REPOSITORY_ROOT / "evals" / "coach" / "run_gate.py"
FIXTURE_RESULTS_PATH = REPOSITORY_ROOT / "evals" / "coach" / "p0-fixture-results.json"


def load_suite() -> dict:
    with SUITE_PATH.open(encoding="utf-8") as suite_file:
        return json.load(suite_file)


def write_results(path: Path, case_results: list[dict]) -> None:
    write_results_document(
        path,
        {
            "suiteId": "coach-p0-gate",
            "caseResults": case_results,
        },
    )


def write_results_document(path: Path, document: dict) -> None:
    path.write_text(
        json.dumps(document, indent=2),
        encoding="utf-8",
    )


def run_gate(results_path: Path) -> subprocess.CompletedProcess[str]:
    return run_gate_with_suite(SUITE_PATH, results_path)


def run_gate_with_suite(
    suite_path: Path,
    results_path: Path,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(RUNNER_PATH),
            "--suite",
            str(suite_path),
            "--results",
            str(results_path),
        ],
        check=False,
        text=True,
        capture_output=True,
    )


def passing_results() -> list[dict]:
    return passing_results_for_suite(load_suite())


def passing_results_for_suite(suite: dict) -> list[dict]:
    results = []
    for case in suite["cases"]:
        result = {
            "id": case["id"],
            "passed": True,
        }
        if case["category"] in {
            "provider_timeout",
            "malformed_model_json",
            "deterministic_fallback",
        }:
            result["fallbackCovered"] = True
        if case["category"] in {
            "not_found_as_fabricated",
            "uk_en_critical_rule_consistency",
        }:
            result["hardRuleConsistent"] = True
        results.append(result)
    return results


def test_coach_gate_runner_accepts_full_passing_results(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    write_results(results_path, passing_results())

    result = run_gate(results_path)

    assert result.returncode == 0
    assert "coach eval gate passed" in result.stdout


def test_coach_gate_runner_rejects_critical_failure(tmp_path: Path) -> None:
    results = passing_results()
    results[0]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Critical eval failed" in result.stderr
    assert "Release-blocking eval failed" in result.stderr
    assert "gold_leakage failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_rejects_string_false_passed(tmp_path: Path) -> None:
    results = passing_results()
    results[0]["passed"] = "false"
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "caseResults[0].passed must be a boolean" in result.stderr
    assert "Critical eval failed" in result.stderr


def test_coach_gate_runner_rejects_missing_suite_id(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    write_results_document(
        results_path,
        {
            "caseResults": passing_results(),
        },
    )

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Result suiteId must be coach-p0-gate" in result.stderr


def test_coach_gate_runner_rejects_wrong_suite_id(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    write_results_document(
        results_path,
        {
            "suiteId": "other-suite",
            "caseResults": passing_results(),
        },
    )

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Result suiteId must be coach-p0-gate" in result.stderr


def test_coach_gate_runner_enforces_invented_evidence_ref_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "invented_evidence_ref"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "invented_evidence_ref failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_forged_citation_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "forged_citation"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "forged_citation failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_unsupported_verdict_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "unsupported_verdict"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "unsupported_verdict failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_not_found_threshold(tmp_path: Path) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "not_found_as_fabricated"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "not_found_as_fabricated failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_conflicting_evidence_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "conflicting_evidence"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "conflicting_evidence failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_insufficient_evidence_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "insufficient_evidence"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "insufficient_evidence failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_enforces_critical_rule_consistency_threshold(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_index = next(
        index
        for index, case in enumerate(suite["cases"])
        if case["category"] == "uk_en_critical_rule_consistency"
    )
    results[target_index]["passed"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "uk_en_critical_rule_consistency failures 1 exceed 0" in result.stderr


def test_coach_gate_runner_rejects_missing_case(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    write_results(results_path, passing_results()[:-1])

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Missing eval results" in result.stderr


def test_coach_gate_runner_rejects_duplicate_result_id(tmp_path: Path) -> None:
    results = passing_results()
    results.append(dict(results[0]))
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Duplicate eval results" in result.stderr


def test_coach_gate_runner_requires_fallback_coverage_per_p0_mission(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    results = passing_results()
    target_pair = ("ai-citation-integrity", "provider_timeout")
    for result_item in results:
        case = next(case for case in suite["cases"] if case["id"] == result_item["id"])
        if (case["missionId"], case["category"]) == target_pair:
            result_item["fallbackCovered"] = False
    results_path = tmp_path / "results.json"
    write_results(results_path, results)

    result = run_gate(results_path)

    assert result.returncode == 1
    assert (
        "Fallback coverage is not passing: "
        "ai-citation-integrity/provider_timeout"
        in result.stderr
    )


def test_coach_gate_runner_rejects_suite_missing_fallback_pair(
    tmp_path: Path,
) -> None:
    suite = load_suite()
    suite["cases"] = [
        case
        for case in suite["cases"]
        if not (
            case["missionId"] == "ai-citation-integrity"
            and case["category"] == "provider_timeout"
        )
    ]
    suite_path = tmp_path / "suite.json"
    results_path = tmp_path / "results.json"
    write_results_document(suite_path, suite)
    write_results(results_path, passing_results_for_suite(suite))

    result = run_gate_with_suite(suite_path, results_path)

    assert result.returncode == 1
    assert (
        "Missing fallback eval coverage: "
        "ai-citation-integrity/provider_timeout"
        in result.stderr
    )


def test_checked_in_fixture_results_pass_the_release_gate() -> None:
    result = run_gate(FIXTURE_RESULTS_PATH)

    assert result.returncode == 0, result.stderr
    assert "coach eval gate passed" in result.stdout
