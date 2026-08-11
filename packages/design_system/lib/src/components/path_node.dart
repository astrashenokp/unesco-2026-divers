import 'package:flutter/material.dart';

import '../tokens.dart';

enum PathNodeState { locked, available, completed }

/// One stop on the skill path.
///
/// Scroll-reveal animation is *not* handled here — wrap this in
/// `RevealOnScroll` instead, so the animation stays a decoration that can
/// be removed without touching the node's meaning or hit target.
///
/// State is conveyed by icon, fill and an explicit localized label, never
/// by colour alone.
class PathNode extends StatelessWidget {
  const PathNode({
    super.key,
    required this.title,
    required this.state,
    required this.stateLabel,
    this.boosterDue = false,
    this.boosterLabel,
    this.onTap,
  });

  final String title;
  final PathNodeState state;

  /// Localized "locked" / "available" / "completed", for the screen reader.
  final String stateLabel;
  final bool boosterDue;
  final String? boosterLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (bg, fg, icon) = switch (state) {
      PathNodeState.locked => (tokens.surfaceRaised, tokens.textMuted, Icons.lock_outline),
      PathNodeState.available => (tokens.action, Colors.white, Icons.explore_outlined),
      PathNodeState.completed => (tokens.evidencePrimary, Colors.white, Icons.check),
    };

    final semanticLabel = boosterDue && boosterLabel != null
        ? '$title, $stateLabel, $boosterLabel'
        : '$title, $stateLabel';

    return Semantics(
      button: state != PathNodeState.locked,
      enabled: state != PathNodeState.locked,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state == PathNodeState.locked ? null : onTap,
            customBorder: const CircleBorder(),
            child: Container(
              // 72dp comfortably clears the 44dp minimum target, which
              // matters most for the learners with the least steady aim.
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: boosterDue
                    ? Border.all(color: tokens.evidenceSecondary, width: 3)
                    : Border.all(color: tokens.textMuted.withValues(alpha: 0.2)),
                boxShadow: state == PathNodeState.locked
                    ? null
                    : [
                        BoxShadow(
                          color: bg.withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Icon(icon, color: fg, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
