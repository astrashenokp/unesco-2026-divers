import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// One rung, as the learner sees it.
@immutable
class LadderRung {
  const LadderRung({
    required this.level,
    required this.criteria,
    required this.xp,
  });

  final int level;

  /// What earns this rung, in the rubric's own words.
  final String criteria;
  final int xp;
}

/// The whole scoring ladder, with the learner's position on it.
///
/// Showing only the rung reached tells someone their score without
/// telling them what the scale is, which is the oldest way to make a
/// number feel arbitrary. All five are visible: the ones below so the
/// climb is legible, the one reached, and the ones above so there is
/// somewhere to go.
///
/// This is also the product's argument made concrete. Every rung
/// describes *how thoroughly the learner investigated* and not one
/// mentions whether they were right, so a learner reading the ladder
/// can see for themselves that being wrong carefully outscores being
/// right by luck. That is far more convincing than a sentence claiming
/// it.
///
/// The rungs above are not framed as failure. They are what to do next
/// time, which is the only thing a process score is good for.
class LevelLadder extends StatelessWidget {
  const LevelLadder({
    super.key,
    required this.rungs,
    required this.reached,
    required this.levelLabel,
    required this.xpLabel,
    this.reachedLabel,
    this.nextLabel,
  });

  final List<LadderRung> rungs;

  /// The level this learner reached, or null when nothing has been
  /// attempted yet and the ladder is being shown purely as an
  /// explanation of how scoring works.
  final int? reached;

  /// Localized "Level 3 of 4".
  final String Function(int level, int total) levelLabel;

  /// Localized "6 XP".
  final String Function(int xp) xpLabel;

  /// Spoken and printed marker for the rung reached, e.g. "you reached
  /// this". Never colour alone.
  final String? reachedLabel;

  /// Marker for the next rung up, e.g. "next".
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final top = rungs.isEmpty ? 0 : rungs.last.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, rung) in rungs.indexed)
          _Rung(
            rung: rung,
            index: index,
            total: top,
            isReached: reached != null && rung.level == reached,
            isBelow: reached != null && rung.level < reached!,
            isNext: reached != null && rung.level == reached! + 1,
            levelLabel: levelLabel,
            xpLabel: xpLabel,
            reachedLabel: reachedLabel,
            nextLabel: nextLabel,
            isLast: index == rungs.length - 1,
            tokens: tokens,
          ),
      ],
    );
  }
}

class _Rung extends StatelessWidget {
  const _Rung({
    required this.rung,
    required this.index,
    required this.total,
    required this.isReached,
    required this.isBelow,
    required this.isNext,
    required this.levelLabel,
    required this.xpLabel,
    required this.reachedLabel,
    required this.nextLabel,
    required this.isLast,
    required this.tokens,
  });

  final LadderRung rung;
  final int index;
  final int total;
  final bool isReached;
  final bool isBelow;
  final bool isNext;
  final String Function(int, int) levelLabel;
  final String Function(int) xpLabel;
  final String? reachedLabel;
  final String? nextLabel;
  final bool isLast;
  final EvidenceGymTokens tokens;

  @override
  Widget build(BuildContext context) {
    final accent = isReached
        ? tokens.evidencePrimary
        : isBelow
            ? tokens.evidencePrimary.withValues(alpha: 0.5)
            : tokens.textMuted;

    // The marker carries the state as a shape as well as a colour: a
    // filled check for climbed, a ring for reached, an outline for
    // ahead. Greyscale and colour-blind vision both survive it.
    final icon = isBelow
        ? Icons.check_circle
        : isReached
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked;

    final marker = [
      if (isReached && reachedLabel != null) reachedLabel!,
      if (isNext && nextLabel != null) nextLabel!,
    ].join();

    return Semantics(
      label: [
        levelLabel(rung.level, total),
        rung.criteria,
        xpLabel(rung.xp),
        if (marker.isNotEmpty) marker,
      ].join('. '),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Motion.of(
                          context, Motion.enter + Motion.stagger * index),
                      curve: Motion.curveEmphasis,
                      builder: (context, t, child) =>
                          Opacity(opacity: t, child: child),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: EdgeInsets.symmetric(
                              vertical: tokens.space(0.25)),
                          color: isBelow
                              ? tokens.evidencePrimary.withValues(alpha: 0.4)
                              : tokens.textMuted.withValues(alpha: 0.22),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: tokens.space(1.25)),
                  padding: EdgeInsets.all(tokens.space(1.25)),
                  decoration: BoxDecoration(
                    color: isReached
                        ? tokens.evidencePrimary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(tokens.space(1.5)),
                    border: Border.all(
                      color: isReached
                          ? tokens.evidencePrimary.withValues(alpha: 0.55)
                          : tokens.textMuted.withValues(alpha: 0.2),
                      width: isReached ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap, not Row: at 200% the level name, the XP and
                      // the marker do not share a line.
                      Wrap(
                        spacing: tokens.space(1),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            levelLabel(rung.level, total),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isReached
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                          Text(xpLabel(rung.xp),
                              style: Theme.of(context).textTheme.bodySmall),
                          if (marker.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.space(0.75),
                                vertical: tokens.space(0.125),
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(tokens.space(1)),
                              ),
                              child: Text(
                                marker,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: tokens.space(0.5)),
                      Text(rung.criteria,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
