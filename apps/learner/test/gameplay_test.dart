import 'package:evidence_gym_learner/data/gameplay.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same cases as `packages/gameplay/tests`, asserting the same
/// numbers.
///
/// These are deliberately duplicated rather than "adapted". The client
/// computes progression locally in demo mode, where there is no server
/// to ask, so two implementations of one rule now exist and the only
/// thing stopping them drifting is that both are pinned to the same
/// expected values. If a rule changes on the Python side and these fail,
/// that is the mechanism working.
void main() {
  DateTime day(int y, int m, int d) => DateTime.utc(y, m, d);

  group('process XP', () {
    // The reviewed ladder from content/p0-demo-pack.
    const rubric = [
      ProcessLevel(level: 0, xpGuidance: 1, criteria: 'instinct only'),
      ProcessLevel(level: 1, xpGuidance: 2, criteria: 'source checked'),
      ProcessLevel(level: 2, xpGuidance: 4, criteria: 'earlier source found'),
      ProcessLevel(level: 3, xpGuidance: 6, criteria: 'context corroborated'),
      ProcessLevel(level: 4, xpGuidance: 8, criteria: 'calibrated conclusion'),
    ];

    test('the level is the number of checks, capped at four', () {
      expect(processLevelFor(0), 0);
      expect(processLevelFor(3), 3);
      expect(processLevelFor(4), 4);
      expect(processLevelFor(9), 4,
          reason: 'running more checks than the rubric has rungs must not '
              'keep paying');
    });

    test('XP comes off the rubric, not from a formula', () {
      expect(xpFor(rubric, 0), 1);
      expect(xpFor(rubric, 2), 4);
      expect(xpFor(rubric, 4), 8);
      expect(xpFor(rubric, 12), 8, reason: 'the cap applies to XP too');
    });

    test('a rubric missing the rung pays nothing rather than guessing', () {
      // Awarding a plausible number would hide a content fault. Zero is
      // visibly wrong, which is the point.
      expect(xpFor(const [], 2), 0);
    });

    test('XP does not depend on being right', () {
      // There is no argument for the conclusion anywhere in the signature,
      // and that is the product's whole position on scoring. Guarded so
      // nobody adds one.
      expect(xpFor(rubric, 3), xpFor(rubric, 3));
    });
  });

  group('skills', () {
    test('four practices reach mastery and it stops there', () {
      var state = const SkillState(skill: 'provenance');
      for (var i = 0; i < 4; i++) {
        state = state.practise(day(2026, 8, 12));
      }
      expect(state.mastery, 1.0);
      state = state.practise(day(2026, 8, 12));
      expect(state.mastery, 1.0, reason: 'mastery must cap at 1.0');
      expect(state.practices, 5);
    });

    test('review intervals double from one day', () {
      var state = const SkillState(skill: 'provenance');
      final start = day(2026, 8, 12);
      state = state.practise(start);
      expect(state.dueAt, day(2026, 8, 13), reason: 'first review after 1 day');
      state = state.practise(start);
      expect(state.dueAt, day(2026, 8, 14), reason: 'then 2');
      state = state.practise(start);
      expect(state.dueAt, day(2026, 8, 16), reason: 'then 4');
      state = state.practise(start);
      expect(state.dueAt, day(2026, 8, 20), reason: 'then 8');
    });

    test('a skill is due on its date, not only after it', () {
      final state =
          const SkillState(skill: 'provenance').practise(day(2026, 8, 12));
      expect(state.isDue(day(2026, 8, 12)), isFalse);
      expect(state.isDue(day(2026, 8, 13)), isTrue);
      expect(state.isDue(day(2026, 8, 20)), isTrue);
    });
  });

  group('compassionate streak', () {
    test('it increments once per calendar day', () {
      var state = const StreakState().recordActivity(day(2026, 8, 12));
      state = state.recordActivity(day(2026, 8, 12));
      state = state.recordActivity(day(2026, 8, 13));
      expect(state.current, 2);
      expect(state.lastActive, day(2026, 8, 13));
    });

    test('one freeze covers one missed day, and only one', () {
      var state = StreakState(current: 3, lastActive: day(2026, 8, 12));
      state = state.recordActivity(day(2026, 8, 14));
      expect(state.current, 4, reason: 'the freeze should have carried it');
      expect(state.freezeAvailable, isFalse);

      final reset = state.recordActivity(day(2026, 8, 16));
      expect(reset.current, 1, reason: 'the freeze is spent, so this resets');
    });

    test('a pause excuses activity through its last day inclusive', () {
      var state = StreakState(current: 3, lastActive: day(2026, 8, 12));
      state = state.pause(day(2026, 8, 14));

      final during = state.recordActivity(day(2026, 8, 14));
      expect(during.current, 3, reason: 'a paused day changes nothing');

      final after = state.recordActivity(day(2026, 8, 15));
      expect(after.current, 4);
      expect(after.lastActive, day(2026, 8, 15));
    });

    test('a pause does not silently end the streak it was protecting', () {
      // The reason the feature exists: someone stops for a week because
      // something happened to them. Coming back must not read as failure.
      var state = StreakState(current: 12, lastActive: day(2026, 8, 1));
      state = state.pause(day(2026, 8, 20));
      final back = state.recordActivity(day(2026, 8, 21));
      expect(back.current, 13,
          reason: 'a paused absence must not reset the streak');
    });
  });
}
