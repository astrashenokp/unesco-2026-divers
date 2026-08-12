import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// The dashed connector drawn between two path nodes.
///
/// Without it the nodes read as three unrelated buttons floating in
/// space, which is how the first build looked. The curve gives the map
/// its direction and makes "this comes after that" visible rather than
/// implied by vertical order alone.
///
/// [reached] darkens the segment once the learner has got this far, so
/// progress is legible from the shape of the trail itself. It is a
/// secondary cue only — node state is still carried by icon and label.
class PathTrail extends StatelessWidget {
  const PathTrail({
    super.key,
    required this.fromLeft,
    required this.reached,
    this.height = 64,
  });

  /// Whether the previous node sat on the left; the curve bows the other
  /// way so the trail weaves instead of zig-zagging sharply.
  final bool fromLeft;
  final bool reached;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrailPainter(
            fromLeft: fromLeft,
            color: reached
                ? tokens.evidencePrimary.withValues(alpha: 0.55)
                : tokens.textMuted.withValues(alpha: 0.28),
            dashOn: reached ? 10 : 6,
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.fromLeft, required this.color, required this.dashOn});

  final bool fromLeft;
  final Color color;
  final double dashOn;

  @override
  void paint(Canvas canvas, Size size) {
    final startX = fromLeft ? size.width * 0.30 : size.width * 0.70;
    final endX = fromLeft ? size.width * 0.70 : size.width * 0.30;

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(
        startX, size.height * 0.45,
        endX, size.height * 0.55,
        endX, size.height,
      );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Walk the curve and stroke alternating dashes. Using PathMetrics
    // rather than a dash pattern keeps the spacing even around the bend,
    // where a naive dash would bunch up.
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashOn, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.fromLeft != fromLeft || old.color != color || old.dashOn != dashOn;
}
