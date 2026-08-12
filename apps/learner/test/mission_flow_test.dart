import 'package:evidence_gym_learner/data/api_client.dart';
import 'package:evidence_gym_learner/data/arenas.dart';
import 'package:evidence_gym_learner/data/audience.dart';
import 'package:evidence_gym_learner/data/demo_fixtures.dart';
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
  DemoMissionRepository repo({AudienceMode audience = AudienceMode.adult}) =>
      DemoMissionRepository(
        localeCode: () => 'en',
        audience: () => audience,
      );

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

  test('the coach climbs its ladder and stops at four', () async {
    final r = repo();
    final attempt = await startFirst(r);
    final levels = <int>[];
    for (var i = 0; i < 7; i++) {
      final hint = await r.requestHint(attempt.id, 'viral-flood-photo');
      levels.add(hint.level);
    }
    expect(levels.take(4).toList(), [1, 2, 3, 4]);
    // Asking beyond the top must not wrap around to an easier hint or
    // escalate into giving the answer.
    expect(levels.skip(4).every((l) => l == 4), isTrue);
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

  test('the two 409s are told apart by code, not by status', () async {
    // Conflating them offers to restart the mission of a learner who has
    // simply not checked enough evidence yet, discarding work they had
    // not finished doing.
    final r = repo();
    final attempt = await startFirst(r);
    await r.submitPrediction(
      attempt.id,
      PredictionInput(reaction: 'trust', confidence: 80, version: attempt.version),
    );

    // Concluding with no evidence behind it.
    Object? thrown;
    try {
      await r.submitConclusion(
        attempt.id,
        const ConclusionInput(
          authenticity: AxisAssessment(label: 'authentic', confidence: 60),
          claimVeracity: AxisAssessment(label: 'supported', confidence: 60),
          contextIntegrity: AxisAssessment(label: 'accurate', confidence: 60),
          postConfidence: 60,
          shareDecision: 'do_not_share',
          version: 2,
        ),
      );
    } catch (e) {
      thrown = e;
    }

    final error = thrown as EvidenceGymApiException;
    expect(error.problem.status, 409);
    expect(error.needsMoreEvidence, isTrue,
        reason: 'a conclusion without evidence is a step not yet taken');
    expect(error.isStaleVersion, isFalse,
        reason: 'restarting here would throw away work the learner had not '
            'finished doing');
  });

  test('a stale version reads as stale, whichever casing the code uses', () {
    // The server writes kebab-case and the demo pack writes snake_case.
    // Matching one spelling silently misses the other, and a missed
    // stale version leaves the learner stuck on a screen where every
    // button fails identically.
    for (final code in [
      'stale-attempt-version',
      'stale_attempt_version',
      'attempt-conflict',
    ]) {
      final error = EvidenceGymApiException(
        Problem(
          type: 'about:blank',
          title: 'Conflict',
          status: 409,
          code: code,
          traceId: 't',
        ),
      );
      expect(error.isStaleVersion, isTrue, reason: '$code was not recognised');
      expect(error.needsMoreEvidence, isFalse);
    }
  });

  group('audience modes', () {
    test('the younger mode hides the distressing missions and only those',
        () async {
      final adult = await repo().getLearningPath();
      final child =
          await repo(audience: AudienceMode.child).getLearningPath();

      expect(child.nodes.length, lessThan(adult.nodes.length),
          reason: 'nothing was filtered, so the mode does nothing');
      expect(child.nodes, isNotEmpty,
          reason: 'a younger learner with an empty path has no product');

      // Named explicitly rather than counted, so a change of intent has
      // to be a change of test rather than a number quietly moving.
      final hidden = adult.nodes.map((n) => n.missionId).toSet()
        ..removeAll(child.nodes.map((n) => n.missionId));
      final missions = demoMissionsFor('en');
      for (final id in hidden) {
        expect(missions[id]!.contentWarnings, isNotEmpty,
            reason: '$id was hidden but declares nothing to warn about');
      }
      for (final node in child.nodes) {
        expect(
          suitableFor(AudienceMode.child, missions[node.missionId]!.contentWarnings),
          isTrue,
          reason: '${node.missionId} reached the younger path unsuitable',
        );
      }
    });

    test('a hidden mission cannot be opened directly either', () async {
      final r = repo(audience: AudienceMode.child);
      final adultPath = await repo().getLearningPath();
      final childIds =
          (await r.getLearningPath()).nodes.map((n) => n.missionId).toSet();
      final hidden = adultPath.nodes
          .map((n) => n.missionId)
          .firstWhere((id) => !childIds.contains(id));

      // A path that omits a mission is not a guarantee nothing else
      // opens it — a saved link, a resumed session, a deep link later.
      await expectLater(
        r.getMission(hidden),
        throwsA(isA<EvidenceGymApiException>()
            .having((e) => e.problem.status, 'status', 404)),
      );
    });

    test('an unrecognised content warning fails closed', () {
      // The rule that matters most. A blocklist would admit every tag
      // nobody thought of, so the first warning from a new pack would
      // reach a child precisely because it was unfamiliar.
      expect(suitableFor(AudienceMode.child, ['something-nobody-added-yet']),
          isFalse,
          reason: 'an unknown warning was treated as safe for children');
      expect(suitableFor(AudienceMode.child, []), isTrue,
          reason: 'declaring nothing to warn about is not the same as '
              'carrying an unknown warning');
      expect(suitableFor(AudienceMode.adult, ['something-nobody-added-yet']),
          isTrue,
          reason: 'the adult mode filters nothing');
    });

    test('both modes score identically', () async {
      // The younger mode must not become the easy mode. Same rubric,
      // same XP, same skills — only the case material differs.
      // The *same* mission in both modes. An earlier version of this
      // took each mode's first mission, which are different missions
      // with different numbers of checks — it compared two unlike
      // things and failed while the rubric was in fact identical.
      final shared = (await repo(audience: AudienceMode.child)
              .getLearningPath())
          .nodes
          .first
          .missionId;

      Future<int> xpFor(AudienceMode mode) async {
        final r = repo(audience: mode);
        final mission = await r.getMission(shared);
        final attempt = await r.startAttempt(mission.id, mission.version);
        final predicted = await r.submitPrediction(
          attempt.id,
          PredictionInput(
              reaction: 'investigate', confidence: 50, version: attempt.version),
        );
        var version = predicted.version;
        for (final action in mission.evidenceActions) {
          final result = await r.useEvidenceAction(
              attempt.id, mission.id, action.id, version);
          version = result.attemptVersion;
        }
        final done = await r.submitConclusion(
          attempt.id,
          ConclusionInput(
            authenticity: const AxisAssessment(label: 'authentic', confidence: 60),
            claimVeracity:
                const AxisAssessment(label: 'insufficient_evidence', confidence: 40),
            contextIntegrity:
                const AxisAssessment(label: 'misleading', confidence: 55),
            postConfidence: 45,
            shareDecision: 'do_not_share',
            version: version,
          ),
        );
        return done.xpAwarded;
      }

      final adultXp = await xpFor(AudienceMode.adult);
      final childXp = await xpFor(AudienceMode.child);
      expect(childXp, adultXp,
          reason: 'the younger mode paid differently for the same work');
    });
  });

  test('every mission belongs to exactly one arena', () async {
    // An untagged mission would be reachable only through "Everything"
    // and would vanish from every arena — present in the product and
    // absent from the way people navigate it.
    final path = await repo().getLearningPath();
    for (final node in path.nodes) {
      expect(demoArenaOf[node.missionId], isNotNull,
          reason: '${node.missionId} belongs to no arena');
    }

    // And every arena has something in it, or it is a room with a sign
    // and no door.
    for (final arena in kArenaOrder) {
      expect(
        path.nodes.where((n) => demoArenaOf[n.missionId] == arena),
        isNotEmpty,
        reason: '$arena is empty in the adult mode',
      );
    }
  });
}
