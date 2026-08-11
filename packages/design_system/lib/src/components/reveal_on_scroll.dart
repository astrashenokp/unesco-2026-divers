import 'package:flutter/material.dart';

import '../tokens.dart';

/// Fades and lifts [child] into place as it scrolls into view, with a
/// small spring overshoot — the smooth downward-scroll feel described in
/// `MASCOT_AND_VISUAL_LANGUAGE.md` ("Scroll reveal").
///
/// Reveals once and stays revealed: re-hiding content the learner has
/// already read is disorienting, and it would fight the screen reader.
/// Under reduced motion (or if the position can't be measured) the child
/// is simply visible immediately, so nothing is ever gated on animation.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.delayIndex = 0,
    this.offset = 24,
  });

  final Widget child;

  /// Staggers siblings; index 0 leads, each following item trails ~40ms.
  final int delayIndex;

  /// How far below its resting place the child starts, in logical pixels.
  final double offset;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    // If we're already on screen at first layout, reveal without waiting
    // for a scroll event that may never come (short lists, big windows).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  void _maybeReveal() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final topY = box.localToGlobal(Offset.zero).dy;
    if (topY < viewportHeight * 0.92) {
      setState(() => _revealed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final shown = _revealed || reduceMotion;

    return NotificationListener<ScrollNotification>(
      // Returning false lets the notification keep bubbling to any
      // ancestor listeners — we're only observing.
      onNotification: (_) {
        _maybeReveal();
        return false;
      },
      child: AnimatedSlide(
        offset: shown ? Offset.zero : Offset(0, widget.offset / 100),
        duration: reduceMotion ? Duration.zero : tokens.motionSlow,
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: reduceMotion
              ? Duration.zero
              : tokens.motionSlow + Duration(milliseconds: 40 * widget.delayIndex),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
