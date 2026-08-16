import 'package:evidence_gym_learner/app.dart';
import 'package:evidence_gym_learner/app_settings.dart';
import 'package:evidence_gym_learner/data/account.dart';
import 'package:evidence_gym_learner/data/audience.dart';
import 'package:evidence_gym_learner/data/mission_repository.dart';
import 'package:evidence_gym_learner/features/shell/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lupa and Slid animate continuously, so `pumpAndSettle` never returns.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Opens the shell directly on the bundled pack.
///
/// These tests are about layout at 200% text, not about the sign-in
/// journey — and sign-in now needs a credential no test build carries.
/// Going through the front door would make every one of them a test of
/// authentication instead of a test of whether the path clips.
Widget _shell({required String locale, required double scale}) =>
    EvidenceGymApp(
      settings: AppSettings(locale: Locale(locale), textScale: scale),
      home: HomeShell(
        repository: DemoMissionRepository(
          localeCode: () => locale,
          audience: () => AudienceMode.adult,
        ),
        account: const Account(
          id: 'test',
          role: AccountRole.learner,
          token: 'test',
        ),
      ),
    );


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

        await tester.pumpWidget(_shell(locale: locale, scale: scale));
        await _settle(tester);

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
        // Straight into the shell, like the layout tests above: this is
        // about whether reduced motion strands someone mid-reveal, not
        // about the journey to the shell.
        child: _shell(locale: 'en', scale: 1.0),
      ),
    );
    await _settle(tester);

    expect(find.text('What are you up against?'), findsOneWidget);
    await tester.ensureVisible(find.text('Everything'));
    await tester.pump();
    await tester.tap(find.text('Everything'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your path'), findsOneWidget);
    _expectNoOverflow();
  });
}
