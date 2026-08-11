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
    // Reveal after the first frame if we're already on screen, and again
    // shortly after as a safety net: with a staggered list the later
    // items lay out over several frames, and a missed first check used to
    // leave them permanently invisible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeReveal();
      Future<void>.delayed(const Duration(milliseconds: 120), _maybeReveal);
    });
  }

  void _maybeReveal() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    // No render object yet, or a zero-size box: reveal rather than wait.
    // A page short enough not to scroll produces no scroll notifications,
    // so anything still hidden here would stay hidden forever — which is
    // exactly what the first build did on a three-node path.
    if (box == null || !box.hasSize) {
      setState(() => _revealed = true);
      return;
    }
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
