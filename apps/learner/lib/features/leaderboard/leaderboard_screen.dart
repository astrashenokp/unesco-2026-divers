import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';

/// One row of the board.
@immutable
class BoardEntry {
  const BoardEntry({
    required this.handle,
    required this.xp,
    required this.missions,
    this.isYou = false,
  });

  /// A chosen handle, never a real name.
  final String handle;
  final int xp;
  final int missions;
  final bool isYou;
}

/// Where learners can see each other.
///
/// **This screen is built against the grain of the design docs and that
/// is worth stating plainly.** `SCREEN_REFERENCE.md` lists "no
/// leaderboard" among the things deliberately absent, and the reasoning
/// was sound: a board that ranks people on judging what is true rewards
/// speed and confidence, which are the two habits this product exists to
/// slow down. It was asked for anyway, so it is built — with the parts
/// that cause that harm removed rather than the whole idea.
///
/// Four decisions carry that:
///
/// * **It ranks process XP, which cannot be earned by being right.**
///   Every point comes from checks actually run. Someone who guesses
///   correctly in five seconds scores the minimum, and no amount of
///   luck moves them up. The only way to climb is to investigate more
///   thoroughly, which is the behaviour worth competing over.
/// * **No accuracy column, ever.** The moment a board shows who was
///   "right most often", it teaches confident guessing and punishes
///   saying "not enough evidence" — the answer the product is built to
///   make sayable.
/// * **Handles, not names.** `PRIVACY.md` collects no legal name and
///   this must not become the reason to start.
/// * **Opt-in, and reversible.** A learner who has not chosen a handle
///   does not appear at all. Ranking people who never asked to be
///   ranked is the difference between a game and a scoreboard someone
///   else put you on.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    super.key,
    required this.repository,
    required this.entries,
    required this.participating,
    required this.onJoin,
    required this.onLeave,
  });

  final MissionRepository repository;
  final List<BoardEntry> entries;

  /// Whether this learner has opted in.
  final bool participating;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return ReadableWidth(
      child: ListView(
        padding: EdgeInsets.all(tokens.space(2)),
        children: [
          Text(s.boardTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SectionRule(),
          Text(s.boardExplain, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: tokens.space(2)),

          if (!participating) ...[
            // Nothing about anyone else is shown before the learner has
            // decided to take part. Showing the board first and asking
            // afterwards would make the choice a formality.
            Container(
              padding: EdgeInsets.all(tokens.space(2)),
              decoration: BoxDecoration(
                color: tokens.surfaceRaised,
                borderRadius: BorderRadius.circular(tokens.space(2)),
                border:
                    Border.all(color: tokens.textMuted.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.boardJoinTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: tokens.space(1)),
                  Text(s.boardJoinBody,
                      style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: tokens.space(1.5)),
                  ElevatedButton(onPressed: onJoin, child: Text(s.boardJoin)),
                ],
              ),
            ),
            SizedBox(height: tokens.space(2)),
            Text(s.boardPrivacyNote,
                style: Theme.of(context).textTheme.bodySmall),
          ] else ...[
            for (final (index, entry) in entries.indexed)
              RevealOnScroll(
                delayIndex: index,
                child: _Row(entry: entry, place: index + 1),
              ),
            if (entries.isEmpty)
              Text(s.boardEmpty, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: tokens.space(2)),
            Text(s.boardPrivacyNote,
                style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: tokens.space(1)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onLeave,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: Text(s.boardLeave),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.place});

  final BoardEntry entry;
  final int place;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Semantics(
      label: [
        s.boardPlace(place),
        entry.handle,
        s.boardXpAndMissions(entry.xp, entry.missions),
        if (entry.isYou) s.boardThatIsYou,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          margin: EdgeInsets.only(bottom: tokens.space(1)),
          padding: EdgeInsets.all(tokens.space(1.5)),
          decoration: BoxDecoration(
            // The learner's own row is marked, and nobody else's is.
            // Podium colours for the top three would make the rest of
            // the board look like the losing part of it.
            color: entry.isYou
                ? tokens.action.withValues(alpha: 0.10)
                : tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.space(1.75)),
            border: Border.all(
              color: entry.isYou
                  ? tokens.action.withValues(alpha: 0.5)
                  : tokens.textMuted.withValues(alpha: 0.18),
              width: entry.isYou ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$place',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.handle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      s.boardXpAndMissions(entry.xp, entry.missions),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (entry.isYou)
                Icon(Icons.person, size: 18, color: tokens.action),
            ],
          ),
        ),
      ),
    );
  }
}
