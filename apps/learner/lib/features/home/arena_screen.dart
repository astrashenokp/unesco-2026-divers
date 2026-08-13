import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/arenas.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import 'stat_tile.dart';

/// The choice above the path: which kind of disinformation to work on.
///
/// This sits before the path rather than filtering it from inside,
/// because the two answer different questions. A filter asks "show me
/// less of what I already have"; this asks "what am I here for". The
/// second is the one a learner arrives with.
///
/// "Everything" is first and is not framed as the lazy option — the
/// missions are ordered so the skills build, and taking them in order is
/// a legitimate way through. The arenas are for the learner who already
/// knows what they keep falling for.
class ArenaGrid extends StatelessWidget {
  const ArenaGrid({
    super.key,
    required this.nodes,
    required this.onSelect,
    this.hiddenCount = 0,
  });

  /// How many missions the younger mode is leaving out. Zero in the
  /// adult mode, where nothing is filtered.

  /// The full path, unfiltered. Counts are computed per arena from this,
  /// so an arena emptied by the younger content mode shows as empty
  /// rather than disappearing — a missing room is confusing, a room with
  /// nothing in it is honest.
  final int hiddenCount;

  final List<LearningPathNode> nodes;

  /// Null means "everything".
  final ValueChanged<DisinfoArena?> onSelect;

  (IconData, Color) _style(DisinfoArena arena, EvidenceGymTokens t) =>
      switch (arena) {
        DisinfoArena.crisis => (Icons.crisis_alert_outlined, t.misleading),
        DisinfoArena.healthAndScience => (Icons.biotech_outlined, t.evidencePrimary),
        DisinfoArena.powerAndMoney => (Icons.account_balance_outlined, t.evidenceSecondary),
        DisinfoArena.syntheticAndRecycled => (Icons.auto_awesome_outlined, t.action),
      };

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns only when a card can still hold its example line
        // without becoming a stack of two-word fragments.
        final columns = constraints.maxWidth >= 620 ? 2 : 1;

        Widget card(DisinfoArena? arena, int index) {
          final inArena = arena == null
              ? nodes
              : nodes.where((n) => demoArenaOf[n.missionId] == arena).toList();
          final done = inArena.where((n) => n.state == 'completed').length;
          final due = inArena.where((n) => n.boosterDue).length;
          final (icon, tint) = arena == null
              ? (Icons.grid_view_outlined, tokens.textMuted)
              : _style(arena, tokens);

          return RevealOnScroll(
            delayIndex: index,
            child: ArenaCard(
              title: arena == null ? s.arenaAll : s.arenaTitleOf(arena.name),
              example: arena == null
                  ? s.arenaAllExample
                  : (inArena.isEmpty
                      ? s.arenaEmpty
                      : s.arenaExampleOf(arena.name)),
              icon: icon,
              tint: tint,
              completed: done,
              total: inArena.length,
              progressLabel: s.arenaProgress(done, inArena.length),
              dueCount: due,
              dueLabel: due > 0 ? s.arenaDue(due) : null,
              onTap: () => onSelect(arena),
            ),
          );
        }

        final cards = <Widget>[
          card(null, 0),
          for (final (i, arena) in kArenaOrder.indexed) card(arena, i + 1),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.arenasTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SectionRule(),
            LupaGreeting(lines: [s.arenasIntro]),
            SizedBox(height: tokens.space(1)),
            // Said once, here, where the counts on the cards would
            // otherwise look like the whole pack. A learner comparing
            // "2 of 3" against a friend's "2 of 5" deserves to know why
            // the totals differ.
            if (hiddenCount > 0)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.space(1)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.child_care_outlined,
                        size: 18, color: tokens.evidencePrimary),
                    SizedBox(width: tokens.space(1)),
                    Expanded(
                      child: Text(s.audienceHiddenNote(hiddenCount),
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            SizedBox(height: tokens.space(1)),
            // A Wrap rather than a GridView: the cards size to their own
            // content, so an arena with a longer example does not force
            // every other card to the same height or clip its own text
            // at 200%.
            Wrap(
              spacing: tokens.space(2),
              runSpacing: tokens.space(2),
              children: [
                for (final card in cards)
                  SizedBox(
                    width: columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - tokens.space(2)) / 2,
                    child: card,
                  ),
              ],
            ),
            SizedBox(height: tokens.space(2)),
          ],
        );
      },
    );
  }
}
