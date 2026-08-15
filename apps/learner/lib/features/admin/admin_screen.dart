import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/arenas.dart';
import '../../l10n/strings.dart';

/// What the operator view can show about a cohort.
@immutable
class CohortStats {
  const CohortStats({
    required this.learners,
    required this.missionsCompleted,
    required this.medianProcessLevel,
    required this.uncertaintyShare,
    required this.evidenceBeforeConclusion,
    required this.perArenaCompletion,
    required this.reportsOpen,
  });

  final int learners;
  final int missionsCompleted;

  /// Typical rung reached, 0–4.
  final double medianProcessLevel;

  /// Share of conclusions that used an uncertainty answer.
  ///
  /// The single most useful number here. It is not an error rate — it is
  /// how often people were willing to say the evidence did not settle
  /// it, which is the habit the whole product is trying to build.
  final double uncertaintyShare;

  /// Share of conclusions that had at least one evidence check behind
  /// them. The inverse is the failure mode this product exists for.
  final double evidenceBeforeConclusion;

  final Map<DisinfoArena, double> perArenaCompletion;
  final int reportsOpen;
}

/// The operator view.
///
/// **Aggregate only, and that is a deliberate refusal rather than an
/// unfinished feature.** A per-learner analytics screen was asked for; it
/// is not built, because this product records what a person believed
/// before they checked, how confident they were, and how their mind
/// changed. A screen that replays one named individual's beliefs is a
/// different product from the one described in `PRIVACY.md`, which
/// commits to aggregation, small-cohort suppression and no
/// susceptibility profiling — and it would be the single most damaging
/// thing that could leak from a media-literacy tool.
///
/// The teaching questions an operator actually has are cohort questions
/// anyway: is anyone concluding without checking, are people willing to
/// say "not enough evidence", which subject is going badly. All of those
/// are answerable here. "How is Maria doing" is not, and a teacher who
/// needs that should ask Maria.
///
/// Nothing marks this screen as special in the interface. It is reached
/// by an account that has the role and does not exist for one that does
/// not, which is the only place that decision can safely live — a
/// client-side flag would be a lock with the key taped to it.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.stats});

  final CohortStats stats;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    // Below this, nothing is shown at all. A "cohort" of three is three
    // identifiable people, and an average over them is a description of
    // each. PRIVACY.md calls this small-cohort suppression.
    const minimumCohort = 5;
    if (stats.learners < minimumCohort) {
      return ReadableWidth(
        child: Padding(
          padding: EdgeInsets.all(tokens.space(3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.adminTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SectionRule(),
              Text(s.adminTooFewTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              Text(s.adminTooFewBody(minimumCohort),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    Widget stat(String label, String value, String meaning) => Padding(
          padding: EdgeInsets.only(bottom: tokens.space(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              // Every number carries what it means. An operator dashboard
              // of bare figures invites people to act on the ones they
              // misread, and the misreadings here have consequences for
              // learners.
              Text(meaning, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );

    return ReadableWidth(
      child: ListView(
        padding: EdgeInsets.all(tokens.space(2)),
        children: [
          Text(s.adminTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SectionRule(),
          Text(s.adminScopeNote, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: tokens.space(3)),

          stat(s.adminLearners, '${stats.learners}', s.adminLearnersMeaning),
          stat(
            s.adminEvidenceFirst,
            '${(stats.evidenceBeforeConclusion * 100).round()}%',
            s.adminEvidenceFirstMeaning,
          ),
          stat(
            s.adminUncertainty,
            '${(stats.uncertaintyShare * 100).round()}%',
            s.adminUncertaintyMeaning,
          ),
          stat(
            s.adminMedianLevel,
            stats.medianProcessLevel.toStringAsFixed(1),
            s.adminMedianLevelMeaning,
          ),

          SizedBox(height: tokens.space(2)),
          Text(s.adminByArena, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          for (final arena in kPopulatedArenas)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space(1)),
              child: SkillMeter(
                label: s.arenaTitleOf(arena.name),
                mastery: stats.perArenaCompletion[arena] ?? 0,
                masteryLabel:
                    '${((stats.perArenaCompletion[arena] ?? 0) * 100).round()}%',
              ),
            ),

          SizedBox(height: tokens.space(2)),
          Text(s.adminReports, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(0.5)),
          Text(s.adminReportsCount(stats.reportsOpen),
              style: Theme.of(context).textTheme.bodyLarge),
          Text(s.adminReportsMeaning,
              style: Theme.of(context).textTheme.bodySmall),

          SizedBox(height: tokens.space(3)),
          Container(
            padding: EdgeInsets.all(tokens.space(2)),
            decoration: BoxDecoration(
              color: tokens.unknown.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(tokens.space(2)),
              border: Border.all(color: tokens.unknown.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: tokens.textMuted),
                    SizedBox(width: tokens.space(1)),
                    Expanded(
                      child: Text(s.adminNoIndividualsTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space(1)),
                Text(s.adminNoIndividualsBody,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
