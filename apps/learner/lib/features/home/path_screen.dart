import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/demo_fixtures.dart';
import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import '../mission/mission_screen.dart';
import 'mission_sheet.dart';
import 'stat_tile.dart';

/// The skill path — the winding map of missions, and the app's home.
///
/// Hosted inside `HomeShell`, so it has no Scaffold of its own. On a
/// laptop the map keeps its own column and a side panel carries the
/// greeting and stats, because a single narrow column centred in a 1920px
/// window reads as an unfinished page.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  late Future<({LearningPath path, Progress progress})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({LearningPath path, Progress progress})> _load() async {
    final path = await widget.repository.getLearningPath();
    final progress = await widget.repository.getMyProgress();
    return (path: path, progress: progress);
  }

  void _retry() => setState(() => _future = _load());

  Future<void> _openMission(LearningPathNode node) async {
    // Show what the mission is before committing to it. If the mission
    // cannot be fetched, fall through and let the mission screen show
    // the failure rather than swallowing it here.
    try {
      final mission = await widget.repository.getMission(node.missionId);
      if (!mounted) return;
      final chapter = demoChapterOf[node.missionId];
      final start = await showMissionSheet(
        context: context,
        mission: mission,
        chapterTitle: chapter == null
            ? ''
            : demoChapterTitle(chapter, Strings.of(context).locale.languageCode),
      );
      if (!start || !mounted) return;
    } catch (_) {
      // Fall through to the mission screen, which reports properly.
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionScreen(
          repository: widget.repository,
          missionId: node.missionId,
        ),
      ),
    );
    // The path and the XP total may both have moved on.
    if (mounted) _retry();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return FutureBuilder<({LearningPath path, Progress progress})>(
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

        final path = snapshot.data!.path;
        final progress = snapshot.data!.progress;
        final completed = path.nodes.where((n) => n.state == 'completed').length;

        LearningPathNode? next;
        for (final n in path.nodes) {
          if (n.state == 'available') {
            next = n;
            break;
          }
        }
        final resume = next;

        final header = _PathHeader(
          completed: completed,
          total: path.nodes.length,
          totalXp: progress.totalXp,
          next: resume,
          onContinue: resume == null ? null : () => _openMission(resume),
        );

        final map = _PathMap(nodes: path.nodes, onOpen: _openMission);

        if (formFactorOf(context).isWide) {
          // One scroll area, not two. Independent scrollables put a
          // scrollbar down the middle of the workspace and split it in
          // half visually; the whole thing moves together now.
          //
          // Fixed column widths rather than flex shares: with flex, the
          // map floated in the middle of a column far wider than it
          // needed while the panel drifted toward the window edge. Sized
          // columns sit side by side with no dead space between them,
          // and the pair is centred as one block.
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.tokens.space(2),
                    vertical: context.tokens.space(2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 520, child: map),
                      SizedBox(width: context.tokens.space(3)),
                      Expanded(child: header),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ReadableWidth(
          maxWidth: 520,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.tokens.space(2),
                  context.tokens.space(2),
                  context.tokens.space(2),
                  0,
                ),
                sliver: SliverToBoxAdapter(child: header),
              ),
              SliverToBoxAdapter(child: map),
            ],
          ),
        );
      },
    );
  }
}

class _PathHeader extends StatelessWidget {
  const _PathHeader({
    required this.completed,
    required this.total,
    required this.totalXp,
    required this.next,
    required this.onContinue,
  });

  final int completed;
  final int total;
  final int totalXp;

  /// The first mission still open, if any.
  final LearningPathNode? next;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.yourPath, style: Theme.of(context).textTheme.headlineMedium),
        const SectionRule(),
        SizedBox(height: tokens.space(1)),
        LupaGreeting(lines: s.lupaPathLines(completed: completed, total: total)),
        SizedBox(height: tokens.space(2)),
        Wrap(
          spacing: tokens.space(1),
          runSpacing: tokens.space(1),
          children: [
            StatTile(
              icon: Icons.workspace_premium_outlined,
              value: s.statXp(totalXp),
              label: s.statXpLabel,
              tint: tokens.evidenceSecondary,
              count: totalXp,
              format: s.statXp,
            ),
            StatTile(
              icon: Icons.local_fire_department_outlined,
              value: s.statStreak(completed),
              label: s.statStreakLabel,
              tint: tokens.action,
            ),
            StatTile(
              icon: Icons.flag_outlined,
              value: s.statGoal(completed, total),
              label: s.statGoalLabel,
              tint: tokens.evidencePrimary,
            ),
          ],
        ),
        SizedBox(height: tokens.space(1)),
        Text(
          s.pathProgress(completed, total),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (next != null) ...[
          SizedBox(height: tokens.space(2)),
          // One tap back into the thread, rather than hunting the map
          // for where you stopped.
          Card(
            child: InkWell(
              onTap: onContinue,
              borderRadius: BorderRadius.circular(tokens.space(2)),
              child: Padding(
                padding: EdgeInsets.all(tokens.space(2)),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline, color: tokens.action),
                    SizedBox(width: tokens.space(1.5)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.continueTitle,
                              style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            next!.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        s.continueAction,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.action, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PathMap extends StatelessWidget {
  const _PathMap({required this.nodes, required this.onOpen});

  final List<LearningPathNode> nodes;
  final ValueChanged<LearningPathNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    if (nodes.isEmpty) {
      // An empty path is a real state, not a mistake — say so with the
      // same warmth as the rest of the screen rather than a bare line.
      return Padding(
        padding: EdgeInsets.all(tokens.space(4)),
        child: Column(
          children: [
            Lupa(mood: LupaMood.thinking, size: 110, semanticLabel: s.lupaLabel('thinking')),
            SizedBox(height: tokens.space(2)),
            Text(
              s.pathEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: tokens.space(1)),
            Text(
              s.profileEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final code = s.locale.languageCode;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space(3)),
      child: Column(
        children: [
          for (var i = 0; i < nodes.length; i++) ...[
            // A chapter heading appears wherever the chapter changes, so
            // the map reads as sections rather than one long ribbon.
            if (_chapterStartsAt(i)) _ChapterHeading(nodes: nodes, index: i, code: code),
            if (i > 0 && !_chapterStartsAt(i))
              PathTrail(
                fromLeft: (i - 1).isEven,
                reached: nodes[i - 1].state == 'completed',
              ),
            RevealOnScroll(
              delayIndex: i,
              child: Align(
                alignment: Alignment((i.isEven ? -1.0 : 1.0) * 0.45, 0),
                child: _PathStop(
                  node: nodes[i],
                  index: i,
                  total: nodes.length,
                  chapterTitle: _titleFor(nodes[i].missionId, code),
                  onOpen: onOpen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _chapterStartsAt(int i) {
    if (i == 0) return true;
    return demoChapterOf[nodes[i].missionId] != demoChapterOf[nodes[i - 1].missionId];
  }

  static String _titleFor(String missionId, String code) {
    final chapter = demoChapterOf[missionId];
    return chapter == null ? '' : demoChapterTitle(chapter, code);
  }
}

class _ChapterHeading extends StatelessWidget {
  const _ChapterHeading({
    required this.nodes,
    required this.index,
    required this.code,
  });

  final List<LearningPathNode> nodes;
  final int index;
  final String code;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final chapter = demoChapterOf[nodes[index].missionId];
    if (chapter == null) return const SizedBox.shrink();

    final inChapter =
        nodes.where((n) => demoChapterOf[n.missionId] == chapter).toList();
    final done = inChapter.where((n) => n.state == 'completed').length;

    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : tokens.space(4),
        bottom: tokens.space(2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demoChapterTitle(chapter, code),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  s.chapterProgress(done, inChapter.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Slid(width: 72, height: 22, steps: inChapter.length, reached: done),
        ],
      ),
    );
  }
}

class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.node,
    required this.index,
    required this.total,
    required this.chapterTitle,
    required this.onOpen,
  });

  final LearningPathNode node;
  final int index;
  final int total;
  final String chapterTitle;
  final ValueChanged<LearningPathNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    final state = switch (node.state) {
      'completed' => PathNodeState.completed,
      'available' => PathNodeState.available,
      _ => PathNodeState.locked,
    };
    final locked = state == PathNodeState.locked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PathNode(
          // Position is spoken, so a screen-reader user knows where they
          // are on the map without seeing it.
          // The lock reason is spoken here because the only other copy
          // lives inside an ExcludeSemantics block below — a blind
          // learner heard "locked" and never why.
          title: locked
              ? '${node.title}, ${s.nodePosition(index + 1, total, chapterTitle)}, ${s.lockedReason}'
              : '${node.title}, ${s.nodePosition(index + 1, total, chapterTitle)}',
          state: state,
          stateLabel: switch (state) {
            PathNodeState.locked => s.stateLocked,
            PathNodeState.available => s.stateAvailable,
            PathNodeState.completed => s.stateCompleted,
          },
          heroTag: 'mission-${node.missionId}',
          onTap: locked ? null : () => onOpen(node),
        ),
        SizedBox(height: tokens.space(1)),
        ExcludeSemantics(
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                Text(
                  node.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: locked ? FontWeight.w400 : FontWeight.w700,
                        color: locked ? tokens.textMuted : tokens.textPrimary,
                      ),
                ),
                // A padlock alone does not say what would unlock it.
                if (locked)
                  Text(
                    s.lockedReason,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
