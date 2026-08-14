"""Executable checks for the deterministic coach eval harness.

The harness is the honest executor for ``p0-eval-cases.json``: it runs every
case against the validated fixture coach (the same fallback-hint path the API
serves in demo mode) and never fabricates a result. These tests pin the harness
contract so suite changes cannot silently skip categories.
"""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

EVALS_ROOT = Path(__file__).resolve().parents[1]

HARNESS_PATH = EVALS_ROOT / "run_deterministic_harness.py"
SUITE_PATH = EVALS_ROOT / "p0-eval-cases.json"

FALLBACK_CATEGORIES = {
    "provider_timeout",
    "malformed_model_json",
    "deterministic_fallback",
}
HARD_RULE_CATEGORIES = {
    "not_found_as_fabricated",
    "uk_en_critical_rule_consistency",
}


def load_suite() -> dict:
    with SUITE_PATH.open(encoding="utf-8") as suite_file:
        return json.load(suite_file)


def run_harness(
    results_path: Path, live_provider: str | None = None
) -> subprocess.CompletedProcess[str]:
    command = [
        sys.executable,
        str(HARNESS_PATH),
        "--suite",
        str(SUITE_PATH),
        "--out",
        str(results_path),
    ]
    if live_provider is not None:
        command.extend(["--live-provider", live_provider])
    return subprocess.run(
        command,
        check=False,
        text=True,
        capture_output=True,
    )


def test_harness_executes_every_case_in_the_suite(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    result = run_harness(results_path)

    assert result.returncode == 0, result.stderr
    assert results_path.is_file()

    document = json.loads(results_path.read_text(encoding="utf-8"))
    suite = load_suite()
    expected_ids = [case["id"] for case in suite["cases"]]
    actual_ids = [item["id"] for item in document["caseResults"]]
    assert actual_ids == expected_ids
    assert document["suiteId"] == suite["suiteId"]


def test_harness_results_carry_gate_fields(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    run_harness(results_path)

    document = json.loads(results_path.read_text(encoding="utf-8"))
    suite = load_suite()
    by_id = {case["id"]: case for case in suite["cases"]}
    for item in document["caseResults"]:
        assert isinstance(item["passed"], bool)
        assert isinstance(item["reasons"], list)
        case = by_id[item["id"]]
        if case["category"] in FALLBACK_CATEGORIES:
            assert isinstance(item["fallbackCovered"], bool)
        if case["category"] in HARD_RULE_CATEGORIES:
            assert isinstance(item["hardRuleConsistent"], bool)


def test_harness_is_deterministic(tmp_path: Path) -> None:
    first_path = tmp_path / "first.json"
    second_path = tmp_path / "second.json"
    run_harness(first_path)
    run_harness(second_path)

    first = first_path.read_text(encoding="utf-8")
    second = second_path.read_text(encoding="utf-8")
    assert first == second


def test_harness_rejects_unknown_eval_category(tmp_path: Path) -> None:
    suite = load_suite()
    suite["cases"][0]["category"] = "not-a-real-category"
    suite_path = tmp_path / "suite.json"
    suite_path.write_text(json.dumps(suite), encoding="utf-8")
    results_path = tmp_path / "results.json"

    result = subprocess.run(
        [
            sys.executable,
            str(HARNESS_PATH),
            "--suite",
            str(suite_path),
            "--out",
            str(results_path),
        ],
        check=False,
        text=True,
        capture_output=True,
    )

    assert result.returncode == 1
    assert "unsupported eval category 'not-a-real-category'" in result.stderr
    assert not results_path.exists()


def test_harness_gate_consumable_results_exist_for_p0(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    run_harness(results_path)

    gate = subprocess.run(
        [
            sys.executable,
            str(EVALS_ROOT / "run_gate.py"),
            "--suite",
            str(SUITE_PATH),
            "--results",
            str(results_path),
        ],
        check=False,
        text=True,
        capture_output=True,
    )
    assert gate.returncode == 1
    assert "Missing eval results" not in gate.stderr
    assert "Duplicate eval results" not in gate.stderr
