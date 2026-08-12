import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';

/// What a mission is, before committing to it.
///
/// Tapping a node used to drop the learner straight into a prediction
/// with no idea what they were walking into. This shows the claim, the
/// skills it trains and the checks available, so starting is a choice
/// rather than a surprise.
///
/// Returns true when the learner chose to start.
Future<bool> showMissionSheet({
  required BuildContext context,
  required Mission mission,
  required String chapterTitle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MissionSheet(mission: mission, chapterTitle: chapterTitle),
  );
  return result ?? false;
}

class _MissionSheet extends StatelessWidget {
  const _MissionSheet({required this.mission, required this.chapterTitle});

  final Mission mission;
  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    // Roughly a minute of reading plus half a minute per check. Honest
    // enough to help someone decide whether they have time now, and
    // labelled "about" so it never reads as a promise.
    final minutes = 1 + (mission.evidenceActions.length * 0.5).ceil();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            tokens.space(3),
            0,
            tokens.space(3),
            tokens.space(3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(chapterTitle, style: Theme.of(context).textTheme.bodySmall),
              Text(mission.title, style: Theme.of(context).textTheme.headlineMedium),
              const SectionRule(),
              Text(mission.claim, style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: tokens.space(2)),

              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: tokens.textMuted),
                  SizedBox(width: tokens.space(0.5)),
                  Text(
                    s.missionEstimate(minutes),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: tokens.space(2)),

              Text(s.missionSkills, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              Wrap(
                spacing: tokens.space(1),
                runSpacing: tokens.space(1),
                children: [
                  for (final tag in mission.skillTags)
                    Chip(
                      label: Text(s.skillName(tag)),
                      backgroundColor: tokens.surface,
                      side: BorderSide(color: tokens.evidencePrimary),
                    ),
                ],
              ),
              SizedBox(height: tokens.space(2)),

              Text(s.missionChecks, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              Wrap(
                spacing: tokens.space(1),
                runSpacing: tokens.space(1),
                children: [
                  for (final action in mission.evidenceActions)
                    PropTile(
                      prop: propForActionType(action.type),
                      label: action.label,
                      semanticLabel: action.label,
                      // Preview only — the checks are run inside the
                      // mission, not from here.
                      onTap: null,
                    ),
                ],
              ),
              SizedBox(height: tokens.space(3)),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(s.startMission),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
