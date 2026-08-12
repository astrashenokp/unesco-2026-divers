import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';

/// Lupa's behavioural state.
///
/// Never a verdict — only ever how the coach is relating to the learner.
/// There is deliberately no "wrong" or "correct" mood: the product does
/// not hand down judgements, and neither does its mascot.
enum LupaMood {
  idle,
  thinking,
  asking,
  encouraging,

  /// Something went wrong for the learner — a failed load, a lost
  /// connection. Concerned, never alarmed: this is not a hazard.
  concerned,
}

/// The Socratic-coach mascot: a creature whose face is a magnifying-glass
/// lens.
///
/// Drawn procedurally so there is no art asset to ship or lose. Tapping
/// it makes it hop and blink — small, pointless, and the sort of thing
/// that makes a character feel present rather than printed.
class Lupa extends StatefulWidget {
  const Lupa({
    super.key,
    this.mood = LupaMood.idle,
    this.size = 96,
    this.respondToTap = true,
    this.semanticLabel,
  });

  final LupaMood mood;
  final double size;

  /// Tapping triggers a hop. Disable where the mascot sits inside another
  /// tappable surface, so the two gestures don't compete.
  final bool respondToTap;

  /// Localized description of the current mood. The design system holds
  /// no strings, so callers supply it. When null the mascot is treated
  /// as decoration and hidden from assistive technology — silence is
  /// better than announcing English to a Ukrainian screen-reader user,
  /// which is what a hardcoded default did.
  final String? semanticLabel;

  @override
  State<Lupa> createState() => _LupaState();
}

class _LupaState extends State<Lupa> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  double _t = 0;
  final List<_Particle> _particles = [];
  LupaMood? _lastMood;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      setState(() {
        _t = elapsed.inMilliseconds / 1000.0;
        _stepParticles();
      });
    })..start();
  }

  @override
  void didUpdateWidget(covariant Lupa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == LupaMood.encouraging && oldWidget.mood != LupaMood.encouraging) {
      _burst();
    }
  }

  void _burst() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    final random = math.Random();
    for (var i = 0; i < 18; i++) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * 2.2;
      final speed = 0.55 + random.nextDouble() * 0.75;
      _particles.add(_Particle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        shape: i % 3,
      ));
    }
  }

  void _stepParticles() {
    if (_particles.isEmpty) return;
    for (final p in _particles) {
      p.position += p.velocity * 0.016 * 60;
      p.velocity = Offset(p.velocity.dx * 0.985, p.velocity.dy + 0.035);
      p.life -= 0.014;
      p.spin += 0.09;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void _onTap() {
    if (MediaQuery.of(context).disableAnimations) return;
    _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final t = reduceMotion ? 0.0 : _t;

    if (_lastMood != widget.mood) _lastMood = widget.mood;

    final art = AnimatedBuilder(
      animation: _hop,
      builder: (context, _) {
        // A single squash-and-stretch hop, driven only by taps.
        final hopT = _hop.value;
        final lift = math.sin(hopT * math.pi) * widget.size * 0.14;
        final squash = 1 - math.sin(hopT * math.pi) * 0.07;
        return Transform.translate(
          offset: Offset(0, -lift),
          child: Transform.scale(scaleX: 1 / squash, scaleY: squash, child: _paint(t, tokens)),
        );
      },
    );

    final body = ExcludeSemantics(
      child: widget.respondToTap
          ? GestureDetector(onTap: _onTap, behavior: HitTestBehavior.opaque, child: art)
          : art,
    );

    return widget.semanticLabel == null
        ? body
        : Semantics(label: widget.semanticLabel, child: body);
  }

  Widget _paint(double t, EvidenceGymTokens tokens) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _LupaPainter(
            t: t,
            mood: widget.mood,
            body: tokens.action,
            rim: tokens.evidenceSecondary,
            spark: tokens.evidencePrimary,
            // Shading is a property of Lupa, not of the page she is on.
            // This was `tokens.textPrimary`, which is near-white on the
            // dark theme — it turned her contact shadow into a glow and
            // flattened the shading on her body by lerping toward white
            // instead of away from it. A shadow darkens in every theme,
            // so it takes the light theme's ink in both.
            shadow: EvidenceGymTokens.standard.textPrimary,
            particles: _particles,
            particleColors: [tokens.action, tokens.evidenceSecondary, tokens.evidencePrimary],
          ),
        ),
      );
}

class _Particle {
  _Particle({required this.velocity, required this.shape});
  Offset position = Offset.zero;
  Offset velocity;
  double life = 1;
  double spin = 0;
  final int shape;
}

class _LupaPainter extends CustomPainter {
  _LupaPainter({
    required this.t,
    required this.mood,
    required this.body,
    required this.rim,
    required this.spark,
    required this.shadow,
    required this.particles,
    required this.particleColors,
  });

  final double t;
  final LupaMood mood;
  final Color body;
  final Color rim;
  final Color spark;
  final Color shadow;
  final List<_Particle> particles;
  final List<Color> particleColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final bob = switch (mood) {
      LupaMood.idle => math.sin(t * (2 * math.pi / 2.4)) * (r * 0.055),
      LupaMood.encouraging => -math.max(0, math.sin(t * 5.5)) * (r * 0.16),
      LupaMood.concerned => math.sin(t * 1.4) * (r * 0.02),
      _ => 0.0,
    };
    final lens = center.translate(0, -r * 0.04 + bob);

    // Contact shadow: without it the mascot floats rather than sits.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.86),
        width: r * (1.05 - bob / (r * 4)),
        height: r * 0.16,
      ),
      Paint()..color = shadow.withValues(alpha: 0.13),
    );

    // Handle, tucked behind the lens.
    final tilt = switch (mood) {
      LupaMood.thinking => math.sin(t * 2.6) * 0.16,
      LupaMood.concerned => 0.24,
      _ => 0.0,
    };
    canvas.drawLine(
      lens + Offset.fromDirection(math.pi / 4 + tilt, r * 0.60),
      lens + Offset.fromDirection(math.pi / 4 + tilt, r * 1.06),
      Paint()
        ..color = Color.lerp(body, shadow, 0.25)!
        ..strokeWidth = r * 0.27
        ..strokeCap = StrokeCap.round,
    );

    // Rim, then glass.
    canvas.drawCircle(lens, r * 0.64, Paint()..color = rim);
    canvas.drawCircle(lens, r * 0.55, Paint()..color = Color.lerp(rim, shadow, 0.18)!);
    canvas.drawCircle(lens, r * 0.50, Paint()..color = body);

    // Eye. Blinks about every four seconds; squints when concerned.
    final blink = (t % 4.0) > 3.86;
    final openness = blink ? 0.12 : (mood == LupaMood.concerned ? 0.62 : 1.0);
    canvas.save();
    canvas.translate(lens.dx, lens.dy);
    canvas.scale(1, openness);
    canvas.drawCircle(Offset.zero, r * 0.23, Paint()..color = Colors.white);
    canvas.restore();

    if (!blink) {
      // The pupil drifts while thinking — it is looking around.
      final drift = mood == LupaMood.thinking
          ? Offset(math.sin(t * 1.9) * r * 0.07, math.cos(t * 1.5) * r * 0.04)
          : Offset.zero;
      canvas.drawCircle(lens + drift, r * 0.105, Paint()..color = body);
      canvas.drawCircle(
        lens + drift + Offset(-r * 0.04, -r * 0.04),
        r * 0.032,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // Glass highlight: a soft sweep across the upper-left of the lens.
    final highlight = Path()
      ..addArc(
        Rect.fromCircle(center: lens, radius: r * 0.44),
        math.pi * 1.05,
        math.pi * 0.55,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round,
    );

    if (mood == LupaMood.thinking) {
      for (var i = 0; i < 3; i++) {
        final angle = t * 3.4 + (i * 2 * math.pi / 3);
        canvas.drawCircle(
          lens + Offset.fromDirection(angle, r * 0.92) + Offset(0, -r * 0.1),
          r * 0.055,
          Paint()..color = spark.withValues(alpha: 0.85),
        );
      }
    }

    if (mood == LupaMood.asking) {
      final pulse = 0.6 + 0.4 * math.sin(t * 7).abs();
      canvas.drawCircle(
        lens + Offset(r * 0.56, -r * 0.74),
        r * 0.13 * pulse,
        Paint()..color = spark,
      );
    }

    // Celebration particles, in the product's own palette — never the
    // gold-and-green of a "correct answer".
    for (final p in particles) {
      final paint = Paint()
        ..color = particleColors[p.shape % particleColors.length]
            .withValues(alpha: p.life.clamp(0.0, 1.0));
      final at = lens + p.position * r * 0.9;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(p.spin);
      final s = r * 0.06 * (0.6 + p.life * 0.6);
      if (p.shape == 0) {
        canvas.drawCircle(Offset.zero, s, paint);
      } else if (p.shape == 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 0.8), paint);
      } else {
        canvas.drawLine(Offset(-s, 0), Offset(s, 0), paint..strokeWidth = s * 0.7);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LupaPainter old) => true;
}
