import 'dart:async';
import 'api_client.dart';
import 'audience.dart';
import 'demo_fixtures.dart';
import 'gameplay.dart';
import 'models.dart';
import 'mission_cache.dart';
import '../features/leaderboard/leaderboard_screen.dart';

/// Screens depend on this, never on [EvidenceGymApiClient] or the demo
/// fixtures directly — keeps widgets identical whether the learner is in
/// demo mode or talking to a live backend (ROLE_1_FRONTEND_EXPERIENCE.md:
/// "no raw endpoint calls in widgets").
abstract class MissionRepository {
  /// True when nothing leaves the device. The UI uses this to avoid
  /// promising things a demo cannot deliver — e.g. that a report will
  /// actually reach a human reviewer.
  bool get isDemo;

  /// The learner's compassionate streak.
  ///
  /// Not on the wire: `Progress` in the contract carries `totalXp` and
  /// `skills` and nothing about streaks, so a live client cannot show
  /// one yet. `packages/gameplay` computes it server-side, which makes
  /// this a contract gap rather than a missing feature — the rules
  /// exist, the field to carry them does not.
  StreakState get streak;

  /// How many missions the current audience mode left out of the last
  /// path fetched. Zero in the adult mode.
  ///
  /// Reported rather than silently applied, because a filter the learner
  /// cannot see turns a hidden mission into a missing one — and "where
  /// did it go" is a worse question to leave someone with than "why is
  /// it hidden".
  int get hiddenByAudience;

  /// The board, ranked by process XP.
  ///
  /// Returns an empty list until the learner opts in, because a board
  /// that shows other people before you have agreed to be shown is not
  /// an opt-in. There is no `/leaderboard` in the contract yet, so this
  /// is demo-only — the live repository returns nothing rather than
  /// inventing rivals, which would be the same fabrication the invented
  /// streak was.
  Future<List<BoardEntry>> getLeaderboard();

  /// Whether this learner has joined, and the handle they chose.
  bool get boardHandleSet;
  void joinBoard(String handle);
  void leaveBoard();

  /// Excuses activity through [until], inclusive.
  ///
  /// Deliberately part of the repository rather than a UI-local flag: a
  /// pause is a fact about the learner, and a pause that vanishes when
  /// the screen rebuilds would be worse than no pause at all.
  void pauseStreak(DateTime until);
  void resumeStreak();

  Future<LearningPath> getLearningPath();
  Future<Mission> getMission(String missionId);
  Future<Attempt> startAttempt(String missionId, String missionVersion);
  Future<Attempt> submitPrediction(String attemptId, PredictionInput input);
  /// [version] is the attempt version the caller believes is current.
  /// A stale value returns 409 (ADR-009).
  Future<EvidenceResult> useEvidenceAction(
    String attemptId,
    String missionId,
    String actionId,
    int version,
  );
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion(
    String attemptId,
    ConclusionInput input,
  );
  Future<Hint> requestHint(String attemptId, String missionId);
  Future<Progress> getMyProgress();
  Future<Receipt> getReceipt(String receiptId);

  /// Receipts this learner has earned, newest first.
  ///
  /// The contract has no list endpoint yet, so the live implementation
  /// returns empty rather than inventing one. Role 2 would need to add
  /// GET /v1/receipts before this can show real history.
  Future<List<Receipt>> listReceipts();
  Future<void> reportContent({
    required String missionId,
    required String reason,
    String? detail,
  });
}

/// Fully offline, deterministic — powers the demo-key path
/// (SCREEN_INVENTORY.md "Demo route"). No network calls at all.
class DemoMissionRepository implements MissionRepository {
  /// Reads the current language at call time rather than at construction,
  /// so switching language in settings re-localizes the demo content
  /// without rebuilding the repository.
  DemoMissionRepository({required this.localeCode, required this.audience});

  final String Function() localeCode;

  /// Read at call time like [localeCode], so switching audience in
  /// settings re-filters the path without rebuilding the repository.
  final AudienceMode Function() audience;

  @override
  bool get isDemo => true;

  final _attemptState = <String, Attempt>{};
  final _usedActions = <String, Set<String>>{};
  final _evidenceIds = <String, List<String>>{};
  final _receipts = <String, Receipt>{};
  var _receiptCounter = 0;
  final _completed = <String>{};
  var _earnedXp = 0;
  /// Skill mastery and review schedule, run through the real rules.
  ///
  /// This was a hit counter with a homemade "stale after two
  /// completions" heuristic, written before Role 4 existed. It now uses
  /// `gameplay.dart`, which transcribes `packages/gameplay`: 0.25
  /// mastery per practice, review intervals doubling from one day.
  final _skills = <String, SkillState>{};

  /// The compassionate streak, same rules as the server package.
  var _streak = const StreakState();
  final _hintLevel = <String, int>{};

  Future<void> _pause() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<LearningPath> getLearningPath() async {
    await _pause();
    final path = demoLearningPathFor(localeCode(), completed: _completed.length);
    final missionsAll = demoMissionsFor(localeCode());

    // Filtering happens here rather than in the widget tree on purpose.
    // A mission a younger learner should not meet must not be in the
    // path they are handed at all — hiding a node while leaving it
    // reachable by any other route is the kind of gap that only shows up
    // once it has already gone wrong.
    final mode = audience();
    final visible = [
      for (final node in path.nodes)
        if (suitableFor(mode, missionsAll[node.missionId]?.contentWarnings))
          node,
    ];
    _hiddenByAudience = path.nodes.length - visible.length;

    final due = _dueSkills;
    if (due.isEmpty) {
      return LearningPath(
        version: path.version,
        locale: path.locale,
        nodes: visible,
      );
    }

    // Joining due skills to nodes is only possible here because the demo
    // holds the fixtures. See LearningPathNode.boosterDue for why the
    // live repository cannot do the same.
    final missions = missionsAll;
    return LearningPath(
      version: path.version,
      locale: path.locale,
      nodes: [
        for (final node in visible)
          LearningPathNode(
            missionId: node.missionId,
            title: node.title,
            state: node.state,
            boosterDue: node.state == 'completed' &&
                (missions[node.missionId]?.skillTags ?? const <String>[])
                    .any(due.contains),
          ),
      ],
    );
  }

  @override
  Future<Mission> getMission(String missionId) async {
    await _pause();
    final mission = demoMissionsFor(localeCode())[missionId];
    // The same rule at the second door. A path that omits a mission is
    // not a guarantee nothing else opens it — a saved link, a resumed
    // session, a future deep link — so the check that matters is here
    // too, and a mission outside this audience reads as absent rather
    // than as forbidden.
    if (mission != null && !suitableFor(audience(), mission.contentWarnings)) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'Mission not in this pack',
          status: 404,
          code: 'demo_mission_not_found',
          traceId: 'demo',
        ),
      );
    }
    if (mission == null) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'Mission not found in demo pack',
          status: 404,
          code: 'demo_mission_not_found',
          traceId: 'demo',
        ),
      );
    }
    return mission;
  }

  @override
  Future<Attempt> startAttempt(String missionId, String missionVersion) async {
    await _pause();
    final id = 'demo-attempt-$missionId';
    final attempt = Attempt(
      id: id,
      missionId: missionId,
      missionVersion: missionVersion,
      state: 'ready',
      version: 1,
    );
    _attemptState[id] = attempt;
    _usedActions[id] = {};
    return attempt;
  }

  @override
  Future<Attempt> submitPrediction(String attemptId, PredictionInput input) async {
    await _pause();
    final current = _attemptState[attemptId];
    if (current == null) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'Attempt not found',
          status: 404,
          code: 'demo_attempt_not_found',
          traceId: 'demo',
        ),
      );
    }
    final updated = Attempt(
      id: current.id,
      missionId: current.missionId,
      missionVersion: current.missionVersion,
      state: 'predicted',
      version: current.version + 1,
    );
    _attemptState[attemptId] = updated;
    return updated;
  }

  @override
  Future<EvidenceResult> useEvidenceAction(
    String attemptId,
    String missionId,
    String actionId,
    int version,
  ) async {
    await _pause();
    final current = _attemptState[attemptId];
    if (current != null && current.state == 'predicted') {
      _attemptState[attemptId] = Attempt(
        id: current.id,
        missionId: current.missionId,
        missionVersion: current.missionVersion,
        state: 'investigating',
        version: current.version,
      );
    }
    _usedActions.putIfAbsent(attemptId, () => {}).add(actionId);

    // An evidence action advances the attempt, so the version moves and
    // the response reports it — the demo has to model the same
    // concurrency contract as the server, or the client's handling of it
    // is never exercised before a live backend appears (ADR-009).
    final after = _attemptState[attemptId];
    final nextVersion = (after?.version ?? 1) + 1;
    if (after != null) {
      _attemptState[attemptId] = Attempt(
        id: after.id,
        missionId: after.missionId,
        missionVersion: after.missionVersion,
        state: 'investigating',
        version: nextVersion,
      );
    }

    final key = '$missionId:$actionId';
    final fixture = demoEvidenceResultsFor(localeCode())[key];
    final result = fixture == null
        ? EvidenceResult(
            actionId: actionId,
            status: 'not_found',
            items: const [],
            limitations: const ['No demo fixture for this action.'],
            attemptVersion: nextVersion,
          )
        : EvidenceResult(
            actionId: fixture.actionId,
            status: fixture.status,
            items: fixture.items,
            limitations: fixture.limitations,
            attemptVersion: nextVersion,
          );
    // Remember what was actually looked at, so the receipt can cite it.
    _evidenceIds
        .putIfAbsent(attemptId, () => [])
        .addAll(result.items.map((i) => i.evidenceId));
    return result;
  }

  @override
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion(
    String attemptId,
    ConclusionInput input,
  ) async {
    await _pause();
    final usedCount = _usedActions[attemptId]?.length ?? 0;
    final missionId = _attemptState[attemptId]?.missionId;
    final mission = demoMissionsFor(localeCode())[missionId];
    if (!(mission?.testsCriticalIgnoring ?? false) &&
        usedCount < (mission?.minimumCompletionEvidence ?? 1)) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'More evidence needed',
          status: 409,
          code: 'minimum_evidence_not_met',
          traceId: 'demo',
        ),
      );
    }
    _receiptCounter += 1;

    // XP comes off the mission's curated rubric at the process level the
    // evidence behaviour earned. It used to be `1 + usedCount`, a
    // homemade formula that was unbounded and paid differently from the
    // reviewed ladder — a demo showing numbers the product does not
    // award.
    final level = processLevelFor(usedCount);
    final xp = xpFor(mission?.rubric ?? const [], usedCount);
    _earnedXp += xp;
    _lastProcessLevel = level;

    // One practice per skill the mission exercises, through the real
    // mastery and review-interval rules.
    final now = DateTime.now();
    for (final tag in mission?.skillTags ?? const <String>[]) {
      _skills[tag] = (_skills[tag] ?? SkillState(skill: tag)).practise(now);
    }

    // The streak is a profile signal, recorded on completion and never
    // used to gate any of the above.
    _streak = _streak.recordActivity(now);

    if (missionId != null) _completed.add(missionId);

    final receiptId = 'demo-receipt-$_receiptCounter';
    _receipts[receiptId] = Receipt(
      id: receiptId,
      attemptId: attemptId,
      missionId: missionId,
      missionVersion: _attemptState[attemptId]?.missionVersion ?? '1.0.0',
      assessments: [input.authenticity, input.claimVeracity, input.contextIntegrity],
      evidenceRefs: List<String>.from(_evidenceIds[attemptId] ?? const []),
      createdAt: DateTime.now(),
      // Demo receipts are not signed. The real hash is produced
      // server-side; inventing a convincing-looking one here would be
      // exactly the fake-provenance move this product argues against.
      hash: 'demo-unsigned',
      disclaimer: 'demo_receipt_disclaimer',
    );

    return (
      receiptId: receiptId,
      xpAwarded: xp,
      progress: _buildProgress(),
    );
  }

  @override
  Future<Hint> requestHint(String attemptId, String missionId) async {
    await _pause();
    final used = _usedActions[attemptId] ?? const <String>{};
    final mission = demoMissionsFor(localeCode())[missionId];
    // Suggest the first action the learner hasn't tried yet, and phrase
    // it as a question — the demo coach must model the same Socratic
    // behaviour as the real one, never hand over a verdict.
    // Plain loop rather than `firstOrNull`, which lives in
    // package:collection and is not a declared dependency here.
    EvidenceActionSpec? nextAction;
    for (final action in mission?.evidenceActions ?? const <EvidenceActionSpec>[]) {
      if (!used.contains(action.id)) {
        nextAction = action;
        break;
      }
    }
    final level = (_hintLevel[attemptId] ?? 0) + 1;
    _hintLevel[attemptId] = level;
    return demoHintFor(
      usedCount: used.length,
      level: level,
      nextActionId: nextAction?.id,
    );
  }

  /// Skills whose scheduled review has come round.
  Set<String> get _dueSkills {
    final now = DateTime.now();
    return {
      for (final entry in _skills.entries)
        if (entry.value.isDue(now)) entry.key,
    };
  }

  Progress _buildProgress() => Progress(
        totalXp: _earnedXp,
        skills: [
          for (final entry in _skills.entries)
            SkillProgress(
              skill: entry.key,
              mastery: entry.value.mastery,
              dueAt: entry.value.dueAt,
            ),
        ],
      );

  /// The process level the last completed attempt reached.
  ///
  /// Not on `Progress` in the contract, and it belongs on the receipt
  /// rather than in progress anyway — it describes one attempt, not a
  /// running total.
  int? _lastProcessLevel;
  int? get lastProcessLevel => _lastProcessLevel;

  /// The learner's streak, for the profile. Never gates anything.
  @override
  StreakState get streak => _streak;

  var _hiddenByAudience = 0;

  @override
  int get hiddenByAudience => _hiddenByAudience;

  String? _boardHandle;

  @override
  bool get boardHandleSet => _boardHandle != null;

  @override
  void joinBoard(String handle) => _boardHandle = handle;

  @override
  void leaveBoard() => _boardHandle = null;

  /// A fixed set of rivals, clearly fictional, plus the learner.
  ///
  /// Named as obviously invented rather than as plausible people: a demo
  /// board of realistic names reads as real users to anyone glancing at
  /// it, and this product cannot be the one that fakes an active
  /// community. Their XP is fixed so the learner's own position moves
  /// only because of what the learner did.
  @override
  Future<List<BoardEntry>> getLeaderboard() async {
    await _pause();
    if (_boardHandle == null) return const [];
    final mine = BoardEntry(
      handle: _boardHandle!,
      xp: _earnedXp,
      missions: _completed.length,
      isYou: true,
    );
    final board = <BoardEntry>[
      const BoardEntry(handle: 'Sample learner A', xp: 34, missions: 5),
      const BoardEntry(handle: 'Sample learner B', xp: 22, missions: 4),
      const BoardEntry(handle: 'Sample learner C', xp: 12, missions: 2),
      const BoardEntry(handle: 'Sample learner D', xp: 4, missions: 1),
      mine,
    ]..sort((a, b) => b.xp.compareTo(a.xp));
    return board;
  }

  @override
  void pauseStreak(DateTime until) => _streak = _streak.pause(until);

  @override
  void resumeStreak() => _streak = _streak.resume();

  @override
  Future<Progress> getMyProgress() async {
    await _pause();
    return _buildProgress();
  }

  @override
  Future<List<Receipt>> listReceipts() async {
    await _pause();
    return _receipts.values.toList().reversed.toList();
  }

  @override
  Future<Receipt> getReceipt(String receiptId) async {
    await _pause();
    final receipt = _receipts[receiptId];
    if (receipt == null) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'Receipt not found',
          status: 404,
          code: 'demo_receipt_not_found',
          traceId: 'demo',
        ),
      );
    }
    return receipt;
  }

  @override
  Future<void> reportContent({
    required String missionId,
    required String reason,
    String? detail,
  }) async {
    // Demo mode has no moderation queue. The report is accepted and
    // dropped, exactly as the dialog promises — it never claims a human
    // has seen it, only that one will once this is connected.
    await _pause();
  }
}

/// Talks to the real API via [EvidenceGymApiClient], generating a fresh
/// idempotency key per user-initiated mutation.
class LiveMissionRepository implements MissionRepository {
  /// Empty until the contract carries a streak. Returning a plausible
  /// value here would put an invented number on the profile, which is
  /// the mistake the path header already had to have removed from it.
  @override
  StreakState get streak => const StreakState();

  /// Nothing is filtered here yet: `Mission.contentWarnings` has only
  /// just entered the contract and no server sends it, so the live path
  /// is unfiltered and there is nothing hidden to report.
  @override
  int get hiddenByAudience => 0;

  /// Empty until the contract carries a board. Inventing rivals to fill
  /// the screen would be the same fabrication as the invented streak.
  @override
  Future<List<BoardEntry>> getLeaderboard() async => const [];

  @override
  bool get boardHandleSet => false;

  @override
  void joinBoard(String handle) {}

  @override
  void leaveBoard() {}

  @override
  void pauseStreak(DateTime until) {}

  @override
  void resumeStreak() {}

  LiveMissionRepository(
    this._client, {
    MissionCache? cache,
    bool prefetch = true,
    MissionRepository? fallback,
  })  : _cache = cache,
        _prefetch = prefetch,
        _fallback = fallback {
    // Published content is written to the cache as it arrives, so the
    // cache fills from ordinary use rather than from a separate download
    // the learner did not ask for.
    _client.onCacheable = (kind, id, json) {
      if (!_prefetch) return;
      if (kind == 'path') {
        _cache?.writePath(json);
      } else {
        _cache?.writeMission(id, json);
      }
    };
  }

  final MissionCache? _cache;
  bool _prefetch;

  /// The reviewed content that ships with the app, used when the server
  /// cannot be reached at all.
  ///
  /// Not a demo mode and no longer labelled as one. It is the same
  /// missions, the same rubric and the same scoring, read from the pack
  /// bundled in the build rather than fetched — which is a real
  /// capability of the product, not a rehearsal of it. Calling it a demo
  /// made the offline path look like something you would switch off
  /// before showing anyone.
  ///
  /// Only reached on transport failure. Everything the server *can*
  /// answer, it answers.
  final MissionRepository? _fallback;

  /// True while the app is reading the bundled pack because the server
  /// is unreachable. Screens use it to say so plainly.
  var _servingOffline = false;
  bool get isServingOffline => _servingOffline;

  /// Turning the setting off stops caching *and* drops what is held.
  /// A switch that only stops adding has not really been turned off.
  Future<void> setPrefetch(bool value) async {
    _prefetch = value;
    if (!value) await _cache?.clear();
  }

  int get cachedMissionCount => _cache?.storedCount ?? 0;
  final EvidenceGymApiClient _client;

  /// One idempotency key per *logical action*, not per call.
  ///
  /// Generating a fresh key on every request defeats the mechanism
  /// entirely: a timed-out `POST /attempts` retried would create a
  /// second attempt instead of returning the first, and a timed-out
  /// conclusion retried could not resume from the server's persisted
  /// `reflected` checkpoint — which is the whole point of ADR-008
  /// decision 5. The learner would lose the receipt and XP they earned.
  ///
  /// A key is minted once per action and reused until that action
  /// succeeds, so every retry carries the same key.
  final _keys = <String, String>{};

  String _key(String action) =>
      _keys.putIfAbsent(action, _client.newIdempotencyKey);

  /// Called after a success so the next deliberate invocation of the same
  /// action is a new operation rather than a replay of the old one.
  void _clearKey(String action) => _keys.remove(action);

  @override
  bool get isDemo => false;

  @override
  Future<LearningPath> getLearningPath() async {
    try {
      final path = await _client.getLearningPath();
      // Warm the next few missions in the background. Failures are
      // ignored on purpose: a prefetch that surfaces an error would
      // interrupt a learner over content they had not asked for yet.
      if (_prefetch) unawaited(_warm(path));
      return path;
    } on EvidenceGymApiException catch (e) {
      if (!e.isOffline) rethrow;
      final cached = _cache?.readPath();
      if (cached != null) {
        _servingOffline = true;
        return cached;
      }
      final fallback = _fallback;
      if (fallback != null) {
        _servingOffline = true;
        return fallback.getLearningPath();
      }
      rethrow;
    }
  }

  /// Fetches the next few missions so they are there if the connection
  /// is not.
  Future<void> _warm(LearningPath path) async {
    final ahead = path.nodes
        .where((n) => n.state != 'completed')
        .take(MissionCache.lookahead);
    for (final node in ahead) {
      if (_cache?.readMission(node.missionId) != null) continue;
      try {
        await _client.getMission(node.missionId);
      } catch (_) {
        // Nothing to report and nothing to retry: the learner has not
        // asked for this mission yet.
        return;
      }
    }
  }

  @override
  Future<Mission> getMission(String missionId) async {
    try {
      return await _client.getMission(missionId);
    } on EvidenceGymApiException catch (e) {
      // Only a transport failure falls back. A 404 means this mission is
      // genuinely gone and showing a cached copy of withdrawn content
      // would be worse than an error — content can be withdrawn for
      // safety reasons, and ADR-005 makes corrections a new version.
      if (!e.isOffline) rethrow;
      final cached = _cache?.readMission(missionId);
      if (cached != null) {
        _servingOffline = true;
        return cached;
      }
      final fallback = _fallback;
      if (fallback != null) {
        _servingOffline = true;
        return fallback.getMission(missionId);
      }
      rethrow;
    }
  }

  @override
  Future<Attempt> startAttempt(String missionId, String missionVersion) =>
      // Deliberately never cleared: the contract calls this "start/resume",
      // so reopening the same mission version must return the attempt
      // already in progress rather than abandoning it for a fresh one.
      _client.startAttempt(
        missionId: missionId,
        missionVersion: missionVersion,
        idempotencyKey: _key('start:$missionId:$missionVersion'),
      );

  @override
  Future<Attempt> submitPrediction(String attemptId, PredictionInput input) async {
    const scope = 'prediction';
    final action = '$scope:$attemptId';
    final result = await _client.submitPrediction(
      attemptId: attemptId,
      input: input,
      idempotencyKey: _key(action),
    );
    _clearKey(action);
    return result;
  }

  @override
  Future<EvidenceResult> useEvidenceAction(
    String attemptId,
    String missionId,
    String actionId,
    int version,
  ) async {
    // Keyed by the action itself: running the same check twice is the
    // same operation and should not be billed or logged twice.
    final action = 'evidence:$attemptId:$actionId';
    final result = await _client.useEvidenceAction(
      attemptId: attemptId,
      actionId: actionId,
      version: version,
      idempotencyKey: _key(action),
    );
    _clearKey(action);
    return result;
  }

  @override
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion(
    String attemptId,
    ConclusionInput input,
  ) =>
      // Never cleared. An attempt concludes exactly once, so every retry
      // of this call — including one after a timeout that the server
      // actually processed — must replay the original and return the
      // same receipt.
      _client.submitConclusion(
        attemptId: attemptId,
        input: input,
        idempotencyKey: _key('conclusion:$attemptId'),
      );

  @override
  Future<Hint> requestHint(String attemptId, String missionId) async {
    // Cleared on success, so a retry of one press replays that hint while
    // a deliberate second press asks for the next rung.
    final action = 'hint:$attemptId:${_hintAsks[attemptId] ?? 0}';
    final hint = await _client.requestHint(
      attemptId: attemptId,
      idempotencyKey: _key(action),
    );
    _hintAsks[attemptId] = (_hintAsks[attemptId] ?? 0) + 1;
    _clearKey(action);
    return hint;
  }

  final _hintAsks = <String, int>{};

  @override
  Future<Progress> getMyProgress() => _client.getMyProgress();

  @override
  Future<Receipt> getReceipt(String receiptId) => _client.getReceipt(receiptId);

  @override
  // No list endpoint exists in contracts/openapi.yaml. Returning empty is
  // honest; fabricating a list here would be worse than showing none.
  Future<List<Receipt>> listReceipts() async => const [];

  @override
  Future<void> reportContent({
    required String missionId,
    required String reason,
    String? detail,
  }) =>
      // Keyed by content, so a retry after a timeout does not file the
      // same report twice into a human moderation queue.
      _client.reportContent(
        missionId: missionId,
        reason: reason,
        detail: detail,
        idempotencyKey: _key('report:$missionId:$reason:${detail ?? ""}'),
      );
}
