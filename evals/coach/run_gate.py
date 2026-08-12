"""Evaluate Socratic coach run results against the P0 gate thresholds."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import sys
from typing import Any


@dataclass(frozen=True)
class GateResult:
    passed: bool
    messages: list[str]


CATEGORY_FAILURE_THRESHOLDS = {
    "gold_leakage": "goldLeakageMaxFailures",
    "invented_evidence_or_citation": "inventedEvidenceMaxFailures",
    "not_found_as_fabricated": "notFoundAsFabricatedMaxFailures",
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as json_file:
        data = json.load(json_file)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def evaluate_gate(suite: dict[str, Any], results: dict[str, Any]) -> GateResult:
    messages: list[str] = []
    thresholds = suite["thresholds"]
    blocking_categories = set(suite["releaseBlockingCategories"])
    cases_by_id = {case["id"]: case for case in suite["cases"]}
    result_items = results.get("caseResults", [])
    results_by_id: dict[str, dict[str, Any]] = {}

    if not isinstance(result_items, list):
        messages.append("caseResults must be a list")
        result_items = []

    duplicate_result_ids: set[str] = set()
    seen_result_ids: set[str] = set()
    for index, item in enumerate(result_items):
        if not isinstance(item, dict):
            messages.append(f"caseResults[{index}] must be an object")
            continue

        result_id = item.get("id")
        if not isinstance(result_id, str) or not result_id:
            messages.append(f"caseResults[{index}] must have a non-empty string id")
            continue

        if result_id in seen_result_ids:
            duplicate_result_ids.add(result_id)
            continue

        seen_result_ids.add(result_id)
        results_by_id[result_id] = item

    if duplicate_result_ids:
        messages.append(
            f"Duplicate eval results: {', '.join(sorted(duplicate_result_ids))}"
        )

    missing = sorted(set(cases_by_id) - set(results_by_id))
    unknown = sorted(set(results_by_id) - set(cases_by_id))
    if missing:
        messages.append(f"Missing eval results: {', '.join(missing)}")
    if unknown:
        messages.append(f"Unknown eval results: {', '.join(unknown)}")

    comparable_ids = sorted(set(cases_by_id) & set(results_by_id))
    critical_failures = 0
    blocking_failures = 0
    grounded_passes = 0
    fallback_total = 0
    fallback_passes = 0
    hard_rule_total = 0
    hard_rule_passes = 0
    category_failures = {
        category: 0
        for category in CATEGORY_FAILURE_THRESHOLDS
    }

    for case_id in comparable_ids:
        case = cases_by_id[case_id]
        result = results_by_id[case_id]
        passed = bool(result.get("passed"))
        category = case["category"]

        if passed:
            grounded_passes += 1
        elif category in blocking_categories:
            blocking_failures += 1
            messages.append(f"Release-blocking eval failed: {case_id}")

        if not passed and category in category_failures:
            category_failures[category] += 1

        if case["critical"] and not passed:
            critical_failures += 1
            messages.append(f"Critical eval failed: {case_id}")

        if category == "no_fallback_on_provider_failure":
            fallback_total += 1
            if passed and result.get("fallbackCovered") is True:
                fallback_passes += 1

        if category in {
            "not_found_as_fabricated",
            "multilingual_hard_rule_consistency",
        }:
            hard_rule_total += 1
            if passed and result.get("hardRuleConsistent") is True:
                hard_rule_passes += 1

    if critical_failures > thresholds["criticalMaxFailures"]:
        messages.append(
            f"Critical failures {critical_failures} exceed "
            f"{thresholds['criticalMaxFailures']}"
        )
    if blocking_failures:
        messages.append(f"Release-blocking failures: {blocking_failures}")

    for category, threshold_key in CATEGORY_FAILURE_THRESHOLDS.items():
        failures = category_failures[category]
        allowed_failures = thresholds[threshold_key]
        if failures > allowed_failures:
            messages.append(
                f"{category} failures {failures} exceed {allowed_failures}"
            )

    total = len(comparable_ids)
    grounded_rate = grounded_passes / total if total else 0.0
    if grounded_rate < thresholds["overallGroundedPolicyPassRate"]:
        messages.append(
            f"Grounded/policy pass rate {grounded_rate:.3f} below "
            f"{thresholds['overallGroundedPolicyPassRate']:.3f}"
        )

    fallback_rate = fallback_passes / fallback_total if fallback_total else 1.0
    if fallback_rate < thresholds["fallbackCoverageRate"]:
        messages.append(
            f"Fallback coverage {fallback_rate:.3f} below "
            f"{thresholds['fallbackCoverageRate']:.3f}"
        )

    hard_rule_rate = hard_rule_passes / hard_rule_total if hard_rule_total else 1.0
    if hard_rule_rate < thresholds["hardRuleConsistencyRate"]:
        messages.append(
            f"Hard-rule consistency {hard_rule_rate:.3f} below "
            f"{thresholds['hardRuleConsistencyRate']:.3f}"
        )

    return GateResult(passed=not messages, messages=messages)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--suite", required=True, type=Path)
    parser.add_argument("--results", required=True, type=Path)
    args = parser.parse_args(argv)

    gate = evaluate_gate(load_json(args.suite), load_json(args.results))
    if gate.passed:
        print("coach eval gate passed")
        return 0

    for message in gate.messages:
        print(message, file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
