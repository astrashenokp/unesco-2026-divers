import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import 'skill_screen.dart';

/// Skill mastery and process XP.
///
/// Frames XP as a record of *how* the learner investigates — the
/// "XP is never evidence that a person is intelligent or trustworthy"
/// rule from `GAME_AND_LEARNING_DESIGN.md` is printed on the screen, not
/// just honoured in the scoring.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    required this.repository,
    this.onGoToPath,
  });

  final MissionRepository repository;

  /// Moves the learner to the path. Supplied by the shell, which owns
  /// the destination index — a screen inside a shell should not be
  /// reaching for a Navigator that is not its own.
  final VoidCallback? onGoToPath;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<Progress> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getMyProgress();
  }

  void _retry() => setState(() => _future = widget.repository.getMyProgress());

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return FutureBuilder<Progress>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Semantics(label: s.loading, child: const CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return FailureView(
            error: snapshot.error,
            onRetry: _retry,
            isDemo: widget.repository.isDemo,
          );
        }

        final progress = snapshot.data!;
        final onGoToPath = widget.onGoToPath;
        return ReadableWidth(
          child: ListView(
            padding: EdgeInsets.all(tokens.space(2)),
            children: [
              Text(s.profileTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SectionRule(),
              Row(
                children: [
                  Lupa(mood: LupaMood.idle, size: 64, semanticLabel: s.lupaLabel('idle')),
                  SizedBox(width: tokens.space(2)),
                  Expanded(
                    child: Text(
                      s.totalXp(progress.totalXp),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.space(1)),
              Text(s.xpMeaning, style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: tokens.space(3)),
              Text(s.skillsTitle, style: Theme.of(context).textTheme.titleLarge),
              const Slid(),
              if (progress.skills.isEmpty) ...[
                // A destination that says "0" and nothing else spends a
                // whole tab telling someone they have done nothing. This
                // space is worth more explaining what is about to be
                // measured, which is also the product's argument: every
                // skill below is about how a claim was checked, and not
                // one of them is about being right.
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space(1)),
                  child: Text(
                    s.progressEmptyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(s.progressEmptyBody,
                    style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: tokens.space(2)),
                Text(s.progressWhatIsMeasured,
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: tokens.space(1)),
                for (final (i, skill) in s.skillPreview.indexed)
                  RevealOnScroll(
                    delayIndex: i,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: tokens.space(1.25)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: tokens.textMuted),
                          SizedBox(width: tokens.space(1)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(skill.what,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: tokens.space(2)),
                // The only thing that changes any of this is finishing a
                // mission, so the screen offers that rather than leaving
                // the learner to work out where to go.
                if (onGoToPath != null)
                  ElevatedButton.icon(
                    onPressed: onGoToPath,
                    icon: const Icon(Icons.route_outlined),
                    label: Text(s.progressEmptyAction),
                  ),
              ] else
                for (var i = 0; i < progress.skills.length; i++)
                  RevealOnScroll(
                    delayIndex: i,
                    // Each meter opens the skill behind it: a percentage
                    // with no explanation tells a learner they are at 40%
                    // of something they cannot name.
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SkillScreen(skill: progress.skills[i]),
                        ),
                      ),
                      child: SkillMeter(
                        label: s.skillName(progress.skills[i].skill),
                        mastery: progress.skills[i].mastery,
                        masteryLabel:
                            s.masteryPercent((progress.skills[i].mastery * 100).round()),
                        dueLabel: progress.skills[i].dueAt == null ? null : s.boosterDue,
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

