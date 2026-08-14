import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mission_repository.dart';
import '../../data/arenas.dart';
import '../../data/gameplay.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import '../receipt/receipt_screen.dart';

/// Who the learner is here, and what the app holds about them.
///
/// Two things this screen exists to say plainly: that a guest is not
/// tracked by name, and that everything held can be taken away. Both are
/// commitments from `PRIVACY.md`, and a privacy promise that lives only
/// in a policy document is not a promise a learner can act on.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<
      ({
        Progress progress,
        List<Receipt> receipts,
        LearningPath path,
        List<ProcessLevel> rubric,
      })> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _retry() => setState(() => _future = _load());

  Future<
      ({
        Progress progress,
        List<Receipt> receipts,
        LearningPath path,
        List<ProcessLevel> rubric,
      })> _load() async {
    final progress = await widget.repository.getMyProgress();
    final receipts = await widget.repository.listReceipts();
    final path = await widget.repository.getLearningPath();

    // The ladder comes off a real mission rather than a hardcoded demo
    // copy. The first version of this called `demoRubric()` directly,
    // which would have shown demo content to a live learner as though it
    // were the rubric they are actually scored against — the same class
    // of mistake as the invented streak that had to be removed from the
    // path header.
    //
    // Allowed to come back empty: no mission, no ladder, and the section
    // is simply absent rather than filled with a plausible stand-in.
    var rubric = const <ProcessLevel>[];
    if (path.nodes.isNotEmpty) {
      try {
        rubric = (await widget.repository.getMission(path.nodes.first.missionId))
            .rubric;
      } catch (_) {
        // The profile is worth showing without it.
      }
    }

    return (
      progress: progress,
      receipts: receipts,
      path: path,
      rubric: rubric,
    );
  }

  Future<void> _export(Progress progress, List<Receipt> receipts) async {
    // Everything held, as readable text. Deliberately plain rather than
    // a download: it works identically on web and mobile, and the
    // learner can see exactly what they are taking before pasting it.
    final s = Strings.of(context);
    final buffer = StringBuffer()
      ..writeln('Evidence Gym — ${s.exportData}')
      ..writeln(DateTime.now().toIso8601String())
      ..writeln()
      ..writeln('XP: ${progress.totalXp}');

    for (final skill in progress.skills) {
      buffer.writeln('${skill.skill}: ${(skill.mastery * 100).round()}%');
    }
    buffer.writeln();
    for (final receipt in receipts) {
      buffer.writeln('${receipt.id}  ${receipt.createdAt.toIso8601String()}');
      for (final a in receipt.assessments) {
        buffer.writeln('  ${a.label} (${a.confidence}%)');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.exportCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return FutureBuilder<
        ({
          Progress progress,
          List<Receipt> receipts,
          LearningPath path,
          List<ProcessLevel> rubric,
        })>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Semantics(label: s.loading, child: const CircularProgressIndicator()),
          );
        }

        // Without this a failed load rendered as "Guest, 0 XP, no
        // receipts" — a network error presented as an empty account.
        if (snapshot.hasError) {
          return FailureView(
            error: snapshot.error,
            onRetry: _retry,
            isDemo: widget.repository.isDemo,
          );
        }

        final progress = snapshot.data!.progress;
        final receipts = snapshot.data!.receipts;
        final nodes = snapshot.data!.path.nodes;
        final rubric = snapshot.data!.rubric;

        return ReadableWidth(
          child: ListView(
            padding: EdgeInsets.all(tokens.space(2)),
            children: [
              Row(
                children: [
                  Lupa(mood: LupaMood.idle, size: 72, semanticLabel: s.lupaLabel('idle')),
                  SizedBox(width: tokens.space(2)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.youGuest,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(s.statXp(progress.totalXp),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SectionRule(),
              Text(s.guestExplained, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: tokens.space(2)),

              // The streak belongs here as much as on the path —
              // `packages/gameplay` calls it "a profile signal only",
              // and the profile is where someone looks to see how they
              // are doing rather than what to do next.
              Builder(builder: (context) {
                final streak = widget.repository.streak;
                final paused = streak.isPaused(DateTime.now());
                return Container(
                  padding: EdgeInsets.all(tokens.space(1.75)),
                  decoration: BoxDecoration(
                    color: tokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(tokens.space(2)),
                    border: Border.all(
                      color: tokens.textMuted.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        paused
                            ? Icons.pause_circle_outline
                            : Icons.local_fire_department_outlined,
                        color: paused
                            ? tokens.textMuted
                            : tokens.evidenceSecondary,
                      ),
                      SizedBox(width: tokens.space(1.5)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paused
                                  ? s.streakPaused
                                  : (streak.current == 0
                                      ? s.streakNone
                                      : '${s.streakDays(streak.current)} ${s.streakLabel}'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                            Text(
                              paused ? s.streakPausedExplain : s.streakExplain,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: tokens.space(3)),

              // Where the work actually went. Total XP says how much;
              // this says on what, which is the question someone opens
              // their own profile to answer.
              Text(s.byArenaTitle, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              for (final arena in kArenaOrder)
                Builder(builder: (context) {
                  final inArena = nodes
                      .where((n) => demoArenaOf[n.missionId] == arena)
                      .toList();
                  if (inArena.isEmpty) return const SizedBox.shrink();
                  final done =
                      inArena.where((n) => n.state == 'completed').length;
                  return Padding(
                    padding: EdgeInsets.only(bottom: tokens.space(1)),
                    child: SkillMeter(
                      label: s.arenaTitleOf(arena.name),
                      mastery: done / inArena.length,
                      masteryLabel: s.arenaProgress(done, inArena.length),
                      segments: inArena.length,
                    ),
                  );
                }),
              SizedBox(height: tokens.space(3)),

              // The ladder is here as a reference, with no rung marked:
              // on a receipt it explains a score just given, and here it
              // answers "what am I being measured on" before the next
              // mission rather than after it.
              if (rubric.isNotEmpty) ...[
                Text(s.ladderTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: tokens.space(0.5)),
                Text(s.ladderIntro,
                    style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: tokens.space(1.5)),
                LevelLadder(
                  rungs: [
                    for (final rung in rubric)
                      LadderRung(
                        level: rung.level,
                        criteria: rung.criteria,
                        xp: rung.xpGuidance,
                      ),
                  ],
                  reached: null,
                  levelLabel: s.ladderLevel,
                  xpLabel: s.ladderXp,
                ),
                SizedBox(height: tokens.space(3)),
              ],

              Text(s.historyTitle, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              if (receipts.isEmpty)
                Text(s.historyEmpty, style: Theme.of(context).textTheme.bodyMedium)
              else
                for (final (index, receipt) in receipts.indexed)
                  RevealOnScroll(
                    delayIndex: index,
                    child: Card(
                      // `onFocusChange: null` sat here with a comment
                      // claiming it made the tile announce as a button.
                      // It is the parameter's default and does nothing;
                      // ListTile's InkWell carries the tap action but
                      // never sets the button flag. This is the node that
                      // actually declares the role.
                      child: Builder(builder: (context) {
                        void open() => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  repository: widget.repository,
                                  receiptId: receipt.id,
                                ),
                              ),
                            );
                        // The role and the action go on the same node.
                        // Declaring `button: true` here while the action
                        // lives on the ListTile's InkWell below leaves a
                        // node that announces as a button and does
                        // nothing when activated — the exact defect
                        // semantics_test.dart was written to catch.
                        return Semantics(
                          button: true,
                          onTap: open,
                          child: ListTile(
                            leading: Icon(Icons.receipt_long_outlined,
                                color: tokens.evidencePrimary),
                            title: Text(s.receiptNumbered(index + 1)),
                            subtitle: Text(
                              s.formatDateTime(receipt.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: open,
                          ),
                        );
                      }),
                    ),
                  ),
              SizedBox(height: tokens.space(3)),

              OutlinedButton.icon(
                onPressed: () => _export(progress, receipts),
                icon: const Icon(Icons.download_outlined),
                label: Text(s.exportData),
              ),
              SizedBox(height: tokens.space(0.5)),
              Text(s.exportExplained, style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: tokens.space(3)),
            ],
          ),
        );
      },
    );
  }
}
