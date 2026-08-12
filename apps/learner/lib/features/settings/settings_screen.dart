import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../app_settings.dart';
import '../../l10n/strings.dart';

/// Accessibility and language settings.
///
/// Deliberately the third top-level destination rather than buried in a
/// profile menu: for the learners who need these controls, finding them
/// is the difference between using the app and closing it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final settings = AppSettingsScope.of(context);
    final tokens = context.tokens;

    return ReadableWidth(
      child: ListView(
        padding: EdgeInsets.all(tokens.space(2)),
        children: [
          Text(s.settingsTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SectionRule(),

          // ------------------------------------------------------ language
          Text(s.languageLabel, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'uk', label: Text('Українська')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {settings.locale.languageCode},
            onSelectionChanged: (selection) =>
                settings.locale = Locale(selection.first),
          ),
          SizedBox(height: tokens.space(3)),

          // --------------------------------------------- reading and motion
          Text(s.readingLabel, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          SwitchListTile(
            value: settings.simpleLanguage,
            onChanged: (v) => settings.simpleLanguage = v,
            title: Text(s.simpleLanguageLabel),
            subtitle: Text(s.simpleLanguageHint),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: settings.forceReduceMotion,
            onChanged: (v) => settings.forceReduceMotion = v,
            title: Text(s.reduceMotionLabel),
            subtitle: Text(s.reduceMotionHint),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: tokens.space(2)),

          // ----------------------------------------------------- text size
          Text(s.textSizeLabel, style: Theme.of(context).textTheme.bodyLarge),
          // The Slider carries its own slider semantics; an outer
          // Semantics node produced two announcements, the inner one
          // reporting 0% while sitting at 100%. The label now comes from
          // semanticFormatterCallback on the Slider itself, which is the
          // one node assistive technology reads.
          Builder(
            builder: (context) => Slider(
              value: settings.textScale,
              min: 1.0,
              max: 2.0,
              divisions: 4,
              label: s.textSizePercent((settings.textScale * 100).round()),
              semanticFormatterCallback: (v) =>
                  '${s.textSizeLabel} ${s.textSizePercent((v * 100).round())}',
              onChanged: (v) => settings.textScale = v,
            ),
          ),
          Text(
            s.textSizePercent((settings.textScale * 100).round()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
