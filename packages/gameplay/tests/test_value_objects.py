import pytest

from gameplay.value_objects import ProcessLevel, XpGrant


@pytest.mark.parametrize(
    "factory",
    [
        lambda: XpGrant("", 1, 1),
        lambda: XpGrant("rule", -1, 1),
        lambda: XpGrant("rule", 1, 5),
        lambda: ProcessLevel(5, 1),
        lambda: ProcessLevel(1, -1),
    ],
)
def test_value_objects_reject_invalid_values(factory) -> None:
    with pytest.raises(ValueError):
        factory()
