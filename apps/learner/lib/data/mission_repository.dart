import 'api_client.dart';
import 'demo_fixtures.dart';
import 'models.dart';

/// Screens depend on this, never on [EvidenceGymApiClient] or the demo
/// fixtures directly — keeps widgets identical whether the learner is in
/// demo mode or talking to a live backend (ROLE_1_FRONTEND_EXPERIENCE.md:
/// "no raw endpoint calls in widgets").
abstract class MissionRepository {
  /// True when nothing leaves the device. The UI uses this to avoid
  /// promising things a demo cannot deliver — e.g. that a report will
  /// actually reach a human reviewer.
  bool get isDemo;

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
  DemoMissionRepository({required this.localeCode});

  final String Function() localeCode;

  @override
  bool get isDemo => true;

  final _attemptState = <String, Attempt>{};
  final _usedActions = <String, Set<String>>{};
  final _evidenceIds = <String, List<String>>{};
  final _receipts = <String, Receipt>{};
  var _receiptCounter = 0;
  final _completed = <String>{};
  var _earnedXp = 0;
  final _skillHits = <String, int>{};
  final _hintLevel = <String, int>{};

  Future<void> _pause() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<LearningPath> getLearningPath() async {
    await _pause();
    return demoLearningPathFor(localeCode(), completed: _completed.length);
  }

  @override
  Future<Mission> getMission(String missionId) async {
    await _pause();
    final mission = demoMissionsFor(localeCode())[missionId];
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
    _receiptCounter += 1;
    final usedCount = _usedActions[attemptId]?.length ?? 0;
    final xp = 1 + usedCount; // mirrors the process-XP rubric shape, demo-scale only
    _earnedXp += xp;

    // Credit the skills the mission actually exercises, so the demo
    // progress screen reflects what the learner just did.
    final missionId = _attemptState[attemptId]?.missionId;
    for (final tag in demoMissionsFor(localeCode())[missionId]?.skillTags ?? const <String>[]) {
      _skillHits[tag] = (_skillHits[tag] ?? 0) + usedCount;
    }

    if (missionId != null) _completed.add(missionId);

    final receiptId = 'demo-receipt-$_receiptCounter';
    _receipts[receiptId] = Receipt(
      id: receiptId,
      attemptId: attemptId,
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

  Progress _buildProgress() => Progress(
        totalXp: _earnedXp,
        skills: [
          for (final entry in _skillHits.entries)
            SkillProgress(
              skill: entry.key,
              // Four solid evidence checks on a skill reads as mastery in
              // the demo; the real curve is Role 4's to own.
              mastery: (entry.value / 4).clamp(0.0, 1.0),
            ),
        ],
      );

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
  LiveMissionRepository(this._client);
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
  Future<LearningPath> getLearningPath() => _client.getLearningPath();

  @override
  Future<Mission> getMission(String missionId) => _client.getMission(missionId);

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
