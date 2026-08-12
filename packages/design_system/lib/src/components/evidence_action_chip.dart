import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// A tappable evidence action ("Check source", "Check date", ...).
/// Disabled state communicates "already used" without color alone
/// (opacity + a check icon + semantics).
class EvidenceActionChip extends StatelessWidget {
  const EvidenceActionChip({
    super.key,
    required this.label,
    required this.used,
    this.onTap,
  });

  final String label;
  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: used ? '$label, already used' : label,
      child: AnimatedOpacity(
        duration: Motion.of(context, Motion.fast),
        opacity: used ? 0.55 : 1,
        child: ActionChip(
          avatar: used
              ? const Icon(Icons.check, size: 18)
              : const Icon(Icons.search, size: 18),
          label: Text(label),
          backgroundColor: tokens.surfaceRaised,
          side: BorderSide(color: tokens.evidencePrimary),
          onPressed: used ? null : onTap,
        ),
      ),
    );
  }
}
