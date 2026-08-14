import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';
import 'leaderboard_screen.dart';

/// Loads the board and owns the opt-in decision.
///
/// Separate from [LeaderboardScreen] so that screen stays a pure
/// rendering of a list — which is what makes its rules easy to check by
/// reading it.
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  late Future<List<BoardEntry>> _future = widget.repository.getLeaderboard();

  Future<void> _join() async {
    final handle = await _askForHandle();
    if (handle == null || handle.trim().isEmpty) return;
    widget.repository.joinBoard(handle.trim());
    setState(() => _future = widget.repository.getLeaderboard());
  }

  void _leave() {
    widget.repository.leaveBoard();
    setState(() => _future = widget.repository.getLeaderboard());
  }

  Future<String?> _askForHandle() {
    final s = Strings.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.boardJoinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.boardJoinBody),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: s.boardHandleLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
            ),
            // Said at the moment of choosing, not only in a policy. A
            // learner about to type something is the person who needs to
            // know it will be visible to others.
            Text(s.boardHandleHint,
                style: Theme.of(dialogContext).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(s.boardJoin),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BoardEntry>>(
      future: _future,
      builder: (context, snapshot) {
        return LeaderboardScreen(
          repository: widget.repository,
          entries: snapshot.data ?? const [],
          participating: widget.repository.boardHandleSet,
          onJoin: _join,
          onLeave: _leave,
        );
      },
    );
  }
}
