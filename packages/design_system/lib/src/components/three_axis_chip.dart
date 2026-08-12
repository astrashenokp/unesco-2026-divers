import 'package:flutter/material.dart';

import '../tokens.dart';

/// The three independent conclusion axes.
///
/// Never rendered as a green/red verdict badge: each option carries an
/// icon and a distinct shape as well as a colour, so the meaning survives
/// greyscale and colour-blind vision (`DESIGN_SYSTEM.md`).
enum AxisKind { authenticity, claimVeracity, contextIntegrity }

/// The styling dimension shared across axes. Kept separate from the
/// wording because each axis has its own vocabulary — "Synthetic" and
/// "Misleading" are cautions on different questions, not the same answer.
enum AxisTone { supported, caution, contradicted, unknown }

/// One selectable answer on an axis.
///
/// [code] is the stable, English, machine-readable value sent to the API
/// (`AxisAssessment.label` in `contracts/openapi.yaml`). [label] is the
/// localized text shown to the learner. These must never be conflated:
/// sending a translated label would put Ukrainian text in the contract.
@immutable
class AxisOption {
  const AxisOption({required this.code, required this.label, required this.tone});

  final String code;
  final String label;
  final AxisTone tone;
}

/// The API codes for each axis, in display order. Localized labels are
/// supplied by the app layer; this list fixes the vocabulary and order so
/// the picker and the receipt can never drift apart.
List<({String code, AxisTone tone})> axisOptionCodes(AxisKind axis) => switch (axis) {
      AxisKind.authenticity => const [
          (code: 'authentic', tone: AxisTone.supported),
          (code: 'synthetic', tone: AxisTone.caution),
          (code: 'altered', tone: AxisTone.contradicted),
          (code: 'unknown', tone: AxisTone.unknown),
        ],
      AxisKind.claimVeracity => const [
          (code: 'supported', tone: AxisTone.supported),
          (code: 'contradicted', tone: AxisTone.contradicted),
          (code: 'insufficient_evidence', tone: AxisTone.unknown),
        ],
      AxisKind.contextIntegrity => const [
          (code: 'accurate', tone: AxisTone.supported),
          (code: 'misleading', tone: AxisTone.caution),
          (code: 'fabricated_context', tone: AxisTone.contradicted),
          (code: 'unknown', tone: AxisTone.unknown),
        ],
    };

(Color, IconData) toneStyle(EvidenceGymTokens tokens, AxisTone tone) => switch (tone) {
      AxisTone.supported => (tokens.supported, Icons.check_circle_outline),
      AxisTone.contradicted => (tokens.contradicted, Icons.change_circle_outlined),
      AxisTone.caution => (tokens.misleading, Icons.crop_free),
      AxisTone.unknown => (tokens.unknown, Icons.help_outline),
    };

/// Read-only display of a chosen assessment (conclusion summary, receipt).
class ThreeAxisChip extends StatelessWidget {
  const ThreeAxisChip({
    super.key,
    required this.axisName,
    required this.option,
    required this.confidence,
    required this.confidenceSemantics,
  });

  final String axisName;
  final AxisOption option;
  final int confidence;

  /// Fully localized sentence for the screen reader, e.g.
  /// "confidence 70 percent".
  final String confidenceSemantics;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (color, icon) = toneStyle(tokens, option.tone);

    return Semantics(
      label: '$axisName: ${option.label}, $confidenceSemantics',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space(2),
            vertical: tokens.space(1.5),
          ),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(1.5)),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: tokens.space(1)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(axisName, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      option.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive picker for one axis. Wraps rather than scrolls, so nothing
/// is hidden off-screen at 200% text size.
class AxisPicker extends StatelessWidget {
  const AxisPicker({
    super.key,
    required this.axisName,
    required this.helpText,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String axisName;

  /// Plain-language explanation of what this axis is asking. Always
  /// visible rather than behind a tooltip: a tooltip is unusable on touch
  /// and invisible to a first-time learner.
  final String helpText;
  final List<AxisOption> options;
  final AxisOption? selected;
  final ValueChanged<AxisOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(axisName, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.space(0.5)),
        Text(helpText, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: tokens.space(1)),
        Wrap(
          spacing: tokens.space(1),
          runSpacing: tokens.space(1),
          children: [
            for (final option in options)
              _AxisChoiceChip(
                option: option,
                selected: selected?.code == option.code,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _AxisChoiceChip extends StatelessWidget {
  const _AxisChoiceChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AxisOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (color, icon) = toneStyle(tokens, option.tone);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ChoiceChip(
        avatar: Icon(icon, color: selected ? tokens.onAction : color, size: 18),
        label: Text(option.label),
        selected: selected,
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? tokens.onAction : tokens.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
        side: BorderSide(color: color, width: selected ? 2 : 1),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
