import 'package:evidence_gym_learner/data/api_client.dart';
import 'package:evidence_gym_learner/data/arenas.dart';
import 'package:evidence_gym_learner/data/gameplay.dart';
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
      DemoMissionRepository(localeCode: () => 'en', audience: () => audience);

  Future<Attempt> startFirst(DemoMissionRepository r) async {
    final path = await r.getLearningPath();
    final first = path.nodes.first;
    final mission = await r.getMission(first.missionId);
    return r.startAttempt(mission.id, mission.version);
  }

  test('offline demo mirrors the two Role 3 P0 missions', () {
    expect(demoMissionsFor('en').keys.toList(), [
      'authentic-media-wrong-context',
      'ai-citation-integrity',
    ]);
    expect(demoLearningPathFor('en').nodes.map((n) => n.missionId).toList(), [
      'authentic-media-wrong-context',
      'ai-citation-integrity',
    ]);
  });

  test('an attempt walks ready -> predicted -> investigating', () async {
    final r = repo();
    final attempt = await startFirst(r);
    expect(attempt.state, 'ready');

    final predicted = await r.submitPrediction(
      attempt.id,
      PredictionInput(
        reaction: 'suspicious',
        confidence: 40,
        version: attempt.version,
      ),
    );
    expect(predicted.state, 'predicted');
    // The version must advance, or optimistic concurrency cannot detect
    // a stale write.
    expect(predicted.version, greaterThan(attempt.version));

    final evidence = await r.useEvidenceAction(
      attempt.id,
      'authentic-media-wrong-context',
      'action-source-identity',
      2,
    );
    // ADR-009: an evidence action advances the attempt and the response
    // reports the new version. Without this the conclusion would send a
    // version every evidence action has moved past.
    expect(evidence.attemptVersion, greaterThan(predicted.version));
  });

  test('the receipt cites exactly the evidence that was looked at', () async {
    final r = repo();
    final attempt = await startFirst(r);
    await r.submitPrediction(
      attempt.id,
      PredictionInput(
        reaction: 'investigate',
        confidence: 30,
        version: attempt.version,
      ),
    );

    final a = await r.useEvidenceAction(
      attempt.id,
      'authentic-media-wrong-context',
      'action-source-identity',
      2,
    );
    final b = await r.useEvidenceAction(
      attempt.id,
      'authentic-media-wrong-context',
      'action-provenance-scan',
      2,
    );
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
    expect(
      receipt.evidenceRefs,
      expected,
      reason: 'a receipt must cite what was actually examined, nothing more',
    );
  });

  test(
    'a demo receipt is marked unsigned rather than given a fake hash',
    () async {
      // Inventing a convincing hash in a product about checking provenance
      // would be the exact failure it teaches against.
      final r = repo();
      final attempt = await startFirst(r);
      await r.submitPrediction(
        attempt.id,
        PredictionInput(
          reaction: 'trust',
          confidence: 60,
          version: attempt.version,
        ),
      );
      await r.useEvidenceAction(
        attempt.id,
        'authentic-media-wrong-context',
        'action-source-identity',
        2,
      );

      final result = await r.submitConclusion(
        attempt.id,
        const ConclusionInput(
          authenticity: AxisAssessment(label: 'unknown', confidence: 20),
          claimVeracity: AxisAssessment(
            label: 'insufficient_evidence',
            confidence: 20,
          ),
          contextIntegrity: AxisAssessment(label: 'unknown', confidence: 20),
          postConfidence: 25,
          shareDecision: 'continue_investigating',
          version: 2,
        ),
      );
      final receipt = await r.getReceipt(result.receiptId);
      expect(receipt.hash, 'demo-unsigned');
    },
  );

  test(
    'XP rewards how much was investigated, not what was concluded',
    () async {
      // Two attempts reaching opposite conclusions, one with more checks.
      // The one that investigated more must earn more.
      Future<int> run(List<String> actions, String verdict) async {
        final r = repo();
        final attempt = await startFirst(r);
        await r.submitPrediction(
          attempt.id,
          PredictionInput(
            reaction: 'investigate',
            confidence: 50,
            version: attempt.version,
          ),
        );
        for (final a in actions) {
          await r.useEvidenceAction(
            attempt.id,
            'authentic-media-wrong-context',
            a,
            2,
          );
        }
        final result = await r.submitConclusion(
          attempt.id,
          ConclusionInput(
            authenticity: AxisAssessment(label: verdict, confidence: 50),
            claimVeracity: const AxisAssessment(
              label: 'supported',
              confidence: 50,
            ),
            contextIntegrity: const AxisAssessment(
              label: 'accurate',
              confidence: 50,
            ),
            postConfidence: 50,
            shareDecision: 'do_not_share',
            version: 2,
          ),
        );
        return result.xpAwarded;
      }

      final thorough = await run([
        'action-source-identity',
        'action-provenance-scan',
        'action-primary-source',
      ], 'authentic');
      final hasty = await run(['action-source-identity'], 'altered');
      expect(thorough, greaterThan(hasty));

      // Pinned to the reviewed ladder, not just ordered. `greaterThan`
      // alone passed under the homemade `1 + checks` formula this used to
      // use, so it could not have caught the demo drifting away from the
      // rubric the product actually scores by.
      expect(hasty, 2, reason: 'one check is process level 1, worth 2 XP');
      expect(thorough, 6, reason: 'three checks is level 3, worth 6 XP');
    },
  );

  test(
    'the demo pays the rubric, and stops paying past the top rung',
    () async {
      // The old formula was unbounded: every extra check bought another
      // point forever, which rewards clicking rather than investigating.
      final r = repo();
      final mission = await r.getMission('authentic-media-wrong-context');
      expect(
        mission.rubric,
        isNotEmpty,
        reason: 'a mission with no rubric cannot pay anything',
      );
      expect(
        xpFor(mission.rubric, 4),
        xpFor(mission.rubric, 40),
        reason: 'running forty checks must not pay more than four',
      );
    },
  );

  test('the coach climbs its ladder and stops at four', () async {
    final r = repo();
    final attempt = await startFirst(r);
    final levels = <int>[];
    for (var i = 0; i < 7; i++) {
      final hint = await r.requestHint(
        attempt.id,
        'authentic-media-wrong-context',
      );
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
    final hint = await r.requestHint(
      attempt.id,
      'authentic-media-wrong-context',
    );
    expect(hint.fallback, isTrue);
  });

  test('a missing evidence fixture returns not_found, not an error', () async {
    // "Not found in the queried sources" is a legitimate result the
    // learner must reason about, not a failure to hide.
    final r = repo();
    final attempt = await startFirst(r);
    final result = await r.useEvidenceAction(
      attempt.id,
      'authentic-media-wrong-context',
      'no_such_action',
      2,
    );
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
      PredictionInput(
        reaction: 'trust',
        confidence: 80,
        version: attempt.version,
      ),
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
    expect(
      error.needsMoreEvidence,
      isTrue,
      reason: 'a conclusion without evidence is a step not yet taken',
    );
    expect(
      error.isStaleVersion,
      isFalse,
      reason:
          'restarting here would throw away work the learner had not '
          'finished doing',
    );
  });

  test('a repeated evidence action is its own kind of 409', () {
    // Three unrelated situations share this status on one endpoint and
    // they call for opposite responses: restart, do more work, or do
    // nothing at all. A repeat costs the learner nothing — they already
    // have the result — so it must not read as a fault or offer to
    // start the mission over.
    for (final code in [
      'evidence-action-already-used',
      'evidence_action_already_used',
    ]) {
      final error = EvidenceGymApiException(
        Problem(
          type: 'about:blank',
          title: 'Already used',
          status: 409,
          code: code,
          traceId: 't',
        ),
      );
      expect(error.evidenceAlreadyUsed, isTrue, reason: '$code not recognised');
      expect(
        error.isStaleVersion,
        isFalse,
        reason: 'a repeat must not offer to restart the mission',
      );
      expect(error.needsMoreEvidence, isFalse);
    }
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
    test(
      'the younger mode hides the distressing missions and only those',
      () async {
        final adult = await repo().getLearningPath();
        final child =
            await repo(audience: AudienceMode.child).getLearningPath();

        expect(
          child.nodes.length,
          lessThan(adult.nodes.length),
          reason: 'nothing was filtered, so the mode does nothing',
        );
        expect(
          child.nodes,
          hasLength(1),
          reason:
              'the younger mode should keep the reviewed academic-integrity '
              'mission and hide the distressing natural-disaster case',
        );
        expect(child.nodes.single.missionId, 'ai-citation-integrity');

        // Named explicitly rather than counted, so a change of intent has
        // to be a change of test rather than a number quietly moving.
        final hidden =
            adult.nodes.map((n) => n.missionId).toSet()
              ..removeAll(child.nodes.map((n) => n.missionId));
        final missions = demoMissionsFor('en');
        for (final id in hidden) {
          expect(
            missions[id]!.contentWarnings,
            isNotEmpty,
            reason: '$id was hidden but declares nothing to warn about',
          );
        }
        for (final node in child.nodes) {
          expect(
            suitableFor(
              AudienceMode.child,
              missions[node.missionId]!.contentWarnings,
            ),
            isTrue,
            reason: '${node.missionId} reached the younger path unsuitable',
          );
        }
      },
    );

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
        throwsA(
          isA<EvidenceGymApiException>().having(
            (e) => e.problem.status,
            'status',
            404,
          ),
        ),
      );
    });

    test('a mission nobody tagged is not assumed safe for children', () {
      // The hole Rina found in #26. Parsing a missing `contentWarnings`
      // as an empty list made a server that does not implement the
      // field look exactly like content reviewed and certified as
      // unremarkable, so every live mission passed the child filter.
      //
      // Null is "nobody said" and empty is "reviewed, nothing to warn
      // about". The contract makes the field required precisely so an
      // empty array can be a positive statement.
      expect(
        suitableFor(AudienceMode.child, null),
        isFalse,
        reason: 'filtering on silence is not filtering',
      );
      expect(
        suitableFor(AudienceMode.child, const []),
        isTrue,
        reason:
            'a reviewed mission that declares nothing must still '
            'be reachable, or the younger mode empties out',
      );
      expect(
        suitableFor(AudienceMode.adult, null),
        isTrue,
        reason: 'the adult mode filters nothing',
      );
    });

    test('an unrecognised content warning fails closed', () {
      // The rule that matters most. A blocklist would admit every tag
      // nobody thought of, so the first warning from a new pack would
      // reach a child precisely because it was unfamiliar.
      expect(
        suitableFor(AudienceMode.child, ['something-nobody-added-yet']),
        isFalse,
        reason: 'an unknown warning was treated as safe for children',
      );
      expect(
        suitableFor(AudienceMode.child, []),
        isTrue,
        reason:
            'declaring nothing to warn about is not the same as '
            'carrying an unknown warning',
      );
      expect(
        suitableFor(AudienceMode.adult, ['something-nobody-added-yet']),
        isTrue,
        reason: 'the adult mode filters nothing',
      );
    });

    test(
      'the younger mode does not create alternate scoring fixtures',
      () async {
        final adult = await repo().getLearningPath();
        final child =
            await repo(audience: AudienceMode.child).getLearningPath();

        expect(adult.nodes, isNotEmpty);
        final adultIds = adult.nodes.map((n) => n.missionId).toSet();
        final childIds = child.nodes.map((n) => n.missionId).toSet();
        expect(
          childIds.difference(adultIds),
          isEmpty,
          reason: 'audience filtering must not substitute local-only missions',
        );
      },
    );
  });

  test('every mission belongs to exactly one arena', () async {
    // An untagged mission would be reachable only through "Everything"
    // and would vanish from every arena — present in the product and
    // absent from the way people navigate it.
    final path = await repo().getLearningPath();
    for (final node in path.nodes) {
      expect(
        demoArenaOf[node.missionId],
        isNotNull,
        reason: '${node.missionId} belongs to no arena',
      );
    }

    final representedArenas =
        path.nodes.map((n) => demoArenaOf[n.missionId]).toSet();
    expect(representedArenas, contains(DisinfoArena.crisis));
    expect(representedArenas, contains(DisinfoArena.healthAndScience));
  });

  test('a receipt can be traced back to its mission, in demo mode', () async {
    // Without this the ADR-005 correction flow can never reach a
    // learner: telling them the material was corrected means comparing
    // the receipt's version against the mission's current one, and a
    // receipt that does not know its mission cannot be compared to
    // anything.
    final r = repo();
    final attempt = await startFirst(r);
    await r.submitPrediction(
      attempt.id,
      PredictionInput(
        reaction: 'trust',
        confidence: 60,
        version: attempt.version,
      ),
    );
    final evidence = await r.useEvidenceAction(
      attempt.id,
      'authentic-media-wrong-context',
      'action-source-identity',
      2,
    );
    final done = await r.submitConclusion(
      attempt.id,
      ConclusionInput(
        authenticity: const AxisAssessment(label: 'authentic', confidence: 60),
        claimVeracity: const AxisAssessment(
          label: 'insufficient_evidence',
          confidence: 40,
        ),
        contextIntegrity: const AxisAssessment(
          label: 'accurate',
          confidence: 60,
        ),
        postConfidence: 50,
        shareDecision: 'do_not_share',
        version: evidence.attemptVersion,
      ),
    );

    final receipt = await r.getReceipt(done.receiptId);
    expect(receipt.missionId, 'authentic-media-wrong-context');

    // And the mission it points at must actually exist, or the lookup
    // that drives the banner throws instead of resolving.
    final mission = await r.getMission(receipt.missionId!);
    expect(
      mission.version,
      receipt.missionVersion,
      reason: 'an unchanged mission must not look corrected',
    );
  });
}
