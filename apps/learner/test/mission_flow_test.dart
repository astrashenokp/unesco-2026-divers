import 'package:evidence_gym_learner/data/mission_repository.dart';
import 'package:evidence_gym_learner/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The mission flow at the repository level: predict, investigate,
/// conclude, receipt.
///
/// Driven through `MissionRepository` rather than the widget tree
/// deliberately. The widget path is covered by the smoke and
/// accessibility tests; what needs guarding here is the *state machine*
/// and the promises the product makes about it, which a UI test would
/// only exercise incidentally.
void main() {
  DemoMissionRepository repo() => DemoMissionRepository(localeCode: () => 'en');

  Future<Attempt> startFirst(DemoMissionRepository r) async {
    final path = await r.getLearningPath();
    final first = path.nodes.first;
    final mission = await r.getMission(first.missionId);
    return r.startAttempt(mission.id, mission.version);
  }

  test('an attempt walks ready -> predicted -> investigating', () async {
    final r = repo();
    final attempt = await startFirst(r);
    expect(attempt.state, 'ready');

    final predicted = await r.submitPrediction(
      attempt.id,
      PredictionInput(reaction: 'suspicious', confidence: 40, version: attempt.version),
    );
    expect(predicted.state, 'predicted');
    // The version must advance, or optimistic concurrency cannot detect
    // a stale write.
    expect(predicted.version, greaterThan(attempt.version));

    final evidence =
        await r.useEvidenceAction(attempt.id, 'viral-flood-photo', 'check_source', 2);
    // ADR-009: an evidence action advances the attempt and the response
    // reports the new version. Without this the conclusion would send a
    // version every evidence action has moved past.
    expect(evidence.attemptVersion, greaterThan(predicted.version));
  });

  test('the receipt cites exactly the evidence that was looked at', () async {
    final r = repo();
    final attempt = await startFirst(r);
    await r.submitPrediction(attempt.id,
        PredictionInput(reaction: 'investigate', confidence: 30, version: attempt.version));

    final a = await r.useEvidenceAction(attempt.id, 'viral-flood-photo', 'check_source', 2);
    final b = await r.useEvidenceAction(attempt.id, 'viral-flood-photo', 'check_date', 2);
    final expected = [...a.items, ...b.items].map((i) => i.evidenceId).toList();

    final result = await r.submitConclusion(
      attempt.id,
      const ConclusionInput(
        authenticity: AxisAssessment(label: 'authentic', confidence: 80),
        claimVeracity: AxisAssessment(label: 'contradicted', confidence: 70),
        contextIntegrity: AxisAssessment(label: 'misleading', confidence: 75),
        postConfidence: 80,
        shareDecision: 'do_not_share',
        version: 2,
      ),
    );

    final receipt = await r.getReceipt(result.receiptId);
    expect(receipt.evidenceRefs, expected,
        reason: 'a receipt must cite what was actually examined, nothing more');
  });

  test('a demo receipt is marked unsigned rather than given a fake hash', () async {
    // Inventing a convincing hash in a product about checking provenance
    // would be the exact failure it teaches against.
    final r = repo();
    final attempt = await startFirst(r);
    await r.submitPrediction(attempt.id,
        PredictionInput(reaction: 'trust', confidence: 60, version: attempt.version));
    await r.useEvidenceAction(attempt.id, 'viral-flood-photo', 'check_source', 2);

    final result = await r.submitConclusion(
      attempt.id,
      const ConclusionInput(
        authenticity: AxisAssessment(label: 'unknown', confidence: 20),
        claimVeracity: AxisAssessment(label: 'insufficient_evidence', confidence: 20),
        contextIntegrity: AxisAssessment(label: 'unknown', confidence: 20),
        postConfidence: 25,
        shareDecision: 'continue_investigating',
        version: 2,
      ),
    );
    final receipt = await r.getReceipt(result.receiptId);
    expect(receipt.hash, 'demo-unsigned');
  });

  test('XP rewards how much was investigated, not what was concluded', () async {
    // Two attempts reaching opposite conclusions, one with more checks.
    // The one that investigated more must earn more.
    Future<int> run(List<String> actions, String verdict) async {
      final r = repo();
      final attempt = await startFirst(r);
      await r.submitPrediction(attempt.id,
          PredictionInput(reaction: 'investigate', confidence: 50, version: attempt.version));
      for (final a in actions) {
        await r.useEvidenceAction(attempt.id, 'viral-flood-photo', a, 2);
      }
      final result = await r.submitConclusion(
        attempt.id,
        ConclusionInput(
          authenticity: AxisAssessment(label: verdict, confidence: 50),
          claimVeracity: const AxisAssessment(label: 'supported', confidence: 50),
          contextIntegrity: const AxisAssessment(label: 'accurate', confidence: 50),
          postConfidence: 50,
          shareDecision: 'do_not_share',
          version: 2,
        ),
      );
      return result.xpAwarded;
    }

    final thorough = await run(['check_source', 'check_date', 'reverse_search'], 'authentic');
    final hasty = await run(['check_source'], 'altered');
    expect(thorough, greaterThan(hasty));
  });

  test('the coach climbs its ladder and stops at five', () async {
    final r = repo();
    final attempt = await startFirst(r);
    final levels = <int>[];
    for (var i = 0; i < 7; i++) {
      final hint = await r.requestHint(attempt.id, 'viral-flood-photo');
      levels.add(hint.level);
    }
    expect(levels.take(5).toList(), [1, 2, 3, 4, 5]);
    // Asking beyond the top must not wrap around to an easier hint or
    // escalate into giving the answer.
    expect(levels.skip(5).every((l) => l == 5), isTrue);
  });

  test('every hint declares itself a fallback in demo mode', () async {
    // There is no model behind the demo coach. Claiming otherwise would
    // misrepresent the system to the learner.
    final r = repo();
    final attempt = await startFirst(r);
    final hint = await r.requestHint(attempt.id, 'viral-flood-photo');
    expect(hint.fallback, isTrue);
  });

  test('a missing evidence fixture returns not_found, not an error', () async {
    // "Not found in the queried sources" is a legitimate result the
    // learner must reason about, not a failure to hide.
    final r = repo();
    final attempt = await startFirst(r);
    final result =
        await r.useEvidenceAction(attempt.id, 'viral-flood-photo', 'no_such_action', 2);
    expect(result.status, 'not_found');
    expect(result.items, isEmpty);
  });
}
