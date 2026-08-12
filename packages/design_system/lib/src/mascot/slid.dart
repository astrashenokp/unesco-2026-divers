import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';

/// Slid — "слід", a trace.
///
/// A trail of footprints that writes itself onward as the learner
/// gathers evidence. Deliberately not a character with a face: Lupa is
/// the only voice in the product, and a second face would read as a
/// second opinion.
///
/// [steps] is how many prints the trail can hold; [reached] is how many
/// have been earned. Prints beyond [reached] stay faint, so the trail
/// shows progress by shape rather than by colour alone.
class Slid extends StatefulWidget {
  const Slid({
    super.key,
    this.steps = 4,
    this.reached,
    this.width = 120,
    this.height = 32,
    this.active = true,
  });

  final int steps;

  /// Defaults to all of them — a decorative full trail.
  final int? reached;
  final double width;
  final double height;

  /// When false the trail rests at its end state, which is also what
  /// reduced motion and screen readers get.
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
            reached: widget.reached ?? widget.steps,
            color: tokens.evidenceSecondary,
            muted: tokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SlidPainter extends CustomPainter {
  _SlidPainter({
    required this.t,
    required this.steps,
    required this.reached,
    required this.color,
    required this.muted,
  });

  /// Elapsed seconds, or [double.infinity] for the settled trail.
  final double t;
  final int steps;
  final int reached;
  final Color color;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final settled = !t.isFinite;
    final spacing = size.width / steps;
    final footWidth = spacing * 0.34;
    final footHeight = size.height * 0.34;

    for (var i = 0; i < steps; i++) {
      final earned = i < reached;

      final double opacity;
      if (!earned) {
        // Not yet walked: a faint outline of where the trail could go.
        opacity = 0.13;
      } else if (settled) {
        opacity = 0.45 + 0.55 * (i / math.max(1, steps - 1));
      } else {
        // Each print pulses on its own beat, so the trail reads as
        // moving forward rather than blinking as a block.
        final phase = (t * 1.6 - i * 0.28) % 2.6;
        opacity = phase < 0 || phase > 1.6
            ? 0.2
            : 0.2 + 0.8 * math.sin((phase / 1.6) * math.pi);
      }

      final paint = Paint()
        ..color = (earned ? color : muted).withValues(alpha: opacity.clamp(0.0, 1.0));

      final dy = size.height / 2 + (i.isEven ? -footHeight * 0.5 : footHeight * 0.5);
      final center = Offset(spacing * (i + 0.5), dy);

      canvas.drawOval(
        Rect.fromCenter(center: center, width: footWidth, height: footHeight),
        paint,
      );
      // Toe dot: makes the print directional rather than a blob.
      canvas.drawCircle(
        center.translate(footWidth * 0.62, -footHeight * 0.16),
        footHeight * 0.16,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SlidPainter old) =>
      old.t != t || old.steps != steps || old.reached != reached;
}
