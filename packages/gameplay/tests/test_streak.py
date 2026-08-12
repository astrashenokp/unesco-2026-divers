from datetime import date

from gameplay.streak import StreakState, pause, record_activity


def test_streak_increments_once_per_calendar_day() -> None:
    state = record_activity(StreakState(), date(2026, 8, 12))
    state = record_activity(state, date(2026, 8, 12))
    state = record_activity(state, date(2026, 8, 13))

    assert state.current == 2
    assert state.last_active == date(2026, 8, 13)


def test_freeze_protects_one_missed_day_without_resetting_streak() -> None:
    state = StreakState(current=3, last_active=date(2026, 8, 12))
    state = record_activity(state, date(2026, 8, 14))

    assert state.current == 4
    assert state.freeze_available is False

    reset = record_activity(state, date(2026, 8, 16))
    assert reset.current == 1


def test_pause_excuses_activity_until_inclusive() -> None:
    state = StreakState(current=3, last_active=date(2026, 8, 12))
    state = pause(state, date(2026, 8, 14))

    assert record_activity(state, date(2026, 8, 14)) == state
    resumed = record_activity(state, date(2026, 8, 15))
    assert resumed.current == 4
    assert resumed.last_active == date(2026, 8, 15)
