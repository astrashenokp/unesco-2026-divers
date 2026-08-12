import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../motion.dart';
import '../tokens.dart';

enum PathNodeState { locked, available, completed }

/// One stop on the skill path.
///
/// Scroll-reveal is *not* handled here — wrap this in `RevealOnScroll`
/// instead, so the reveal stays a decoration that can be removed without
/// touching the node's meaning or hit target.
///
/// State is carried by icon, fill and an explicit localized label, never
/// by colour alone. The available node breathes gently so the eye can
/// find "where am I" without reading anything; that pulse is decoration
/// and stops entirely under reduced motion.
class PathNode extends StatefulWidget {
  const PathNode({
    super.key,
    required this.title,
    required this.state,
    required this.stateLabel,
    this.boosterDue = false,
    this.boosterLabel,
    this.heroTag,
    this.onTap,
  });

  final String title;
  final PathNodeState state;

  /// Localized "locked" / "available" / "completed", for the screen reader.
  final String stateLabel;
  final bool boosterDue;
  final String? boosterLabel;

  /// When set, the node flies into the destination screen's header.
  final Object? heroTag;
  final VoidCallback? onTap;

  @override
  State<PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<PathNode> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    if (widget.state == PathNodeState.available) _startPulse();
  }

  @override
  void didUpdateWidget(covariant PathNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PathNodeState.available && _ticker == null) {
      _startPulse();
    } else if (widget.state != PathNodeState.available) {
      _ticker?.dispose();
      _ticker = null;
    }
  }

  void _startPulse() {
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final (bg, fg, icon) = switch (widget.state) {
      PathNodeState.locked => (tokens.surfaceRaised, tokens.textMuted, Icons.lock_outline),
      PathNodeState.available => (tokens.action, Colors.white, Icons.explore_outlined),
      PathNodeState.completed => (tokens.evidencePrimary, Colors.white, Icons.check),
    };

    final semanticLabel = widget.boosterDue && widget.boosterLabel != null
        ? '${widget.title}, ${widget.stateLabel}, ${widget.boosterLabel}'
        : '${widget.title}, ${widget.stateLabel}';

    // A slow halo on the current stop, ~3s per breath.
    final pulse = (widget.state == PathNodeState.available && !reduceMotion)
        ? (math.sin(_t * (2 * math.pi / 3)) + 1) / 2
        : 0.0;

    Widget circle = Container(
      // 72dp clears the 44dp minimum comfortably, which matters most
      // where aim is least steady.
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: widget.boosterDue
            ? Border.all(color: tokens.evidenceSecondary, width: 3)
            : Border.all(color: tokens.textMuted.withValues(alpha: 0.2)),
        boxShadow: widget.state == PathNodeState.locked
            ? null
            : [
                BoxShadow(
                  color: bg.withValues(alpha: 0.32 + pulse * 0.22),
                  blurRadius: 12 + pulse * 12,
                  spreadRadius: pulse * 3,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Icon(icon, color: fg, size: 30),
    );

    if (widget.heroTag != null) {
      circle = Hero(
        tag: widget.heroTag!,
        // Keep it a circle for the whole flight; the default rectangular
        // placeholder makes it visibly square in mid-air.
        createRectTween: (begin, end) => MaterialRectCenterArcTween(begin: begin, end: end),
        child: Material(color: Colors.transparent, child: circle),
      );
    }

    // `onTap` belongs on the node that declares `button: true`. Without
    // it, ExcludeSemantics removes the InkWell's action and the node
    // announces as a button that does nothing when activated — which
    // made every mission unreachable without sight.
    return Semantics(
      button: widget.state != PathNodeState.locked,
      enabled: widget.state != PathNodeState.locked,
      label: semanticLabel,
      onTap: widget.state == PathNodeState.locked ? null : widget.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.state == PathNodeState.locked ? null : widget.onTap,
            customBorder: const CircleBorder(),
            child: AnimatedScale(
              scale: 1 + pulse * 0.02,
              duration: Motion.fast,
              child: circle,
            ),
          ),
        ),
      ),
    );
  }
}
