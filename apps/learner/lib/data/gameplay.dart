/// A Dart mirror of `packages/gameplay`, so the demo scores the way the
/// server does.
///
/// The demo pack used to invent its own arithmetic — `xp = 1 + checks`,
/// mastery from a hit counter, a skill going "stale" after two
/// completions. All three were placeholders written before Role 4
/// existed, and all three would have shown a judge one set of numbers in
/// the demo and a different set against a live server.
///
/// Every rule below is a transcription, not a reinvention. Where the
/// Python says something specific — level capped at 4, mastery 0.25 per
/// practice, review intervals doubling from one day, a freeze that
/// covers exactly one missed day — this says the same thing, and the
/// tests assert the same numbers as `packages/gameplay/tests`.
///
/// It exists because the demo runs with no server at all. If the client
/// ever gets these values from the API instead of computing them, this
/// file should shrink to nothing rather than drift.
library;

/// One rung of a mission's curated rubric.
///
/// Role 3 content, version-pinned with the mission. XP always comes from
/// here and is never hard-coded — that rule is theirs, and it is the
/// reason a rubric change does not need a code change.
class ProcessLevel {
  const ProcessLevel({
    required this.level,
    required this.xpGuidance,
    required this.criteria,
    this.skillTags = const [],
  });

  final int level;
  final int xpGuidance;

  /// What the learner did to reach this level, in the rubric's own
  /// words. Shown to them, because a score without its reason teaches
  /// nothing about how to score better.
  final String criteria;
  final List<String> skillTags;
}

/// The highest rung the rubric defines.
const kMaxProcessLevel = 4;

/// Mastery added by one practice of a skill.
const kMasteryPerPractice = 0.25;

/// Which rung the learner's evidence behaviour earned.
///
/// `min(usedEvidenceActions, 4)`. Deliberately not a function of whether
/// the conclusion was right: process is rewarded, and a wrong first
/// instinct is not punished when the learner investigates well. An
/// `insufficient_evidence` conclusion can earn top process XP if the
/// investigation was strong enough to justify it.
int processLevelFor(int usedEvidenceActions) {
  if (usedEvidenceActions < 0) {
    throw ArgumentError.value(
      usedEvidenceActions,
      'usedEvidenceActions',
      'must not be negative',
    );
  }
  return usedEvidenceActions < kMaxProcessLevel
      ? usedEvidenceActions
      : kMaxProcessLevel;
}

/// The XP a completed attempt earns, read off the rubric.
int xpFor(List<ProcessLevel> rubric, int usedEvidenceActions) {
  final level = processLevelFor(usedEvidenceActions);
  for (final rung in rubric) {
    if (rung.level == level) return rung.xpGuidance;
  }
  // A rubric missing the rung the learner reached is a content fault,
  // and awarding a made-up number would hide it. Zero is visibly wrong.
  return 0;
}

/// When a skill practised for the [practices]th time falls due again.
///
/// Doubling intervals: 1, 2, 4, 8 days. Recall is scheduled explicitly
/// rather than being inferred from a streak — the streak is a profile
/// signal and must never become the scheduler.
DateTime nextDueAt(DateTime at, int practices) =>
    at.add(Duration(days: 1 << (practices - 1)));

/// One skill's mastery and next review.
class SkillState {
  const SkillState({
    required this.skill,
    this.mastery = 0,
    this.practices = 0,
    this.dueAt,
  });

  final String skill;
  final double mastery;
  final int practices;
  final DateTime? dueAt;

  /// Records one practice, capping mastery at 1.0.
  SkillState practise(DateTime at) {
    final next = practices + 1;
    final raised = mastery + kMasteryPerPractice;
    return SkillState(
      skill: skill,
      mastery: raised > 1.0 ? 1.0 : raised,
      practices: next,
      dueAt: nextDueAt(at, next),
    );
  }

  bool isDue(DateTime now) => dueAt != null && !now.isBefore(dueAt!);
}

/// The compassionate streak.
///
/// Optional, non-punitive, pauseable, and never used to gate a reward.
/// The design choice worth preserving is the second one: a gap of two
/// days is forgiven once, because the day someone misses is usually the
/// day something happened to them, and a product about crisis
/// information should not punish people for living through one.
class StreakState {
  const StreakState({
    this.current = 0,
    this.lastActive,
    this.pausedUntil,
    this.freezeAvailable = true,
  });

  final int current;
  final DateTime? lastActive;

  /// Activity through this date, inclusive, is excused entirely.
  final DateTime? pausedUntil;

  /// One freeze covers exactly one missed day, once.
  final bool freezeAvailable;

  bool isPaused(DateTime today) =>
      pausedUntil != null && !_dayOf(today).isAfter(_dayOf(pausedUntil!));

  StreakState pause(DateTime until) => StreakState(
        current: current,
        lastActive: lastActive,
        pausedUntil: until,
        freezeAvailable: freezeAvailable,
      );

  StreakState resume() => StreakState(
        current: current,
        lastActive: lastActive,
        freezeAvailable: freezeAvailable,
      );

  /// Records an active day. Calendar dates, not timestamps — an hour
  /// either side of midnight must not change the answer.
  StreakState recordActivity(DateTime today) {
    final day = _dayOf(today);
    if (isPaused(day)) return this;

    if (lastActive == null) {
      return StreakState(
        current: 1,
        lastActive: day,
        pausedUntil: pausedUntil,
        freezeAvailable: freezeAvailable,
      );
    }

    var effectiveLast = _dayOf(lastActive!);
    if (pausedUntil != null && _dayOf(pausedUntil!).isAfter(effectiveLast)) {
      effectiveLast = _dayOf(pausedUntil!);
    }

    final gap = day.difference(effectiveLast).inDays;
    if (gap == 0) return this;
    if (gap == 1) {
      return StreakState(
        current: current + 1,
        lastActive: day,
        pausedUntil: pausedUntil,
        freezeAvailable: freezeAvailable,
      );
    }
    if (gap == 2 && freezeAvailable) {
      return StreakState(
        current: current + 1,
        lastActive: day,
        pausedUntil: pausedUntil,
        freezeAvailable: false,
      );
    }
    return StreakState(
      current: 1,
      lastActive: day,
      pausedUntil: pausedUntil,
      freezeAvailable: freezeAvailable,
    );
  }

  static DateTime _dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
