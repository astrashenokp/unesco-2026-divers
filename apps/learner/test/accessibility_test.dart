import 'package:evidence_gym_learner/app.dart';
import 'package:evidence_gym_learner/app_settings.dart';
import 'package:evidence_gym_learner/data/demo_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lupa and Slid animate continuously, so `pumpAndSettle` never returns.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Walks onboarding into the demo path.
///
/// Finds controls by key, not by label or by widget type. Labels are
/// localized, and byType is fragile here: SegmentedButton renders its
/// segments as TextButtons, so `find.byType(TextButton).first` grabbed
/// the language switch instead of Skip.
Future<void> _enterDemo(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding.skip')));
  await _settle(tester);
  await tester.enterText(
      find.byKey(const ValueKey('auth.demoKey')), demoAccessKey);
  await tester.ensureVisible(find.byKey(const ValueKey('auth.enterDemo')));
  await tester.tap(find.byKey(const ValueKey('auth.enterDemo')));
  await _settle(tester);
}

/// Fails if anything overflowed its bounds during the test.
///
/// Flutter reports overflow as a caught exception rather than a crash,
/// so without this check a clipped layout passes silently — which is
/// exactly how the wide-layout overflow shipped earlier.
void _expectNoOverflow() {
  final error = TestWidgetsFlutterBinding.instance.takeException();
  expect(
    error,
    isNull,
    reason: 'layout overflowed: $error',
  );
}

void main() {
  // 200% text is a WCAG 2.2 requirement and the size at which most
  // layouts break. Each screen is checked at both extremes.
  for (final scale in [1.0, 2.0]) {
    for (final locale in ['uk', 'en']) {
      testWidgets('path screen survives ${(scale * 100).round()}% text in $locale',
          (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(EvidenceGymApp(
          settings: AppSettings(locale: Locale(locale), textScale: scale),
        ));
        await _settle(tester);
        await _enterDemo(tester);

        _expectNoOverflow();
      });
    }
  }

  testWidgets('laptop width survives 200% text', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(EvidenceGymApp(
      settings: AppSettings(locale: const Locale('uk'), textScale: 2.0),
    ));
    await _settle(tester);
    await _enterDemo(tester);

    _expectNoOverflow();
  });

  testWidgets('reduced motion still reaches the path', (tester) async {
    // Every animation must have a path to the same end state. If a
    // reveal or transition gated content, the path would never appear.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: EvidenceGymApp(settings: AppSettings(locale: const Locale('en'))),
      ),
    );
    await _settle(tester);
    await _enterDemo(tester);

    expect(find.text('What are you up against?'), findsOneWidget);
    await tester.ensureVisible(find.text('Everything'));
    await tester.pump();
    await tester.tap(find.text('Everything'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your path'), findsOneWidget);
    _expectNoOverflow();
  });
}
