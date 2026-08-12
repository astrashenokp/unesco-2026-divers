import 'package:flutter/material.dart';

import '../motion.dart';
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
    required this.describeValue,
    this.step = 5,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// Localized question, e.g. "How confident are you?". Required rather
  /// than defaulted so an English string cannot leak in by omission.
  final String label;

  /// Localized plain-language band for [value], e.g. "Fairly sure".
  final String bandLabel;

  /// Localized spoken form of any value, e.g. 72 -> "72 percent, fairly
  /// sure". Taken as a function rather than a string because a slider
  /// that offers increase/decrease must also announce what the value
  /// *would become* — Flutter asserts if `value` is set without
  /// `increasedValue` and `decreasedValue`.
  final String Function(int) describeValue;

  /// How far one assistive-technology step moves the value.
  final int step;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.space(0.5)),
        // The actions must live on the same node as the role. An earlier
        // version put `slider: true` on the wrapper and ExcludeSemantics
        // on the Slider, which deleted its increase/decrease — the value
        // could be read and never changed.
        Semantics(
          slider: true,
          label: label,
          value: describeValue(value),
          increasedValue: describeValue((value + step).clamp(0, 100)),
          decreasedValue: describeValue((value - step).clamp(0, 100)),
          onIncrease: () => onChanged((value + step).clamp(0, 100)),
          onDecrease: () => onChanged((value - step).clamp(0, 100)),
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
          duration: Motion.of(context, Motion.fast),
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
