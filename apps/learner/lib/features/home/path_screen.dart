import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../mission/mission_screen.dart';

/// The skill path — the winding, Duolingo-style map of missions.
///
/// Hosted inside [HomeShell], so it deliberately has no Scaffold of its
/// own. Each node reveals with a small spring as it scrolls into view
/// ([RevealOnScroll]); the animation is decoration only — every node is
/// reachable, labelled and tappable whether or not it has animated.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  late Future<LearningPath> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getLearningPath();
  }

  void _retry() => setState(() => _future = widget.repository.getLearningPath());

  Future<void> _openMission(LearningPathNode node) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionScreen(
          repository: widget.repository,
          missionId: node.missionId,
        ),
      ),
    );
    // Coming back from a finished mission, the path state may have moved on.
    if (mounted) _retry();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return FutureBuilder<LearningPath>(
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
                  ElevatedButton(onPressed: _retry, child: Text(s.retry)),
                ],
              ),
            ),
          );
        }

        final path = snapshot.data!;
        if (path.nodes.isEmpty) {
          return Center(child: Text(s.pathEmpty));
        }

        return ReadableWidth(
          maxWidth: 520,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space(2),
              vertical: tokens.space(3),
            ),
            itemCount: path.nodes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: tokens.space(2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.yourPath, style: Theme.of(context).textTheme.headlineMedium),
                      const SectionRule(),
                    ],
                  ),
                );
              }

              final i = index - 1;
              final node = path.nodes[i];
              final state = switch (node.state) {
                'completed' => PathNodeState.completed,
                'available' => PathNodeState.available,
                _ => PathNodeState.locked,
              };
              // Gentle left/right weave, the way a trail meanders.
              final drift = (i.isEven ? -1.0 : 1.0) * 0.45;

              return RevealOnScroll(
                delayIndex: i,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space(1.5)),
                  child: Align(
                    alignment: Alignment(drift, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PathNode owns its own InkWell; wrapping it in a
                        // Pressable would fire onTap twice.
                        PathNode(
                          title: node.title,
                          state: state,
                          stateLabel: switch (state) {
                            PathNodeState.locked => s.stateLocked,
                            PathNodeState.available => s.stateAvailable,
                            PathNodeState.completed => s.stateCompleted,
                          },
                          onTap: state == PathNodeState.locked
                              ? null
                              : () => _openMission(node),
                        ),
                        SizedBox(height: tokens.space(1)),
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 140,
                            child: Text(
                              node.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
