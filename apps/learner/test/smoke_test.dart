import 'package:design_system/design_system.dart';
import 'package:evidence_gym_learner/app.dart';
import 'package:evidence_gym_learner/app_settings.dart';
import 'package:evidence_gym_learner/data/demo_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppSettings _english() => AppSettings(locale: const Locale('en'));

void main() {
  testWidgets('onboarding shows the first slide in the selected language', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await tester.pumpAndSettle();

    expect(find.text('Investigate, don\'t guess.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('defaults to Ukrainian', (tester) async {
    await tester.pumpWidget(const EvidenceGymApp());
    await tester.pumpAndSettle();

    expect(find.text('Перевіряй, а не вгадуй.'), findsOneWidget);
  });

  testWidgets('Skip reaches the auth screen', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Enter demo'), findsOneWidget);
  });

  testWidgets('a wrong demo key is rejected and does not navigate', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('Enter demo'));
    await tester.pumpAndSettle();

    expect(find.textContaining(demoAccessKey), findsOneWidget);
    expect(find.text('Your path'), findsNothing);
  });

  testWidgets('the demo key opens the path with the demo pack', (tester) async {
    await tester.pumpWidget(EvidenceGymApp(settings: _english()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), demoAccessKey);
    await tester.tap(find.text('Enter demo'));
    await tester.pumpAndSettle();

    expect(find.text('Your path'), findsOneWidget);
    expect(find.text('The flood photo'), findsWidgets);
  });

  testWidgets('every axis offers an explicit uncertainty answer', (tester) async {
    // "Insufficient evidence" being selectable is a product invariant, not
    // a nicety: CONCEPT.md treats it as a first-class outcome.
    for (final axis in AxisKind.values) {
      expect(
        axisOptionCodes(axis).any((o) => o.tone == AxisTone.unknown),
        isTrue,
        reason: '$axis must offer an unknown/insufficient option',
      );
    }
  });
}
