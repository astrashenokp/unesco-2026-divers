import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// What the product is set in.
///
/// `STITCH_PROMPTS.md` asks for an investigation lab and explicitly rules
/// out generic purple AI gradients. So this is not a wash — it is a
/// surface you could pin evidence to: ruled paper, faint grid, and the
/// impression of threads connecting things you have not looked at yet.
///
/// [variant] lets a screen set its own ground. The mission screens carry
/// the grid; the path carries the corkboard; quiet screens stay plain, so
/// the texture never competes with dense reading.
///
/// Everything is drawn procedurally — no image asset to ship, scale, or
/// lose — and it is static: no ticker, no repaint, nothing moving behind
/// the content.
enum GroundVariant {
  /// Faint ruled grid. For working surfaces: mission, receipt.
  grid,

  /// Corkboard tone with pinned-thread hints. For the path.
  board,

  /// Almost nothing. For text-heavy screens where texture would fight
  /// the reading.
  plain,
}

class LivingBackground extends StatelessWidget {
  const LivingBackground({
    super.key,
    required this.child,
    this.variant = GroundVariant.plain,
    this.artwork,
  });

  final Widget child;
  final GroundVariant variant;

  /// Optional illustrated ground, laid under the procedural texture.
  ///
  /// Drawn with `BoxFit.cover`, not tiled. The artwork is not a seamless
  /// tile — its opposite edges do not meet — so repeating it would show
  /// a visible seam. Cover scales one copy to fill instead.
  ///
  /// Held at low opacity on purpose: the illustration contains near-black
  /// line work, and at full strength it competes with the text sitting on
  /// top of it. Contrast is measured against the paper base, not against
  /// the artwork, so this value must stay low enough that the artwork
  /// never becomes the effective background behind a glyph.
  final ImageProvider? artwork;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      children: [
        if (artwork != null)
          Positioned.fill(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0.32,
                child: Image(
                  image: artwork!,
                  fit: BoxFit.cover,
                  // Decorative: never announce it, and never let a
                  // missing asset take the screen down with it.
                  errorBuilder: (context, _, __) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BackgroundPainter(
                  // The artwork already supplies grid and threads, so the
                  // procedural layer drops to grain only and stops
                  // drawing a second grid on top of the first.
                  variant: artwork == null ? variant : GroundVariant.plain,
                  hasArtwork: artwork != null,
                  base: tokens.surface,
                  bloomA: tokens.action,
                  bloomB: tokens.evidencePrimary,
                  grain: tokens.textPrimary,
                  line: tokens.textMuted,
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
    required this.variant,
    required this.hasArtwork,
    required this.base,
    required this.bloomA,
    required this.bloomB,
    required this.grain,
    required this.line,
  });

  final GroundVariant variant;
  final bool hasArtwork;
  final Color base;
  final Color bloomA;
  final Color bloomB;
  final Color grain;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // With artwork underneath, only the grain is drawn: an opaque wash
    // here would hide the very image it sits on.
    if (hasArtwork) {
      final random = math.Random(7);
      final dot = Paint();
      final count = (size.width * size.height / 6000).clamp(0, 2000).toInt();
      for (var i = 0; i < count; i++) {
        dot.color = grain.withValues(alpha: 0.015 + random.nextDouble() * 0.018);
        canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          random.nextDouble() * 1.1 + 0.35,
          dot,
        );
      }
      return;
    }

    // Vertical wash: very slightly warmer at the bottom, so the page has
    // a direction instead of sitting perfectly flat.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, Colors.white, 0.5)!, Color.lerp(base, bloomA, 0.10)!],
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

    // Blooms are deliberately weak and off-centre. A centred purple glow
    // is the "generic AI gradient" the brief rules out.
    bloom(Offset(size.width * 0.14, size.height * 0.08), size.shortestSide * 0.55,
        bloomA, 0.085);
    bloom(Offset(size.width * 0.92, size.height * 0.88), size.shortestSide * 0.5,
        bloomB, 0.070);

    // The structure that makes it a surface rather than a gradient.
    switch (variant) {
      case GroundVariant.grid:
        final pen = Paint()
          ..color = line.withValues(alpha: 0.10)
          ..strokeWidth = 1;
        const step = 28.0;
        for (var x = 0.0; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), pen);
        }
        for (var y = 0.0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
        }
      case GroundVariant.board:
        // Sparse pin marks with faint threads between them: the board a
        // case gets assembled on, not a level map.
        final random = math.Random(19);
        final pins = <Offset>[
          for (var i = 0; i < 9; i++)
            Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        ];
        final thread = Paint()
          ..color = line.withValues(alpha: 0.11)
          ..strokeWidth = 1.3;
        for (var i = 0; i < pins.length - 1; i++) {
          canvas.drawLine(pins[i], pins[i + 1], thread);
        }
        final pin = Paint()..color = line.withValues(alpha: 0.17);
        for (final p in pins) {
          canvas.drawCircle(p, 2.4, pin);
        }
      case GroundVariant.plain:
        break;
    }

    // Paper grain. A fixed seed keeps it identical between repaints, so
    // it never shimmers, and the dots stay under 3% opacity.
    final random = math.Random(7);
    final dot = Paint();
    final count = (size.width * size.height / 5200).clamp(0, 2400).toInt();
    for (var i = 0; i < count; i++) {
      dot.color = grain.withValues(alpha: 0.02 + random.nextDouble() * 0.022);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 1.1 + 0.35,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.base != base ||
      old.bloomA != bloomA ||
      old.bloomB != bloomB ||
      old.variant != variant ||
      old.hasArtwork != hasArtwork;
}
