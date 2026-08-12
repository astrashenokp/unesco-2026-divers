import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/demo_fixtures.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';

/// One evidence skill: what it is, why it is worth having, and which
/// missions train it.
///
/// A mastery bar with no explanation tells a learner they are at 40% of
/// something they cannot name. This is the other half of that number.
class SkillScreen extends StatelessWidget {
  const SkillScreen({super.key, required this.skill});

  final SkillProgress skill;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final code = s.locale.languageCode;

    // Which missions exercise this skill, read from the pack itself so
    // the list cannot drift from the content.
    final missions = demoMissionsFor(code)
        .values
        .where((m) => m.skillTags.contains(skill.skill))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.skillName(skill.skill))),
      body: LivingBackground(
        child: ReadableWidth(
          child: ListView(
            padding: EdgeInsets.all(tokens.space(2)),
            children: [
              SkillMeter(
                label: s.skillName(skill.skill),
                mastery: skill.mastery,
                masteryLabel: s.masteryPercent((skill.mastery * 100).round()),
                dueLabel: skill.dueAt == null ? null : s.boosterDue,
              ),
              SizedBox(height: tokens.space(3)),

              Text(s.skillWhy, style: Theme.of(context).textTheme.titleLarge),
              const SectionRule(),
              Text(
                s.skillWhyText(skill.skill),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: tokens.space(3)),

              Text(s.skillTrainedBy, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              if (missions.isEmpty)
                Text(s.pathEmpty, style: Theme.of(context).textTheme.bodyMedium)
              else
                for (final (index, mission) in missions.indexed)
                  RevealOnScroll(
                    delayIndex: index,
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.explore_outlined, color: tokens.action),
                        title: Text(mission.title),
                        // The claim is the thing under investigation, so
                        // it wraps rather than truncating. Two lines plus
                        // an ellipsis is already thin at 100% and cuts
                        // most claims mid-sentence at 200% text scale —
                        // exactly the setting used by the people least
                        // able to guess the rest.
                        isThreeLine: true,
                        subtitle: Text(
                          mission.claim,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
              SizedBox(height: tokens.space(3)),
            ],
          ),
        ),
      ),
    );
  }
}
