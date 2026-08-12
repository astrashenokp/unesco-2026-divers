import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: deprecated_member_use
// SemanticsOwner.performAction is how assistive technology activates a
// control. flutter_test exposes no non-deprecated route to it, and
// tapping pixels would not prove the semantics node carries the action —
// which is the entire point of these tests.

/// A control that announces a role but carries no action is worse than
/// an unlabelled one: a screen reader tells the user it is a button, and
/// activating it does nothing. Three components shipped that way — the
/// pattern was `Semantics(button: true, child: ExcludeSemantics(InkWell))`,
/// where ExcludeSemantics deletes the action the wrapper never declared.
///
/// These tests activate each control through the semantics tree, the way
/// assistive technology does, rather than tapping the pixels.
Widget _host(Widget child) => MaterialApp(
      theme: buildEvidenceGymTheme(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('PathNode can be activated through the semantics tree',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PathNode(
      title: 'The flood photo',
      state: PathNodeState.available,
      stateLabel: 'available',
      onTap: () => taps++,
    )));
    await tester.pump();

    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.byType(PathNode));
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(taps, 1, reason: 'announced as a button, so it must act like one');
    handle.dispose();
  });

  testWidgets('a locked PathNode offers no action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PathNode(
      title: 'Locked',
      state: PathNodeState.locked,
      stateLabel: 'locked',
      onTap: () => taps++,
    )));
    await tester.pump();

    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.byType(PathNode));
    expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
    expect(taps, 0);
    handle.dispose();
  });

  testWidgets('PropTile can be activated, even mid-entrance', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PropTile(
      prop: EvidenceProp.source,
      label: 'Check the source',
      semanticLabel: 'Check the source',
      // A late stagger index: the tile is still at zero opacity here, and
      // an inner Semantics node would have been dropped from the tree.
      delayIndex: 4,
      onTap: () => taps++,
    )));
    await tester.pump();

    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.byType(PropTile));
    expect(node.label, 'Check the source');
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('every interactive component is reachable by keyboard',
      (tester) async {
    // A web build makes this non-optional. PropTile was built on a
    // GestureDetector, which is not focusable — so Tab skipped every
    // evidence check, and since a conclusion needs at least one, the
    // mission could not be completed without a pointer.
    var taps = 0;
    await tester.pumpWidget(_host(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PropTile(
          prop: EvidenceProp.source,
          label: 'Check the source',
          semanticLabel: 'Check the source',
          onTap: () => taps++,
        ),
      ],
    )));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(taps, 1, reason: 'Tab then Enter must activate an evidence check');
  });

  testWidgets('ConfidenceSlider can be changed, not only read',
      (tester) async {
    var value = 50;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(ConfidenceSlider(
          value: value,
          label: 'How confident are you?',
          bandLabel: 'Somewhat sure',
          describeValue: (v) => '$v percent',
          onChanged: (v) => setState(() => value = v),
        )),
      ),
    );
    await tester.pump();

    final handle = tester.ensureSemantics();
    // Asserted by behaviour rather than by flag. Whether the merged node
    // reports isSlider depends on how Flutter folds the surrounding
    // Column; what actually matters to a screen-reader user is that
    // increase and decrease move the value.
    // Found through the Slider itself: the label appears twice on screen
    // (as the question and inside the semantics node), so searching by
    // label is ambiguous. getSemantics walks up from the excluded Slider
    // to the annotating node, which is the one under test.
    final node = tester.getSemantics(find.byType(Slider));

    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(value, greaterThan(50), reason: 'a slider that cannot be moved is not a slider');

    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.decrease);
    await tester.pump();
    expect(value, 50);
    handle.dispose();
  });

  testWidgets(
      'unlocking a node is announced, and still announced under reduce motion',
      (tester) async {
    // The unlock animation is the whole of the news for a sighted
    // learner. Without an announcement the path silently grows a step
    // that a screen reader user never hears about, because nothing draws
    // attention to a node they are not focused on.
    //
    // Both cases run here because the tempting implementation guards the
    // announcement behind the same check as the animation, and then
    // reduced motion — a request for less movement — silently becomes a
    // request for less information.
    for (final reduceMotion in [false, true]) {
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (message) async {
          final data = message as Map<dynamic, dynamic>;
          if (data['type'] == 'announce') {
            announcements.add((data['data'] as Map)['message'] as String);
          }
          return null;
        },
      );

      Widget host(PathNodeState state) => MaterialApp(
            theme: buildEvidenceGymTheme(),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Scaffold(
                body: Center(
                  child: PathNode(
                    title: 'Where and when',
                    state: state,
                    stateLabel: 'locked',
                    unlockAnnouncement: 'Where and when is now open',
                  ),
                ),
              ),
            ),
          );

      await tester.pumpWidget(host(PathNodeState.locked));
      expect(announcements, isEmpty,
          reason: 'a node that starts locked has not just unlocked');

      await tester.pumpWidget(host(PathNodeState.available));
      await tester.pump();

      expect(
        announcements,
        contains('Where and when is now open'),
        reason: reduceMotion
            ? 'reduce motion dropped the announcement along with the animation'
            : 'unlocking was never announced',
      );

      // Not pumpAndSettle: an available node breathes on an endless
      // ticker by design, so nothing ever settles. Unmounting disposes
      // it, which is what the next loop iteration needs anyway.
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
    }
  });
}
