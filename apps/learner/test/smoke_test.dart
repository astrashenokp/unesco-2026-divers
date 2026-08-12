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
  testWidgets('onboarding shows the first slide in the selected language', (tester) async {
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

  testWidgets('a wrong demo key is rejected and does not navigate', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await _settle(tester);
    await tester.tap(find.text('Skip'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'NOPE');
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
    await tester.tap(find.text('Enter demo'));
    await _settle(tester);

    expect(find.text('Your path'), findsOneWidget);
    expect(find.text('The flood photo'), findsWidgets);
  });

  test('the demo pack advances the path as missions are completed', () {
    // The path must actually move: exactly one mission open at a time,
    // everything before it done, everything after it locked.
    for (var done = 0; done <= 3; done++) {
      final path = demoLearningPathFor('uk', completed: done);
      expect(path.nodes.where((n) => n.state == 'completed').length, done);
      expect(path.nodes.where((n) => n.state == 'available').length, 1,
          reason: 'exactly one mission should be open at $done completed');
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
}
