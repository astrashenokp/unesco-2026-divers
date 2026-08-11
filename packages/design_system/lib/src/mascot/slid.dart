import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';

/// Slid ("слід" — trace) is the provenance companion: a small trail of
/// footprints that walks along beside evidence, animating the
/// "follow the trail" metaphor from `DESIGN_SYSTEM.md`.
///
/// Deliberately *not* a character with a face — Lupa is the only voice in
/// the product. Slid is a motif, so it never looks like a second opinion.
class Slid extends StatefulWidget {
  const Slid({
    super.key,
    this.steps = 4,
    this.width = 120,
    this.height = 32,
    this.active = true,
  });

  /// How many footprints in the trail.
  final int steps;
  final double width;
  final double height;

  /// When false the full trail is shown at rest (also the reduced-motion
  /// and screen-reader appearance) — the end state is identical, so no
  /// information is carried by the animation.
  final bool active;

  @override
  State<Slid> createState() => _SlidState();
}

class _SlidState extends State<Slid> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animate = widget.active && !reduceMotion;

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _SlidPainter(
            t: animate ? _t : double.infinity,
            steps: widget.steps,
            color: tokens.evidenceSecondary,
          ),
        ),
      ),
    );
  }
}

class _SlidPainter extends CustomPainter {
  _SlidPainter({required this.t, required this.steps, required this.color});

  /// Elapsed seconds, or [double.infinity] to draw the settled trail.
  final double t;
  final int steps;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final settled = !t.isFinite;
    final spacing = size.width / steps;
    final footWidth = spacing * 0.34;
    final footHeight = size.height * 0.34;

    for (var i = 0; i < steps; i++) {
      // Each print fades in on its own beat, then the trail loops.
      final double opacity;
      if (settled) {
        opacity = 0.35 + 0.65 * (i / math.max(1, steps - 1));
      } else {
        final phase = (t * 1.6 - i * 0.28) % 2.6;
        opacity = phase < 0 || phase > 1.6
            ? 0.15
            : 0.15 + 0.85 * math.sin((phase / 1.6) * math.pi);
      }

      final paint = Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0));

      // Alternate above/below the centre line so it reads as walking.
      final dy = size.height / 2 + (i.isEven ? -footHeight * 0.5 : footHeight * 0.5);
      final center = Offset(spacing * (i + 0.5), dy);

      canvas.drawOval(
        Rect.fromCenter(center: center, width: footWidth, height: footHeight),
        paint,
      );
      // Toe dot, so the print reads as directional rather than a blob.
      canvas.drawCircle(
        center.translate(footWidth * 0.62, -footHeight * 0.16),
        footHeight * 0.16,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SlidPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.steps != steps || oldDelegate.color != color;
}
