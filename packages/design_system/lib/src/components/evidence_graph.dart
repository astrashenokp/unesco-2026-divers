import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// How a piece of evidence relates to the claim.
enum EdgeRelation {
  /// Current sources point the same way as the claim.
  supports,

  /// Current sources point against it.
  contradicts,

  /// Relevant, but it does not settle the question either way.
  qualifies,
}

@immutable
class EvidenceNode {
  const EvidenceNode({
    required this.id,
    required this.label,
    required this.relation,
    required this.relationLabel,
  });

  final String id;
  final String label;
  final EdgeRelation relation;

  /// Localized description of [relation], spoken to a screen reader and
  /// printed under the node. The relation is never colour-only.
  final String relationLabel;
}

/// The claim at the centre, with the evidence gathered around it.
///
/// `DESIGN_SYSTEM.md` asks for evidence graph nodes and edges, and this
/// is the component the product's whole argument rests on: an
/// investigation is a set of *relationships* between a claim and what
/// was found, not a list of results. A list quietly teaches that
/// evidence accumulates into a verdict; a graph shows that pieces can
/// pull in different directions at once.
///
/// Drawn rather than laid out in widgets because the edges matter as
/// much as the nodes. Every node is also rendered as a labelled row
/// underneath, so nothing here is only available visually.
class EvidenceGraph extends StatefulWidget {
  const EvidenceGraph({
    super.key,
    required this.claimLabel,
    required this.nodes,
    this.height = 260,
  });

  /// Short restatement of the claim under investigation.
  final String claimLabel;
  final List<EvidenceNode> nodes;
  final double height;

  @override
  State<EvidenceGraph> createState() => _EvidenceGraphState();
}

class _EvidenceGraphState extends State<EvidenceGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: Motion.celebrate,
  )..forward();

  @override
  void didUpdateWidget(covariant EvidenceGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new piece of evidence draws its edge in rather than appearing.
    if (widget.nodes.length != oldWidget.nodes.length) _grow.forward(from: 0.7);
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  Color _colorFor(EdgeRelation r, EvidenceGymTokens t) => switch (r) {
        EdgeRelation.supports => t.supported,
        EdgeRelation.contradicts => t.contradicted,
        EdgeRelation.qualifies => t.misleading,
      };

  IconData _iconFor(EdgeRelation r) => switch (r) {
        EdgeRelation.supports => Icons.check_circle_outline,
        EdgeRelation.contradicts => Icons.change_circle_outlined,
        EdgeRelation.qualifies => Icons.crop_free,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The picture is decoration. Everything it shows is repeated as
        // text below, so a screen-reader user loses nothing.
        ExcludeSemantics(
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _grow,
              builder: (context, _) => CustomPaint(
                painter: _GraphPainter(
                  progress: reduceMotion ? 1 : Curves.easeOutCubic.transform(_grow.value),
                  nodes: widget.nodes,
                  colorFor: (r) => _colorFor(r, tokens),
                  claimColor: tokens.action,
                  surface: tokens.surfaceRaised,
                  outline: tokens.textMuted,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.space(1)),
        Semantics(
          label: widget.claimLabel,
          child: Text(
            widget.claimLabel,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: tokens.space(1)),
        for (final node in widget.nodes)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.space(0.5)),
            child: Semantics(
              label: '${node.label}. ${node.relationLabel}',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_iconFor(node.relation),
                        size: 18, color: _colorFor(node.relation, tokens)),
                    SizedBox(width: tokens.space(1)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.label,
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text(node.relationLabel,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.progress,
    required this.nodes,
    required this.colorFor,
    required this.claimColor,
    required this.surface,
    required this.outline,
  });

  final double progress;
  final List<EvidenceNode> nodes;
  final Color Function(EdgeRelation) colorFor;
  final Color claimColor;
  final Color surface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;

    for (var i = 0; i < nodes.length; i++) {
      // Start at the top and go clockwise, so the order on screen
      // matches the order the evidence was gathered in.
      final angle = -math.pi / 2 + (i * 2 * math.pi / nodes.length);
      final at = centre + Offset.fromDirection(angle, radius);
      final colour = colorFor(nodes[i].relation);

      // Edges draw outward from the claim as the graph grows.
      final tip = Offset.lerp(centre, at, progress.clamp(0.0, 1.0))!;
      canvas.drawLine(
        centre,
        tip,
        Paint()
          ..color = colour.withValues(alpha: 0.55)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      final r = 13.0 * progress;
      canvas.drawCircle(tip, r, Paint()..color = surface);
      canvas.drawCircle(
        tip,
        r,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // The claim sits on top, so an edge never crosses it.
    canvas.drawCircle(centre, 26, Paint()..color = claimColor);
    canvas.drawCircle(
      centre,
      26,
      Paint()
        ..color = surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.progress != progress || old.nodes.length != nodes.length;
}
