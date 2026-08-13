import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// One kind of disinformation, offered as a place to work.
///
/// Carries more than a name on purpose. A grid of four labels is a menu;
/// what a learner actually needs in order to choose is what this subject
/// looks like when they meet it, how much of it they have already done,
/// and whether there is anything waiting. That is three facts, and they
/// fit.
///
/// Progress is a ring rather than a bar because four bars stacked in a
/// grid read as a single chart being compared, which invites the learner
/// to treat the arenas as a ranking. They are not ranked; they are
/// different rooms.
class ArenaCard extends StatefulWidget {
  const ArenaCard({
    super.key,
    required this.title,
    required this.example,
    required this.icon,
    required this.tint,
    required this.completed,
    required this.total,
    required this.progressLabel,
    required this.onTap,
    this.dueCount = 0,
    this.dueLabel,
  });

  final String title;

  /// One concrete thing this arena contains, in the learner's words —
  /// "a flood photo from another year", not "media provenance". The
  /// abstract name is what they are choosing between; the example is
  /// what tells them which one they mean.
  final String example;

  final IconData icon;
  final Color tint;
  final int completed;
  final int total;

  /// Localized "2 of 3 done", spoken and printed. The ring is never the
  /// only carrier of this.
  final String progressLabel;

  /// Missions in this arena whose skills are due for practice.
  final int dueCount;
  final String? dueLabel;

  final VoidCallback onTap;

  @override
  State<ArenaCard> createState() => _ArenaCardState();
}

class _ArenaCardState extends State<ArenaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final done = widget.total == 0 ? 0.0 : widget.completed / widget.total;

    return Semantics(
      button: true,
      onTap: widget.onTap,
      label: [
        widget.title,
        widget.example,
        widget.progressLabel,
        if (widget.dueCount > 0 && widget.dueLabel != null) widget.dueLabel,
      ].join('. '),
      child: ExcludeSemantics(
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(tokens.space(2.5)),
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curveStandard,
                padding: EdgeInsets.all(tokens.space(2)),
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(tokens.space(2.5)),
                  border: Border.all(
                    color: _hovered
                        ? widget.tint
                        : widget.tint.withValues(alpha: 0.4),
                    width: _hovered ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(tokens.space(1.25)),
                          decoration: BoxDecoration(
                            color: widget.tint.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(tokens.space(1.5)),
                          ),
                          child: Icon(widget.icon, color: widget.tint, size: 24),
                        ),
                        SizedBox(width: tokens.space(1.5)),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(height: 1.15),
                          ),
                        ),
                        _ProgressRing(value: done, tint: widget.tint),
                      ],
                    ),
                    SizedBox(height: tokens.space(1.5)),
                    Text(
                      widget.example,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: tokens.space(1.5)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.progressLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (widget.dueCount > 0 && widget.dueLabel != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.space(1),
                              vertical: tokens.space(0.25),
                            ),
                            decoration: BoxDecoration(
                              color: tokens.evidenceSecondary
                                  .withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(tokens.space(1)),
                              border: Border.all(
                                color: tokens.evidenceSecondary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              widget.dueLabel!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.tint});

  final double value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 34,
      height: 34,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: Motion.of(context, Motion.celebrate),
        curve: Motion.curveEmphasis,
        builder: (context, t, _) => CustomPaint(
          painter: _RingPainter(
            value: t,
            tint: tint,
            track: tokens.textMuted.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.tint, required this.track});

  final double value;
  final Color tint;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    if (value <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = tint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.tint != tint;
}
