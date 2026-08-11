import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import '../mission/mission_screen.dart';
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

        final header = _PathHeader(
          completed: completed,
          total: path.nodes.length,
          totalXp: progress.totalXp,
        );

        final map = _PathMap(nodes: path.nodes, onOpen: _openMission);

        if (formFactorOf(context).isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map column, kept to a comfortable measure. It scrolls on
              // its own: a Row gives its children a bounded height, so an
              // unscrollable Column here overflows as soon as the path is
              // taller than the window.
              Expanded(
                flex: 3,
                child: ReadableWidth(
                  maxWidth: 520,
                  child: SingleChildScrollView(child: map),
                ),
              ),
              // Side panel: the greeting and stats that would otherwise
              // push the map down on a phone.
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.tokens.space(3)),
                  child: header,
                ),
              ),
            ],
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
  });

  final int completed;
  final int total;
  final int totalXp;

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
        LupaGreeting(line: s.lupaPathLine(completed: completed, total: total)),
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
      return Padding(
        padding: EdgeInsets.all(tokens.space(4)),
        child: Column(
          children: [
            const Lupa(mood: LupaMood.thinking, size: 96),
            SizedBox(height: tokens.space(2)),
            Text(s.pathEmpty, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space(3)),
      child: Column(
        children: [
          for (var i = 0; i < nodes.length; i++) ...[
            if (i > 0)
              PathTrail(
                fromLeft: (i - 1).isEven,
                reached: nodes[i - 1].state == 'completed',
              ),
            RevealOnScroll(
              delayIndex: i,
              child: Align(
                alignment: Alignment((i.isEven ? -1.0 : 1.0) * 0.45, 0),
                child: _PathStop(node: nodes[i], onOpen: onOpen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PathStop extends StatelessWidget {
  const _PathStop({required this.node, required this.onOpen});

  final LearningPathNode node;
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
          title: node.title,
          state: state,
          stateLabel: switch (state) {
            PathNodeState.locked => s.stateLocked,
            PathNodeState.available => s.stateAvailable,
            PathNodeState.completed => s.stateCompleted,
          },
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
