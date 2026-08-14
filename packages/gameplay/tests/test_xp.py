from dataclasses import FrozenInstanceError
from inspect import signature

import pytest

from gameplay.value_objects import ProcessLevel, XpGrant
from gameplay.xp import XpRuleError, award_xp, process_level_for


def rubric() -> tuple[ProcessLevel, ...]:
    return tuple(ProcessLevel(level, level * 2) for level in range(5))


@pytest.mark.parametrize("actions, expected", [(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (9, 4)])
def test_process_level_is_bounded_and_zero_based(actions: int, expected: int) -> None:
    assert process_level_for(actions) == expected


@pytest.mark.parametrize("value", [-1, True, 1.0, "1"])
def test_process_level_rejects_invalid_action_count(value: object) -> None:
    with pytest.raises(XpRuleError):
        process_level_for(value)  # type: ignore[arg-type]


def test_award_xp_uses_version_pinned_rubric_and_stable_rule_code() -> None:
    first = award_xp(rubric(), 3)
    second = award_xp(rubric(), 3)

    assert first == second == (XpGrant("process-xp:3", 6, 3),)


def test_award_xp_has_no_truth_or_ai_inputs() -> None:
    parameters = set(signature(award_xp).parameters)

    assert parameters == {"process_levels", "used_evidence_actions"}
    assert not {
        "prediction_correct",
        "verdict",
        "claim_label",
        "model_score",
        "ai_score",
    } & parameters


@pytest.mark.parametrize(
    "levels",
    [
        tuple(ProcessLevel(level, level) for level in range(4)),
        tuple(ProcessLevel(level, level) for level in range(5)) + (ProcessLevel(4, 4),),
        (ProcessLevel(0, 0), ProcessLevel(1, 2), ProcessLevel(2, 1), ProcessLevel(3, 3), ProcessLevel(4, 4)),
    ],
)
def test_award_xp_rejects_invalid_rubric(levels: tuple[ProcessLevel, ...]) -> None:
    with pytest.raises(XpRuleError):
        award_xp(levels, 0)


def test_value_objects_are_immutable() -> None:
    grant = XpGrant("process-xp:1", 1, 1)
    with pytest.raises(FrozenInstanceError):
        grant.amount = 2  # type: ignore[misc]
