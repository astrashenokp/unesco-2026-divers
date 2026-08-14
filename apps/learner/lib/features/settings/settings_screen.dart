import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../app_settings.dart';
import '../../data/audience.dart';
import '../../l10n/strings.dart';
import 'language_picker.dart';

/// Accessibility and language settings.
///
/// Deliberately the third top-level destination rather than buried in a
/// profile menu: for the learners who need these controls, finding them
/// is the difference between using the app and closing it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.cachedCount = 0,
    this.onPrefetchChanged,
  });

  /// Missions currently held on the device.
  final int cachedCount;

  /// Lets the shell tell the repository to start or stop caching, and to
  /// drop what it holds.
  final ValueChanged<bool>? onPrefetchChanged;

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
          // One button that opens the list, rather than one segment per
          // language. A segmented control is fine at two and breaks at
          // three — it grows sideways until it wraps, and every option
          // costs horizontal space whether anyone wants it or not.
          // Better to have the shape that scales before a third language
          // arrives than after.
          const LanguageButton(),
          SizedBox(height: tokens.space(3)),

          // -------------------------------------------------------- audience
          Text(s.audienceLabel, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          SegmentedButton<AudienceMode>(
            segments: [
              ButtonSegment(
                value: AudienceMode.adult,
                icon: const Icon(Icons.person_outline),
                label: Text(s.audienceAdult),
              ),
              ButtonSegment(
                value: AudienceMode.child,
                icon: const Icon(Icons.child_care_outlined),
                label: Text(s.audienceChild),
              ),
            ],
            selected: {settings.audience},
            onSelectionChanged: (selection) =>
                settings.audience = selection.first,
          ),
          SizedBox(height: tokens.space(0.5)),
          Text(
            settings.audience == AudienceMode.child
                ? s.audienceChildBody
                : s.audienceAdultBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: tokens.space(0.5)),
          // Repeated here as well as on the first screen. Someone
          // handing a device to a child is most likely to look in
          // settings, and that is exactly the person who must not
          // mistake this for a lock.
          Text(s.audienceNotAGate,
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: tokens.space(3)),

          // ------------------------------------------------------ appearance
          Text(s.appearanceLabel, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          // Three options, not a switch. A two-state switch forces a
          // choice the learner may not have: "follow my device" is the
          // honest default and has to stay reachable after they try the
          // others. Icons sit beside the labels rather than replacing
          // them, so the control does not depend on recognising a glyph.
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(s.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(s.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(s.themeDark),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.themeMode = selection.first,
          ),
          SizedBox(height: tokens.space(0.5)),
          Text(s.themeHint, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: tokens.space(3)),

          // ------------------------------------------------------- offline
          Text(s.offlineLabel, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          SwitchListTile(
            value: settings.prefetchMissions,
            onChanged: (v) {
              settings.prefetchMissions = v;
              // Turning it off drops what is already held, rather than
              // merely stopping new downloads. A switch that leaves the
              // old cache on disk has not been turned off.
              onPrefetchChanged?.call(v);
            },
            title: Text(s.prefetchLabel),
            subtitle: Text(s.prefetchHint),
            contentPadding: EdgeInsets.zero,
          ),
          // What is actually on the device, not what the setting intends.
          // The switch shipped before the cache did, and a promise with
          // nothing behind it is the thing this product exists to argue
          // against.
          Padding(
            padding: EdgeInsets.only(left: tokens.space(0.5)),
            child: Text(
              cachedCount > 0 ? s.prefetchReady(cachedCount) : s.prefetchNone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
