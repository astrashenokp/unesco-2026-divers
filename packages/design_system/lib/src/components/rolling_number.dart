import 'package:flutter/material.dart';

import '../tokens.dart';

/// A number that counts up to its new value instead of snapping.
///
/// Used for XP, where the change is the point: seeing 12 travel to 15
/// says "you earned three" far better than the digits simply changing.
///
/// Accessibility: the animation is decoration only. The semantics node
/// always carries the *final* value, so a screen reader announces the
/// real number immediately rather than a stream of intermediate ones,
/// and under reduced motion the value appears at once.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.format,
    required this.semanticsLabel,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  final int value;

  /// Turns the interpolated number into display text, so callers keep
  /// control of localization ("15 XP" / "15 бали").
  final String Function(int) format;

  /// Announced immediately, always describing [value], never a tween step.
  final String semanticsLabel;

  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final tokens = context.tokens;

    final text = Text(
      format(value),
      style: style ??
          Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: tokens.textPrimary),
    );

    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: reduceMotion
            ? text
            : TweenAnimationBuilder<int>(
                // `begin` applies to the first build only — it counts up
                // from zero. On every later change TweenAnimationBuilder
                // starts from the value currently on screen, so
                // consecutive awards continue from where the counter sits
                // rather than restarting at zero.
                tween: IntTween(begin: 0, end: value),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, shown, _) => Text(
                  format(shown),
                  style: style ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                ),
              ),
      ),
    );
  }
}
