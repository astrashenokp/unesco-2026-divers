import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// Which way the learner moved after investigating.
enum ShiftDirection { lessSure, moreSure, unchanged }

/// What investigating did to the learner's own certainty.
///
/// The completion screen used to report XP and a receipt id — what the
/// system got out of the mission, not what the learner did. This is the
/// other half, and arguably the only half that teaches anything: you
/// believed this much before you looked, and this much after.
///
/// The framing is the whole design. A learner who becomes *less* sure
/// after checking has not failed at anything; they have discovered the
/// question was harder than it looked, which is the single most useful
/// thing this product can teach. So no direction is coloured as good or
/// bad, nothing here is called a score, and the wording never
/// congratulates one movement over another. `unknown` and
/// `evidencePrimary` carry the two directions precisely because neither
/// reads as a verdict.
///
/// Holding steady is treated as a real third outcome rather than a
/// rounding error. Checking and finding your first instinct held up is a
/// different experience from never checking, and the receipt should be
/// able to tell the learner which one happened.
class ConfidenceShift extends StatelessWidget {
  const ConfidenceShift({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    required this.headline,
    required this.explanation,
    required this.spokenSummary,
    this.reactionBefore,
    this.reactionAfter,
    this.reactionLabel,
  });

  /// 0–100, as sent to the API.
  final int before;
  final int after;

  final String beforeLabel;
  final String afterLabel;

  /// Names the movement, e.g. "You became less sure".
  final String headline;

  /// Why that is a reasonable outcome. Never congratulatory.
  final String explanation;

  /// One sentence carrying everything the bars show, for a screen
  /// reader. Two bars and a number are worth nothing spoken.
  final String spokenSummary;

  /// Optional: the first instinct and the final call, e.g.
  /// "Looks trustworthy" → "Context is misleading".
  final String? reactionBefore;
  final String? reactionAfter;
  final String? reactionLabel;

  ShiftDirection get _direction {
    final delta = after - before;
    // A few points either way is noise from dragging a slider, not a
    // change of mind. Treating it as one would put a story on an
    // accident.
    if (delta.abs() < 5) return ShiftDirection.unchanged;
    return delta < 0 ? ShiftDirection.lessSure : ShiftDirection.moreSure;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (accent, icon) = switch (_direction) {
      ShiftDirection.lessSure => (tokens.unknown, Icons.trending_down),
      ShiftDirection.moreSure => (tokens.evidencePrimary, Icons.trending_up),
      ShiftDirection.unchanged => (tokens.evidenceSecondary, Icons.trending_flat),
    };

    return Semantics(
      label: spokenSummary,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.space(2)),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(2.25)),
            border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  SizedBox(width: tokens.space(1)),
                  Expanded(
                    child: Text(headline,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
              SizedBox(height: tokens.space(2)),
              _Bar(label: beforeLabel, value: before, accent: tokens.textMuted),
              SizedBox(height: tokens.space(1)),
              _Bar(label: afterLabel, value: after, accent: accent),
              if (reactionBefore != null &&
                  reactionAfter != null &&
                  reactionLabel != null) ...[
                SizedBox(height: tokens.space(2)),
                Text(reactionLabel!,
                    style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: tokens.space(0.5)),
                // Wrap, not Row: at 200% text scale two labels and an
                // arrow do not fit on one line, and this is content the
                // learner is meant to read rather than glance at.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: tokens.space(1),
                  runSpacing: tokens.space(0.5),
                  children: [
                    Text(reactionBefore!,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Icon(Icons.arrow_forward, size: 16, color: tokens.textMuted),
                    Text(
                      reactionAfter!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
              SizedBox(height: tokens.space(2)),
              Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.accent});

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        SizedBox(
          // Enough for either language's label at ordinary size; the
          // text wraps inside rather than clipping if it needs more.
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        SizedBox(width: tokens.space(1)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 100),
              duration: Motion.of(context, Motion.celebrate),
              curve: Motion.curveEmphasis,
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 12,
                backgroundColor: tokens.textMuted.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
        ),
        SizedBox(width: tokens.space(1)),
        SizedBox(
          width: 44,
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
