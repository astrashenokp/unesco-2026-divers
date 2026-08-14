import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ladder shipped showing every rung in one place and none in
/// another, and nothing caught it — the component was correct and two of
/// its three call sites were not. These pin the component's own promise;
/// the call sites are pinned in the learner app.
void main() {
  const rungs = [
    LadderRung(level: 0, criteria: 'instinct only', xp: 1),
    LadderRung(level: 1, criteria: 'source checked', xp: 2),
    LadderRung(level: 2, criteria: 'earlier source found', xp: 4),
    LadderRung(level: 3, criteria: 'context corroborated', xp: 6),
    LadderRung(level: 4, criteria: 'calibrated conclusion', xp: 8),
  ];

  Widget host(int? reached, {Size size = const Size(600, 900)}) => MaterialApp(
        theme: buildEvidenceGymTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LevelLadder(
              rungs: rungs,
              reached: reached,
              levelLabel: (l, t) => 'Level $l of $t',
              xpLabel: (x) => '$x XP',
              reachedLabel: 'here',
              nextLabel: 'next',
            ),
          ),
        ),
      );

  testWidgets('every rung is rendered, whichever one was reached',
      (tester) async {
    // The bug was rungs going missing, so this counts all of them at
    // every position rather than checking that "some" appear.
    for (final reached in <int?>[null, 0, 2, 4]) {
      await tester.pumpWidget(host(reached));
      await tester.pump(const Duration(seconds: 1));
      for (final rung in rungs) {
        expect(find.text('Level ${rung.level} of 4'), findsOneWidget,
            reason: 'level ${rung.level} missing when reached=$reached');
        expect(find.text('${rung.xp} XP'), findsOneWidget);
        expect(find.text(rung.criteria), findsOneWidget,
            reason: 'a rung without its criteria is a number with no scale');
      }
    }
  });

  testWidgets('the rung reached is marked, and only that one',
      (tester) async {
    await tester.pumpWidget(host(2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('here'), findsOneWidget);
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('with no rung reached, nothing is marked', (tester) async {
    // The reference view on the profile and on a stored receipt. Marking
    // a rung there would be inventing a level neither screen knows.
    await tester.pumpWidget(host(null));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('here'), findsNothing);
    expect(find.text('next'), findsNothing);
  });

  testWidgets('every rung survives 200% text without overflowing',
      (tester) async {
    // Five rungs of criteria text in a narrow column is exactly where a
    // Row would overflow, and the rail taught me that lesson already.
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 900),
        textScaler: TextScaler.linear(2.0),
      ),
      child: host(3, size: const Size(360, 900)),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    for (final rung in rungs) {
      expect(find.text('Level ${rung.level} of 4'), findsOneWidget);
    }
  });
}
