import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// The app's ground.
///
/// A flat single-colour fill reads as "unfinished page" at laptop width,
/// where there is far more background than content. This adds three
/// things that a plain fill lacks — a soft vertical wash, two very faint
/// colour blooms, and a fine grain — while staying quiet enough that text
/// contrast is unaffected.
///
/// Everything is drawn procedurally, so there is no image asset to ship,
/// scale, or lose. It is static: no ticker, no repaint, nothing competing
/// with the content for attention.
class LivingBackground extends StatelessWidget {
  const LivingBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BackgroundPainter(
                  base: tokens.surface,
                  bloomA: tokens.action,
                  bloomB: tokens.evidencePrimary,
                  grain: tokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({
    required this.base,
    required this.bloomA,
    required this.bloomB,
    required this.grain,
  });

  final Color base;
  final Color bloomA;
  final Color bloomB;
  final Color grain;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Vertical wash: very slightly warmer at the bottom, so the page has
    // a direction instead of sitting perfectly flat.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, Color.lerp(base, bloomA, 0.05)!],
        ).createShader(rect),
    );

    // Two soft blooms. Alpha is deliberately tiny — they should register
    // as "the page isn't flat", never as decoration you notice.
    void bloom(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    bloom(Offset(size.width * 0.16, size.height * 0.12), size.shortestSide * 0.7,
        bloomA, 0.07);
    bloom(Offset(size.width * 0.88, size.height * 0.82), size.shortestSide * 0.6,
        bloomB, 0.05);

    // Paper grain. A fixed seed keeps it identical between repaints, so
    // it never shimmers, and the dots stay under 3% opacity.
    final random = math.Random(7);
    final dot = Paint();
    final count = (size.width * size.height / 5200).clamp(0, 2400).toInt();
    for (var i = 0; i < count; i++) {
      dot.color = grain.withValues(alpha: 0.012 + random.nextDouble() * 0.016);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 1.1 + 0.35,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.base != base || old.bloomA != bloomA || old.bloomB != bloomB;
}
