import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// Mastery for one evidence skill, 0..1.
///
/// Renders as a segmented bar rather than a smooth gradient: discrete
/// segments are countable by someone who cannot compare bar lengths
/// precisely, and the numeric percentage is always printed alongside, so
/// the value never depends on visual comparison (`ACCESSIBILITY.md`).
class SkillMeter extends StatelessWidget {
  const SkillMeter({
    super.key,
    required this.label,
    required this.mastery,
    required this.masteryLabel,
    this.dueLabel,
    this.segments = 5,
  });

  final String label;
  final double mastery;

  /// Localized "62% mastered"-style string; also used for the screen reader.
  final String masteryLabel;

  /// Optional localized "practice due" note.
  final String? dueLabel;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final clamped = mastery.clamp(0.0, 1.0);

    return Semantics(
      label: dueLabel == null ? '$label, $masteryLabel' : '$label, $masteryLabel, $dueLabel',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.space(1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
                ),
                Text(
                  masteryLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: tokens.space(0.5)),
            // Segments fill one after another rather than appearing
            // already full, so opening the screen shows the shape of the
            // progress instead of a static bar. Purely decorative: the
            // percentage is printed above and announced by the semantics
            // node, and reduced motion lands on the final state at once.
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped),
                duration: Motion.of(context, Motion.celebrate),
                curve: Motion.curveStandard,
                builder: (context, shown, _) {
                  final grown = (shown * segments).round();
                  return Row(
                    children: [
                      for (var i = 0; i < segments; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: Motion.of(context, Motion.fast),
                            height: 10,
                            margin: EdgeInsets.only(
                              right: i == segments - 1 ? 0 : tokens.space(0.5),
                            ),
                            decoration: BoxDecoration(
                              color: i < grown
                                  ? tokens.evidencePrimary
                                  : tokens.evidencePrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (dueLabel != null) ...[
              SizedBox(height: tokens.space(0.5)),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: tokens.evidenceSecondary),
                  SizedBox(width: tokens.space(0.5)),
                  Text(dueLabel!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
