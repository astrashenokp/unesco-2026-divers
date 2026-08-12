import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One number in the path header: XP, streak, or today's goal.
///
/// Read-only by design. The streak in particular is never presented as
/// something at risk — `GAME_AND_LEARNING_DESIGN.md` requires it to be
/// non-punitive, so there is no countdown, no warning colour, and no
/// "don't lose it" copy.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    this.count,
    this.format,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  /// When supplied, the value counts up to [count] instead of snapping.
  /// [format] turns the interpolated number into localized display text.
  final int? count;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        // A Wrap gives its children unbounded width, so without a cap
        // this Row grows past the screen at large text sizes instead of
        // wrapping to the next line.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space(1.5),
            vertical: tokens.space(1),
          ),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(1.5)),
            border: Border.all(color: tint.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: tint),
              SizedBox(width: tokens.space(1)),
              Flexible(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (count != null && format != null)
                    RollingNumber(
                      value: count!,
                      format: format!,
                      semanticsLabel: '$value $label',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    )
                  else
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Lupa plus what she has to say on the path screen.
class LupaGreeting extends StatelessWidget {
  const LupaGreeting({super.key, required this.lines, this.size = 84});

  final List<String> lines;
  final double size;

  @override
  Widget build(BuildContext context) =>
      LupaSpeech(lines: lines, mascotSize: size);
}
