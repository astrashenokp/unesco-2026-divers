import 'package:design_system/design_system.dart';
import 'package:evidence_gym_learner/app.dart';
import 'package:evidence_gym_learner/app_settings.dart';
import 'package:evidence_gym_learner/data/demo_fixtures.dart';
import 'package:evidence_gym_learner/data/account.dart';
import 'package:evidence_gym_learner/data/audience.dart';
import 'package:evidence_gym_learner/data/mission_repository.dart';
import 'package:evidence_gym_learner/features/shell/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppSettings _english() => AppSettings(locale: const Locale('en'));

/// Lupa and Slid animate continuously by design, so `pumpAndSettle` never
/// returns — it waits for a frame-idle that will not come. Pump a bounded
/// number of frames instead, which is long enough to cover a route
/// transition plus the demo repository's simulated latency.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  testWidgets('onboarding shows the first slide in the selected language', (
    tester,
  ) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);

    expect(find.text('Investigate, don\'t guess.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('defaults to Ukrainian', (tester) async {
    await tester.pumpWidget(const EvidenceGymApp());
    await _settle(tester);

    expect(find.text('Перевіряй, а не вгадуй.'), findsOneWidget);
  });

  testWidgets('Skip reaches sign-in, with both accounts printed', (
    tester,
  ) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    // Real fields, with both accounts printed underneath. They are
    // demonstration credentials: one that had to stay secret would not
    // be on the screen.
    expect(find.byKey(const ValueKey('auth.login')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth.password')), findsOneWidget);
    expect(find.text('Learner'), findsOneWidget);
    expect(find.text('Operator'), findsOneWidget);
    expect(find.textContaining('learner / evidence2026'), findsOneWidget);
    expect(find.textContaining('operator / cohort2026'), findsOneWidget);
  });

  testWidgets('signing in without a credential says so plainly', (
    tester,
  ) async {
    // No token is compiled into a test build, so this is the path any
    // build without credentials takes. It has to name the reason rather
    // than leave someone pressing a button that does nothing.
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    // A wrong pairing is refused before any token is chosen.
    await tester.enterText(
        find.byKey(const ValueKey('auth.login')), 'learner');
    await tester.enterText(
        find.byKey(const ValueKey('auth.password')), 'wrong');
    await tester.ensureVisible(find.byKey(const ValueKey('auth.signIn')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth.signIn')));
    await _settle(tester);
    expect(find.textContaining('do not match'), findsOneWidget);
    expect(find.text('Your path'), findsNothing,
        reason: 'a failed sign-in must not let anyone through');

    // The right pairing gets past the form and stops at the credential
    // this build does not carry — which is a different failure, and has
    // to say so rather than repeating the first one.
    await tester.enterText(
        find.byKey(const ValueKey('auth.password')), 'evidence2026');
    await tester.tap(find.byKey(const ValueKey('auth.signIn')));
    await _settle(tester);
    expect(find.textContaining('no credential'), findsOneWidget);
  });

  testWidgets('sign-in is reachable on a small phone', (tester) async {
    // Guarding a regression I caused twice: things added above the entry
    // points pushed them off the screen, and the only symptom was
    // unrelated-looking failures on the screen people meet first.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    expect(
      find.byKey(const ValueKey('auth.login')).hitTestable(),
      findsOneWidget,
      reason: 'the login field is not reachable at 360x640 without scrolling',
    );
    // The printed credentials may sit below the fold — the privacy
    // notice and audience choice legitimately come first — but both
    // accounts must be there.
    expect(find.text('Learner'), findsOneWidget);
    expect(find.text('Operator'), findsOneWidget);
  });

  test('the bundled pack advances the path as missions are completed', () {
    // The path must actually move: exactly one mission open at a time,
    // everything before it done, everything after it locked.
    for (var done = 0; done < demoMissionsFor('uk').length; done++) {
      final path = demoLearningPathFor('uk', completed: done);
      expect(path.nodes.where((n) => n.state == 'completed').length, done);
      expect(
        path.nodes.where((n) => n.state == 'available').length,
        1,
        reason: 'exactly one mission should be open at $done completed',
      );
    }
  });

  test('every mission belongs to a chapter', () {
    // A mission with no chapter would render without a heading and
    // silently break the grouping.
    for (final id in demoMissionsFor('uk').keys) {
      expect(demoChapterOf[id], isNotNull, reason: '$id has no chapter');
    }
  });

  test('every axis offers an explicit uncertainty answer', () {
    // A product invariant, not a nicety: CONCEPT.md treats "insufficient
    // evidence" as a first-class outcome, so no axis may force the
    // learner into a confident answer.
    for (final axis in AxisKind.values) {
      expect(
        axisOptionCodes(axis).any((o) => o.tone == AxisTone.unknown),
        isTrue,
        reason: '$axis must offer an unknown/insufficient option',
      );
    }
  });

  testWidgets('choosing an arena narrows the path, and it can be changed '
      'back', (tester) async {
    // Opens the shell directly rather than signing in. This test is
    // about what the arena grid does to the path, and routing it through
    // a credential no test build carries would make it a test of
    // authentication instead.
    await tester.pumpWidget(EvidenceGymApp(
      settings: _english(),
      home: HomeShell(
        repository: DemoMissionRepository(
          localeCode: () => 'en',
          audience: () => AudienceMode.adult,
        ),
        account: const Account(
          id: 'test',
          role: AccountRole.learner,
          token: 'test',
        ),
      ),
    ));
    await _settle(tester);

    expect(find.text('What are you up against?'), findsOneWidget,
        reason: 'the arena grid should be the first thing in the shell');

    await tester.ensureVisible(find.text('Crisis and emergency'));
    await tester.pump();
    await tester.tap(find.text('Crisis and emergency'));
    await _settle(tester);

    expect(find.text('Your path'), findsOneWidget);

    // A filter nobody can undo is a trap: someone wondering where the
    // other missions went needs the way back on the screen.
    expect(find.textContaining('Change subject'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Change subject'));
    await tester.pump();
    await tester.tap(find.textContaining('Change subject'));
    await _settle(tester);
    expect(find.text('What are you up against?'), findsOneWidget);
  });

}
