import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';

/// Skill mastery and process XP.
///
/// Frames XP as a record of *how* the learner investigates — the
/// "XP is never evidence that a person is intelligent or trustworthy"
/// rule from `GAME_AND_LEARNING_DESIGN.md` is printed on the screen, not
/// just honoured in the scoring.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.repository});

  final MissionRepository repository;

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
          final message = snapshot.error is EvidenceGymApiException
              ? (snapshot.error! as EvidenceGymApiException).problem.title
              : s.pathError;
          return _ErrorState(message: message, retryLabel: s.retry, onRetry: _retry);
        }

        final progress = snapshot.data!;
        return ReadableWidth(
          child: ListView(
            padding: EdgeInsets.all(tokens.space(2)),
            children: [
              Text(s.profileTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SectionRule(),
              Row(
                children: [
                  const Lupa(mood: LupaMood.idle, size: 64),
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
              if (progress.skills.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space(2)),
                  child: Text(s.profileEmpty, style: Theme.of(context).textTheme.bodyLarge),
                )
              else
                for (var i = 0; i < progress.skills.length; i++)
                  RevealOnScroll(
                    delayIndex: i,
                    child: SkillMeter(
                      label: s.skillName(progress.skills[i].skill),
                      mastery: progress.skills[i].mastery,
                      masteryLabel:
                          s.masteryPercent((progress.skills[i].mastery * 100).round()),
                      dueLabel: progress.skills[i].dueAt == null ? null : s.boosterDue,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space(3)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Lupa(mood: LupaMood.thinking, size: 80),
            SizedBox(height: tokens.space(2)),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: tokens.space(2)),
            ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
