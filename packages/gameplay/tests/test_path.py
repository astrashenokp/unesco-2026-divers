import pytest

from gameplay.path import PathNodeStatus, PathRuleError, node_status, unlock_sequence


PATH = ("mission-1", "mission-2", "mission-3")


def test_linear_path_unlocks_only_after_previous_completion() -> None:
    assert node_status("mission-1", PATH, frozenset()) is PathNodeStatus.AVAILABLE
    assert node_status("mission-2", PATH, frozenset()) is PathNodeStatus.LOCKED
    assert node_status("mission-2", PATH, frozenset({"mission-1"})) is PathNodeStatus.AVAILABLE
    assert node_status("mission-1", PATH, frozenset({"mission-1"})) is PathNodeStatus.COMPLETED


def test_unlock_sequence_preserves_catalog_order() -> None:
    assert unlock_sequence(PATH, frozenset({"mission-1"})) == (
        ("mission-1", PathNodeStatus.COMPLETED),
        ("mission-2", PathNodeStatus.AVAILABLE),
        ("mission-3", PathNodeStatus.LOCKED),
    )


@pytest.mark.parametrize(
    "mission_id, path_ids",
    [("unknown", PATH), ("mission-1", ()), ("mission-1", ("mission-1", "mission-1"))],
)
def test_path_rejects_unknown_empty_or_duplicate_paths(mission_id: str, path_ids: tuple[str, ...]) -> None:
    with pytest.raises(PathRuleError):
        node_status(mission_id, path_ids, frozenset())
