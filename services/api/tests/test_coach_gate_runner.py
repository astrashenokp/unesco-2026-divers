"""Executable checks for the Socratic coach eval gate runner."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

from conftest import REPOSITORY_ROOT


SUITE_PATH = REPOSITORY_ROOT / "evals" / "coach" / "p0-eval-cases.json"
RUNNER_PATH = REPOSITORY_ROOT / "evals" / "coach" / "run_gate.py"


def load_suite() -> dict:
    with SUITE_PATH.open(encoding="utf-8") as suite_file:
        return json.load(suite_file)


def write_results(path: Path, case_results: list[dict]) -> None:
    path.write_text(
        json.dumps(
            {
                "suiteId": "coach-p0-gate",
                "caseResults": case_results,
            },
            indent=2,
        ),
        encoding="utf-8",
    )


def run_gate(results_path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(RUNNER_PATH),
            "--suite",
            str(SUITE_PATH),
            "--results",
            str(results_path),
        ],
        check=False,
        text=True,
        capture_output=True,
    )


def passing_results() -> list[dict]:
    results = []
    for case in load_suite()["cases"]:
        result = {
            "id": case["id"],
            "passed": True,
        }
        if case["category"] == "no_fallback_on_provider_failure":
            result["fallbackCovered"] = True
        if case["category"] in {
            "not_found_as_fabricated",
            "multilingual_hard_rule_consistency",
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


def test_coach_gate_runner_rejects_missing_case(tmp_path: Path) -> None:
    results_path = tmp_path / "results.json"
    write_results(results_path, passing_results()[:-1])

    result = run_gate(results_path)

    assert result.returncode == 1
    assert "Missing eval results" in result.stderr
