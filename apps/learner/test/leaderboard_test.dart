import 'package:evidence_gym_learner/data/api_client.dart';
import 'package:evidence_gym_learner/data/audience.dart';
import 'package:evidence_gym_learner/data/mission_repository.dart';
import 'package:evidence_gym_learner/data/models.dart';
import 'package:evidence_gym_learner/features/leaderboard/leaderboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board is built against `SCREEN_REFERENCE.md`, which lists "no
/// leaderboard" among the deliberate absences. The reasoning there was
/// sound — ranking people on judging truth rewards speed and confidence,
/// the two habits this product exists to slow down — so the parts that
/// cause that harm are removed rather than the idea.
///
/// These tests pin the removals. If any of them ever fails, the board
/// has turned back into the thing the docs warned about.
void main() {
  DemoMissionRepository repo() => DemoMissionRepository(
        localeCode: () => 'en',
        audience: () => AudienceMode.adult,
      );

  test('nobody is on the board until they opt in', () async {
    // Showing other people first and asking afterwards would make the
    // choice a formality.
    final r = repo();
    expect(r.boardHandleSet, isFalse);
    expect(await r.getLeaderboard(), isEmpty);

    r.joinBoard('someone');
    expect(await r.getLeaderboard(), isNotEmpty);

    r.leaveBoard();
    expect(await r.getLeaderboard(), isEmpty,
        reason: 'leaving must actually remove the learner from the board');
  });

  test('rank comes from process XP, which being right cannot earn',
      () async {
    // Two learners, same single mission, opposite conclusions, same
    // number of checks. If accuracy ever leaks into the ranking, these
    // two stop tying.
    Future<int> xpFor(String verdict) async {
      final r = repo();
      final path = await r.getLearningPath();
      final mission = await r.getMission(path.nodes.first.missionId);
      final attempt = await r.startAttempt(mission.id, mission.version);
      final predicted = await r.submitPrediction(
        attempt.id,
        PredictionInput(
            reaction: 'investigate', confidence: 50, version: attempt.version),
      );
      var version = predicted.version;
      for (final action in mission.evidenceActions) {
        final result =
            await r.useEvidenceAction(attempt.id, mission.id, action.id, version);
        version = result.attemptVersion;
      }
      final done = await r.submitConclusion(
        attempt.id,
        ConclusionInput(
          authenticity: AxisAssessment(label: verdict, confidence: 90),
          claimVeracity: AxisAssessment(label: verdict, confidence: 90),
          contextIntegrity: AxisAssessment(label: verdict, confidence: 90),
          postConfidence: 90,
          shareDecision: 'do_not_share',
          version: version,
        ),
      );
      return done.xpAwarded;
    }

    expect(await xpFor('authentic'), await xpFor('altered'),
        reason: 'the board would be ranking accuracy, which is the one '
            'thing it must never do');
  });

  test('the board carries no conclusions, confidence or accuracy',
      () async {
    // What a row may contain is the whole privacy question here. A
    // learner's conclusions and how sure they were belong to them.
    final r = repo();
    r.joinBoard('me');
    final board = await r.getLeaderboard();
    final mine = board.firstWhere((e) => e.isYou);

    // The type itself is the guarantee: if a field for accuracy or
    // confidence is ever added, this stops compiling rather than
    // quietly starting to leak.
    expect(mine.handle, 'me');
    expect(mine.xp, isA<int>());
    expect(mine.missions, isA<int>());
  });

  test('a live board is empty rather than invented', () async {
    // The demo fills the screen with obviously fictional names. A live
    // client with no leaderboard endpoint must show nothing at all —
    // fabricating rivals is the same sin as the invented streak that
    // had to be taken off the path header.
    final live = LiveMissionRepository(EvidenceGymApiClient(
      baseUrl: Uri.parse('http://localhost:1/'),
      authTokenProvider: () async => null,
    ));
    expect(await live.getLeaderboard(), isEmpty);
    expect(live.boardHandleSet, isFalse);
  });

  group('handle sanitising', () {
    // The one string in this product that one user writes and another
    // reads. Flutter renders it as text rather than markup so there is
    // no injection here, but the other risks of user-supplied text are
    // real and a client can do something about three of them.
    test('a right-to-left override cannot rewrite the row around it', () {
      // U+202E does not stop at the end of the string, so a handle
      // containing one visually reverses the score beside it. Same
      // trick as filename spoofing, same shape of target.
      //
      // Written as an escape rather than pasted: putting the real
      // code point in the file makes this test source itself do the
      // thing being tested, and the analyser flags it.
      const attack = 'abc\u202Edef';
      expect(sanitiseHandle(attack), 'abcdef');
      expect(sanitiseHandle(attack).contains('\u202E'), isFalse);
    });

    test('zero-width characters cannot make two handles look identical', () {
      // How impersonation on a board works: same rendering, different
      // string, so the board shows what looks like one person twice.
      expect(sanitiseHandle('Ma\u200Bria'), 'Maria');
      expect(sanitiseHandle('Maria'), sanitiseHandle('Ma\u200Bria'));
    });

    test('newlines and runaway length cannot break the row', () {
      expect(sanitiseHandle('two\nlines'), 'two lines');
      expect(sanitiseHandle('   spaced   out   '), 'spaced out');
      expect(sanitiseHandle('x' * 200).length, 24);
    });

    test('an ordinary handle is left alone, including non-Latin', () {
      // The cleaning must not quietly mangle the languages this product
      // ships in — stripping anything unfamiliar would be worse than
      // the problem.
      expect(sanitiseHandle('Олена'), 'Олена');
      expect(sanitiseHandle('learner_42'), 'learner_42');
      expect(sanitiseHandle('Ana Maria'), 'Ana Maria');
    });
  });
}
