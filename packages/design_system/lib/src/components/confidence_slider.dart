import 'package:flutter/material.dart';

import '../tokens.dart';

/// Confidence input, 0–100.
///
/// The number and a plain-language band are always printed next to the
/// track. A slider position alone is unreadable for anyone who can't
/// judge it visually, and "72%" alone means little to a young learner —
/// so both are shown, and both are what the screen reader announces.
class ConfidenceSlider extends StatelessWidget {
  const ConfidenceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.bandLabel,
    required this.percentSemantics,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// Localized question, e.g. "How confident are you?". Required rather
  /// than defaulted so an English string cannot leak in by omission.
  final String label;

  /// Localized plain-language band for [value], e.g. "Fairly sure".
  final String bandLabel;

  /// Localized spoken form of the value, e.g. "72 percent".
  final String percentSemantics;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.space(0.5)),
        Semantics(
          slider: true,
          label: label,
          value: '$percentSemantics, $bandLabel',
          child: ExcludeSemantics(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              // 5-point steps: fine enough to express a real change of
              // mind, coarse enough to hit with an unsteady finger.
              divisions: 20,
              activeColor: tokens.action,
              label: '$value%',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: tokens.motionFast,
          child: Text(
            '$value% · $bandLabel',
            key: ValueKey('$value$bandLabel'),
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
