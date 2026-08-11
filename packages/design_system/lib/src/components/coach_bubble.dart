import 'package:flutter/material.dart';

import '../mascot/lupa.dart';
import '../tokens.dart';

/// A Socratic hint from Lupa.
///
/// Three non-negotiables encoded here, from `AI_SAFETY.md` and
/// `DESIGN_SYSTEM.md`:
///   1. it is always visibly labelled as AI,
///   2. it always shows its uncertainty,
///   3. it never renders as a verdict — no success/failure colouring.
class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.text,
    required this.uncertainty,
    required this.aiLabel,
    required this.uncertaintyLabel,
    this.isFallback = false,
    this.fallbackLabel,
  });

  final String text;

  /// `low` | `medium` | `high`, straight from the Hint schema.
  final String uncertainty;

  /// Localized "AI coach" label — required, never optional.
  final String aiLabel;

  /// Localized, already-formatted uncertainty sentence.
  final String uncertaintyLabel;

  /// True when the deterministic fallback answered instead of the model.
  /// Shown to the learner rather than hidden, so a degraded coach is
  /// never mistaken for a confident one.
  final bool isFallback;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$aiLabel. $text. $uncertaintyLabel',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(child: Lupa(mood: LupaMood.asking, size: 56)),
          SizedBox(width: tokens.space(1)),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(tokens.space(2)),
              decoration: BoxDecoration(
                color: tokens.surfaceRaised,
                borderRadius: BorderRadius.circular(tokens.space(2)),
                border: Border.all(color: tokens.action.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: tokens.action),
                      SizedBox(width: tokens.space(0.5)),
                      Text(
                        aiLabel.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.action,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.space(1)),
                  Text(text, style: theme.textTheme.bodyLarge),
                  SizedBox(height: tokens.space(1)),
                  Row(
                    children: [
                      Icon(
                        switch (uncertainty) {
                          'low' => Icons.signal_cellular_alt,
                          'medium' => Icons.signal_cellular_alt_2_bar,
                          _ => Icons.signal_cellular_alt_1_bar,
                        },
                        size: 14,
                        color: tokens.textMuted,
                      ),
                      SizedBox(width: tokens.space(0.5)),
                      Expanded(
                        child: Text(
                          uncertaintyLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (isFallback && fallbackLabel != null) ...[
                    SizedBox(height: tokens.space(0.5)),
                    Text(
                      fallbackLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.misleading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
