from datetime import UTC, datetime, timedelta

import pytest

from gameplay.skills import ALGORITHM_VERSION, SkillRuleError, SkillState, practice


def test_practice_increases_mastery_and_doubles_review_interval() -> None:
    start = datetime(2026, 8, 12, tzinfo=UTC)
    state = SkillState("source_identity", 0.0)

    first = practice(state, start)
    second = practice(first, start)

    assert first.mastery == 0.25
    assert first.due_at == start + timedelta(days=1)
    assert second.mastery == 0.5
    assert second.due_at == start + timedelta(days=2)


def test_practice_caps_mastery_and_rejects_unknown_algorithm() -> None:
    start = datetime(2026, 8, 12, tzinfo=UTC)
    state = SkillState("source_identity", 0.9, practices=8)
    assert practice(state, start).mastery == 1.0

    with pytest.raises(SkillRuleError):
        practice(SkillState("source_identity", 0.0, algorithm_version=99), start)


def test_practice_requires_timezone_aware_timestamp() -> None:
    with pytest.raises(SkillRuleError):
        practice(SkillState("source_identity", 0.0), datetime(2026, 8, 12))


@pytest.mark.parametrize(
    "skill, mastery, practices",
    [("", 0.0, 0), ("source_identity", -0.1, 0), ("source_identity", 1.1, 0), ("source_identity", 0.0, -1)],
)
def test_skill_state_rejects_invalid_values(skill: str, mastery: float, practices: int) -> None:
    with pytest.raises(SkillRuleError):
        SkillState(skill, mastery, practices=practices)


def test_algorithm_version_is_explicit() -> None:
    assert SkillState("source_identity", 0.0).algorithm_version == ALGORITHM_VERSION
