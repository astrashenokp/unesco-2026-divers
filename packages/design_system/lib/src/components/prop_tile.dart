import 'package:flutter/material.dart';

import '../tokens.dart';

/// The set of investigation "props" — the objects a learner picks up and
/// uses. Each one maps to a kind of evidence check, so the same object
/// always means the same action across every screen.
enum EvidenceProp {
  /// Who is behind this?
  source,

  /// When was this actually made?
  date,

  /// Who else is reporting it?
  corroboration,

  /// Where did this file come from?
  provenance,

  /// Does the cited work exist?
  citation,

  /// What is still unknown?
  uncertainty,

  /// Should this be passed on?
  sharing,
}

/// Maps a contract `EvidenceAction.type` (or id) onto a prop. Unknown
/// types fall back to [EvidenceProp.source] rather than throwing —
/// content packs must be able to add action types without breaking a
/// client that has not shipped an icon for them yet.
EvidenceProp propForActionType(String type) => switch (type) {
      'source' => EvidenceProp.source,
      'date' => EvidenceProp.date,
      'corroboration' => EvidenceProp.corroboration,
      'provenance' => EvidenceProp.provenance,
      'citation' => EvidenceProp.citation,
      'uncertainty' => EvidenceProp.uncertainty,
      'sharing' => EvidenceProp.sharing,
      _ => EvidenceProp.source,
    };

(IconData, Color) _propStyle(EvidenceProp prop, EvidenceGymTokens t) => switch (prop) {
      EvidenceProp.source => (Icons.account_circle_outlined, t.action),
      EvidenceProp.date => (Icons.event_outlined, t.evidenceSecondary),
      EvidenceProp.corroboration => (Icons.hub_outlined, t.evidencePrimary),
      EvidenceProp.provenance => (Icons.photo_camera_outlined, t.contradicted),
      EvidenceProp.citation => (Icons.menu_book_outlined, t.misleading),
      EvidenceProp.uncertainty => (Icons.help_outline, t.unknown),
      EvidenceProp.sharing => (Icons.ios_share_outlined, t.focus),
    };

/// A chunky, tactile tile in the Duolingo idiom: flat fill, generous
/// radius, and a solid darker edge underneath that the tile presses down
/// into. It reads as a physical object rather than a link.
///
/// The tile pops in with a spring on first appearance, staggered by
/// [delayIndex]. Under reduced motion it is simply present — the
/// animation carries no meaning of its own.
///
/// [used] dims the tile and swaps the icon for a tick, so "already
/// checked" survives greyscale and colour-blind vision.
class PropTile extends StatefulWidget {
  const PropTile({
    super.key,
    required this.prop,
    required this.label,
    required this.semanticLabel,
    this.used = false,
    this.delayIndex = 0,
    this.onTap,
  });

  final EvidenceProp prop;
  final String label;

  /// Fully localized, including the used/unused state.
  final String semanticLabel;
  final bool used;
  final int delayIndex;
  final VoidCallback? onTap;

  @override
  State<PropTile> createState() => _PropTileState();
}

class _PropTileState extends State<PropTile> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Stagger, then spring in. Cancelled safely if we're disposed first.
    Future<void>.delayed(Duration(milliseconds: 60 * widget.delayIndex), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final (icon, color) = _propStyle(widget.prop, tokens);
    final enabled = widget.onTap != null && !widget.used;

    // The "edge" the tile sits on. Pressing sinks the tile into it.
    const edgeDepth = 5.0;
    final sink = _pressed && !reduceMotion ? edgeDepth - 2 : 0.0;

    final tile = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: SizedBox(
            width: 104,
            height: 104 + edgeDepth,
            child: Stack(
              children: [
                // Solid edge underneath.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: widget.used ? 0.25 : 0.55),
                      borderRadius: BorderRadius.circular(tokens.space(2.5)),
                    ),
                  ),
                ),
                // Face.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  top: sink,
                  child: Container(
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.used ? tokens.surface : tokens.surfaceRaised,
                      borderRadius: BorderRadius.circular(tokens.space(2.5)),
                      border: Border.all(
                        color: color.withValues(alpha: widget.used ? 0.35 : 1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.used ? Icons.check_rounded : icon,
                          size: 32,
                          color: color.withValues(alpha: widget.used ? 0.55 : 1),
                        ),
                        SizedBox(height: tokens.space(0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: tokens.space(0.5)),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: widget.used ? tokens.textMuted : tokens.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return tile;

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = Curves.elasticOut.transform(_entrance.value.clamp(0.0, 1.0));
        return Opacity(
          // Fade completes well before the spring settles, so the tile is
          // readable while it is still moving.
          opacity: (_entrance.value * 2).clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
        );
      },
      child: tile,
    );
  }
}
