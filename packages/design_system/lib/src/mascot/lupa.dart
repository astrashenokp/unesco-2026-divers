import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';

/// Lupa's behavioral state. Never a verdict — only ever "how the coach
/// is currently relating to the learner." See MASCOT_AND_VISUAL_LANGUAGE.md.
enum LupaMood { idle, thinking, asking, encouraging }

/// The Socratic-coach mascot: a friendly creature whose face is a
/// magnifying-glass lens. Procedurally drawn with [CustomPainter] so it
/// renders correctly with no external art asset to go missing.
class Lupa extends StatefulWidget {
  const Lupa({super.key, this.mood = LupaMood.idle, this.size = 96});

  final LupaMood mood;
  final double size;

  @override
  State<Lupa> createState() => _LupaState();
}

class _LupaState extends State<Lupa> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
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
    final t = reduceMotion ? 0.0 : _t;

    return Semantics(
      label: switch (widget.mood) {
        LupaMood.idle => 'Lupa, your Socratic coach',
        LupaMood.thinking => 'Lupa is thinking',
        LupaMood.asking => 'Lupa is asking a question',
        LupaMood.encouraging => 'Lupa is celebrating your investigation',
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _LupaPainter(
            t: t,
            mood: widget.mood,
            bodyColor: tokens.action,
            lensRim: tokens.evidenceSecondary,
            sparkColor: tokens.evidencePrimary,
          ),
        ),
      ),
    );
  }
}

class _LupaPainter extends CustomPainter {
  _LupaPainter({
    required this.t,
    required this.mood,
    required this.bodyColor,
    required this.lensRim,
    required this.sparkColor,
  });

  final double t;
  final LupaMood mood;
  final Color bodyColor;
  final Color lensRim;
  final Color sparkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    // Idle bob: gentle vertical drift, ~2.4s period.
    final bob = mood == LupaMood.idle
        ? math.sin(t * (2 * math.pi / 2.4)) * (r * 0.06)
        : mood == LupaMood.encouraging
            ? -math.max(0, math.sin(t * 6)) * (r * 0.18)
            : 0.0;
    final lensCenter = center.translate(0, -r * 0.05 + bob);

    // Handle-tail.
    final handlePaint = Paint()
      ..color = bodyColor
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round;
    final handleTilt = mood == LupaMood.thinking ? math.sin(t * 3) * 0.15 : 0.0;
    final handleEnd = lensCenter +
        Offset.fromDirection(math.pi / 4 + handleTilt, r * 1.05);
    canvas.drawLine(
      lensCenter + Offset.fromDirection(math.pi / 4 + handleTilt, r * 0.62),
      handleEnd,
      handlePaint,
    );

    // Lens rim (body).
    final rimPaint = Paint()..color = lensRim;
    canvas.drawCircle(lensCenter, r * 0.62, rimPaint);

    // Lens glass.
    final glassPaint = Paint()..color = bodyColor.withValues(alpha: 0.92);
    canvas.drawCircle(lensCenter, r * 0.5, glassPaint);

    // Blink: iris contracts briefly once every ~4s.
    final blinkPhase = (t % 4.0);
    final blinking = blinkPhase > 3.85 && blinkPhase < 4.0;
    final eyeOpen = blinking ? 0.15 : 1.0;

    final eyePaint = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(lensCenter.dx, lensCenter.dy);
    canvas.scale(1, eyeOpen);
    canvas.drawCircle(Offset.zero, r * 0.22, eyePaint);
    canvas.restore();

    final pupilPaint = Paint()..color = bodyColor;
    if (!blinking) {
      canvas.drawCircle(lensCenter, r * 0.1, pupilPaint);
    }

    // Thinking dots.
    if (mood == LupaMood.thinking) {
      final dotPaint = Paint()..color = sparkColor;
      for (var i = 0; i < 3; i++) {
        final angle = t * 4 + (i * 2 * math.pi / 3);
        final dotCenter =
            lensCenter + Offset.fromDirection(angle, r * 0.95) + const Offset(0, -8);
        canvas.drawCircle(dotCenter, r * 0.06, dotPaint);
      }
    }

    // Asking spark.
    if (mood == LupaMood.asking) {
      final sparkPaint = Paint()..color = sparkColor;
      final sparkPulse = 0.6 + 0.4 * math.sin(t * 8).abs();
      canvas.drawCircle(
        lensCenter + Offset(r * 0.55, -r * 0.75),
        r * 0.14 * sparkPulse,
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LupaPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mood != mood;
}
