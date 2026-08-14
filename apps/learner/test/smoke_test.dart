import 'package:design_system/design_system.dart';
import 'package:evidence_gym_learner/app.dart';
import 'package:evidence_gym_learner/app_settings.dart';
import 'package:evidence_gym_learner/data/demo_fixtures.dart';
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

  testWidgets('Skip reaches the auth screen', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);

    await tester.tap(find.text('Skip'));
    await _settle(tester);

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Enter demo'), findsOneWidget);
  });

  testWidgets('a wrong demo key is rejected and does not navigate', (
    tester,
  ) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'NOPE');
    // The demo route sits below the privacy notice and the audience
    // choice, so reaching it takes a scroll — as it does for a person.
    await tester.ensureVisible(find.text('Enter demo'));
    await tester.pump();
    await tester.tap(find.text('Enter demo'));
    await _settle(tester);

    expect(find.textContaining(demoAccessKey), findsOneWidget);
    expect(find.text('Your path'), findsNothing);
  });

  testWidgets('the demo key opens the path with the demo pack', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), demoAccessKey);
    await tester.ensureVisible(find.text('Enter demo'));
    await tester.pump();
    await tester.tap(find.text('Enter demo'));
    await _settle(tester);

    await _chooseEverything(tester);
    expect(find.text('Your path'), findsOneWidget);
    expect(find.text('Real Image, Wrong Story'), findsWidgets);
  });

  test('the demo pack advances the path as missions are completed', () {
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

  testWidgets('both ways in still work on a small phone', (tester) async {
    // Guarding a regression I caused: adding a second privacy notice to
    // this screen pushed the demo entry below the fold, and the only
    // symptom was two unrelated-looking test failures. Anything added
    // above the entry points has to keep them reachable, and the screen
    // people meet first is the worst place to find that out late.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    // The primary action has to be there on arrival. hitTestable() is
    // the check that matters: a widget can be in the tree, and laid out,
    // and still be somewhere a finger cannot land.
    expect(
      find.text('Continue as guest').hitTestable(),
      findsOneWidget,
      reason:
          'the main way in is not reachable at 360x640 without '
          'scrolling',
    );

    // The demo route may sit below the fold — it is the secondary path,
    // and the privacy notice and audience choice legitimately come
    // first. What it may not do is stop working.
    expect(find.text('Enter demo'), findsOneWidget);
    await tester.enterText(find.byType(TextField), demoAccessKey);
    await tester.ensureVisible(find.text('Enter demo'));
    await tester.pump();
    await tester.tap(find.text('Enter demo'));
    await _settle(tester);
    await _chooseEverything(tester);
    expect(
      find.text('Your path'),
      findsOneWidget,
      reason: 'the demo entry did not actually work at phone size',
    );
  });

  testWidgets(
    'choosing an arena narrows the path, and it can be changed back',
    (tester) async {
      await tester.pumpWidget(EvidenceGymApp(settings: _english()));
      await _settle(tester);
      await tester.tap(find.text('Skip'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), demoAccessKey);
      await tester.ensureVisible(find.text('Enter demo'));
      await tester.pump();
      await tester.tap(find.text('Enter demo'));
      await _settle(tester);

      // Crisis holds the media-context mission; the AI citation belongs to
      // health and science and must not follow the learner in.
      await tester.ensureVisible(find.text('Crisis and emergency'));
      await tester.pump();
      await tester.tap(find.text('Crisis and emergency'));
      await _settle(tester);

      expect(find.text('Your path'), findsOneWidget);
      expect(
        find.text('Real Image, Wrong Story'),
        findsWidgets,
        reason: 'the arena is missing a mission that belongs to it',
      );
      expect(
        find.text('The Citation That Sounds Real'),
        findsNothing,
        reason: 'a mission from another arena leaked into this one',
      );

      // A filter nobody can undo is a trap: a learner who wonders where
      // the other missions went needs the way back to be on the screen.
      expect(find.textContaining('Change subject'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Change subject'));
      await tester.pump();
      await tester.tap(find.textContaining('Change subject'));
      await _settle(tester);
      expect(find.text('What are you up against?'), findsOneWidget);
    },
  );
}

/// Entering the demo now lands on the arena grid — the choice of which
/// kind of disinformation to work on — and the path is one tap further
/// in. Tests that want the path say so explicitly rather than pretending
/// the screen order did not change.
Future<void> _chooseEverything(WidgetTester tester) async {
  expect(
    find.text('What are you up against?'),
    findsOneWidget,
    reason: 'the arena grid should be the first thing after entering',
  );
  await tester.ensureVisible(find.text('Everything'));
  await tester.pump();
  await tester.tap(find.text('Everything'));
  await _settle(tester);
}
