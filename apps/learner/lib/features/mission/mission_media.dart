import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';

/// The mission's media, drawn when it can be and described when it
/// cannot.
///
/// The pack addresses media as `asset://p0-demo-pack/media/…`, which is
/// not a URL any client can fetch — it names a file inside the content
/// pack. For the demo pack, which ships with the app, that resolves to a
/// bundled asset. Anything else is left undrawn rather than guessed at.
///
/// **The alt text is not a fallback here, it is the primary content.**
/// `accessibility.mediaAlternatives` in the pack says so explicitly:
/// "the mission can be completed from the claim text, alt text, evidence
/// actions and source notes without relying on visual inspection". So
/// the description is always shown, image or no image — a learner using
/// a screen reader and a learner looking at the photo are doing the same
/// mission, not two versions of it.
class MissionMediaView extends StatelessWidget {
  const MissionMediaView({super.key, required this.media});

  final MissionMedia media;

  /// Maps a pack asset reference to a bundled asset, or null.
  ///
  /// Only the demo pack is bundled. A reference into a pack the app does
  /// not carry returns null and the image is simply not drawn, which is
  /// better than a broken-image icon implying something was lost.
  static String? bundledAssetFor(String? url) {
    if (url == null) return null;
    const prefix = 'asset://p0-demo-pack/';
    if (!url.startsWith(prefix)) return null;
    return 'assets/${url.substring(prefix.length)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final asset = bundledAssetFor(media.url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (asset != null)
          Semantics(
            image: true,
            label: media.altText,
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.space(2)),
                child: Image.asset(
                  asset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // A tall photo would otherwise push the claim off the
                  // screen; the claim is the thing under investigation.
                  height: 240,
                  // A missing asset must not take the screen down with
                  // it, and must not leave a broken-image glyph either:
                  // the description below still carries the mission.
                  errorBuilder: (context, _, __) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (asset != null) SizedBox(height: tokens.space(1)),

        // Always, not only when the image is missing.
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.space(1.5)),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(1.75)),
            border: Border.all(color: tokens.textMuted.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                switch (media.type) {
                  'video' => Icons.videocam_outlined,
                  'audio' => Icons.volume_up_outlined,
                  'text' => Icons.article_outlined,
                  _ => Icons.image_outlined,
                },
                size: 18,
                color: tokens.textMuted,
              ),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.mediaDescribed,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(media.altText,
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (media.transcript != null) ...[
                      SizedBox(height: tokens.space(1)),
                      Text(media.transcript!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
