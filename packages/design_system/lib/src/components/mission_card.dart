import 'package:flutter/material.dart';

import '../tokens.dart';

/// Summary card for a mission on the path/home screen.
class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.title,
    required this.skillTags,
    this.onTap,
  });

  final String title;
  final List<String> skillTags;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.space(2)),
        child: Padding(
          padding: EdgeInsets.all(tokens.space(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              Wrap(
                spacing: tokens.space(1),
                runSpacing: tokens.space(1),
                children: [
                  for (final tag in skillTags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: tokens.surface,
                      side: BorderSide(color: tokens.evidencePrimary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
