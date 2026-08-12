import 'package:flutter/material.dart';

import '../tokens.dart';

/// How much of a source's identity could actually be established.
enum SourceStanding {
  /// Publisher and date verified against metadata.
  verified,

  /// Present in a reviewed pack, not independently re-checked.
  curated,

  /// Found, but nothing about it could be confirmed.
  unverified,

  /// Sources disagree about what this is.
  conflicting,
}

/// Who is behind a piece of evidence.
///
/// `DESIGN_SYSTEM.md` asks for a source identity card, and the product's
/// first skill is "who is behind it". Rendering a source as one line of
/// text taught the opposite of the lesson: it made provenance look like
/// a detail rather than the thing being examined.
///
/// Everything the learner needs in order to judge the source sits on the
/// card — who published it, when it was retrieved, what standing that
/// claim of identity has, and what the record does not say.
class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.title,
    required this.standing,
    required this.standingLabel,
    required this.retrievedLabel,
    this.publisher,
    this.detail,
    this.limitations = const [],
  });

  final String title;
  final SourceStanding standing;

  /// Localized name for [standing]. Standing is never colour-only.
  final String standingLabel;

  /// Localized "retrieved 10 August 2026".
  final String retrievedLabel;

  final String? publisher;
  final String? detail;

  /// What this record cannot tell you. Always shown, never behind a
  /// disclosure: a limitation the learner does not see is a limitation
  /// they will not weigh.
  final List<String> limitations;

  (Color, IconData) _style(EvidenceGymTokens t) => switch (standing) {
        SourceStanding.verified => (t.supported, Icons.verified_outlined),
        SourceStanding.curated => (t.evidencePrimary, Icons.inventory_2_outlined),
        SourceStanding.unverified => (t.unknown, Icons.help_outline),
        SourceStanding.conflicting => (t.contradicted, Icons.alt_route),
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (colour, icon) = _style(tokens);

    return Semantics(
      label: [
        title,
        if (publisher != null) publisher,
        standingLabel,
        retrievedLabel,
        ...limitations,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.space(2)),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(2.25)),
            border: Border.all(color: colour.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(tokens.space(1)),
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: colour),
                  ),
                  SizedBox(width: tokens.space(1.5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (publisher != null)
                          Text(publisher!,
                              style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          standingLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colour,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (detail != null) ...[
                SizedBox(height: tokens.space(1.5)),
                Text(detail!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              SizedBox(height: tokens.space(1.5)),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: tokens.textMuted),
                  SizedBox(width: tokens.space(0.5)),
                  Text(retrievedLabel,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (limitations.isNotEmpty) ...[
                SizedBox(height: tokens.space(1)),
                Container(
                  padding: EdgeInsets.all(tokens.space(1.25)),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.space(1.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final limitation in limitations)
                        Text('• $limitation',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A warning shown before content a learner may not want to meet
/// unprepared.
///
/// Required by `DESIGN_SYSTEM.md` and by the safeguarding rules: a pack
/// declares content warnings, and the client has to honour them. This is
/// one of the two places `danger` colouring is legitimate.
class ContentWarning extends StatelessWidget {
  const ContentWarning({
    super.key,
    required this.title,
    required this.body,
    required this.revealLabel,
    required this.onReveal,
  });

  final String title;
  final String body;
  final String revealLabel;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.space(2)),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(tokens.space(2)),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: tokens.danger, size: 20),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: tokens.textPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space(1)),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: tokens.space(1.5)),
          // Revealing is always a deliberate act. There is no automatic
          // reveal on scroll and no timer.
          OutlinedButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(revealLabel),
          ),
        ],
      ),
    );
  }
}
