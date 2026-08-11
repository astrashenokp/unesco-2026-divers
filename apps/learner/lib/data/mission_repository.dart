import 'api_client.dart';
import 'demo_fixtures.dart';
import 'models.dart';

/// Screens depend on this, never on [EvidenceGymApiClient] or the demo
/// fixtures directly — keeps widgets identical whether the learner is in
/// demo mode or talking to a live backend (ROLE_1_FRONTEND_EXPERIENCE.md:
/// "no raw endpoint calls in widgets").
abstract class MissionRepository {
  Future<LearningPath> getLearningPath();
  Future<Mission> getMission(String missionId);
  Future<Attempt> startAttempt(String missionId, String missionVersion);
  Future<Attempt> submitPrediction(String attemptId, PredictionInput input);
  Future<EvidenceResult> useEvidenceAction(
    String attemptId,
    String missionId,
    String actionId,
  );
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion(
    String attemptId,
    ConclusionInput input,
  );
  Future<Hint> requestHint(String attemptId, String missionId);
  Future<Progress> getMyProgress();
}

/// Fully offline, deterministic — powers the demo-key path
/// (SCREEN_INVENTORY.md "Demo route"). No network calls at all.
class DemoMissionRepository implements MissionRepository {
  final _attemptState = <String, Attempt>{};
  final _usedActions = <String, Set<String>>{};
  var _receiptCounter = 0;
  var _earnedXp = 0;
  final _skillHits = <String, int>{};

  Future<void> _pause() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<LearningPath> getLearningPath() async {
    await _pause();
    return demoLearningPath;
  }

  @override
  Future<Mission> getMission(String missionId) async {
    await _pause();
    final mission = demoMissions[missionId];
    if (mission == null) {
      throw EvidenceGymApiException(
        Problem(
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
        Problem(
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
    final key = '$missionId:$actionId';
    return demoEvidenceResults[key] ??
        EvidenceResult(
          actionId: actionId,
          status: 'not_found',
          items: const [],
          limitations: const ['No demo fixture for this action.'],
        );
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
    for (final tag in demoMissions[missionId]?.skillTags ?? const <String>[]) {
      _skillHits[tag] = (_skillHits[tag] ?? 0) + usedCount;
    }

    return (
      receiptId: 'demo-receipt-$_receiptCounter',
      xpAwarded: xp,
      progress: _buildProgress(),
    );
  }

  @override
  Future<Hint> requestHint(String attemptId, String missionId) async {
    await _pause();
    final used = _usedActions[attemptId] ?? const <String>{};
    final mission = demoMissions[missionId];
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
    return demoHintFor(usedCount: used.length, nextActionId: nextAction?.id);
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
}

/// Talks to the real API via [EvidenceGymApiClient], generating a fresh
/// idempotency key per user-initiated mutation.
class LiveMissionRepository implements MissionRepository {
  LiveMissionRepository(this._client);
  final EvidenceGymApiClient _client;

  @override
  Future<LearningPath> getLearningPath() => _client.getLearningPath();

  @override
  Future<Mission> getMission(String missionId) => _client.getMission(missionId);

  @override
  Future<Attempt> startAttempt(String missionId, String missionVersion) =>
      _client.startAttempt(
        missionId: missionId,
        missionVersion: missionVersion,
        idempotencyKey: _client.newIdempotencyKey(),
      );

  @override
  Future<Attempt> submitPrediction(String attemptId, PredictionInput input) =>
      _client.submitPrediction(
        attemptId: attemptId,
        input: input,
        idempotencyKey: _client.newIdempotencyKey(),
      );

  @override
  Future<EvidenceResult> useEvidenceAction(
    String attemptId,
    String missionId,
    String actionId,
  ) =>
      _client.useEvidenceAction(
        attemptId: attemptId,
        actionId: actionId,
        idempotencyKey: _client.newIdempotencyKey(),
      );

  @override
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion(
    String attemptId,
    ConclusionInput input,
  ) =>
      _client.submitConclusion(
        attemptId: attemptId,
        input: input,
        idempotencyKey: _client.newIdempotencyKey(),
      );

  @override
  Future<Hint> requestHint(String attemptId, String missionId) => _client.requestHint(
        attemptId: attemptId,
        idempotencyKey: _client.newIdempotencyKey(),
      );

  @override
  Future<Progress> getMyProgress() => _client.getMyProgress();
}
