import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../app_settings.dart';
import '../../l10n/strings.dart';

/// A language, named in its own language.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.endonym,
    required this.flag,
  });

  final String code;

  /// The **endonym** — the language's name in itself, not translated.
  ///
  /// This is the one rule that matters here. Someone looking for
  /// Ukrainian is looking for "Українська", and a list that offers
  /// "Ukrainian" is only usable by people who already read English —
  /// exactly the people who least need the list.
  final String endonym;

  /// A flag, as a hint and never as the label.
  ///
  /// Flags are countries, not languages, and the two do not line up:
  /// English is not England's alone and no flag stands for Arabic. They
  /// are here because they make a familiar row findable at a glance, and
  /// every one is accompanied by its endonym so nothing depends on
  /// recognising it.
  final String flag;
}

/// The languages this build ships.
///
/// Two, honestly. The list is deliberately not padded with locales that
/// have no translations — a picker offering ten languages that fall back
/// to English is worse than one offering two that work.
const kAppLanguages = [
  AppLanguage(code: 'uk', endonym: 'Українська', flag: '🇺🇦'),
  AppLanguage(code: 'en', endonym: 'English', flag: '🇬🇧'),
];

/// One button showing the current language, opening a list of the rest.
///
/// Replaces a segmented control with one segment per language. That
/// pattern is fine at two and breaks at three: it grows sideways until
/// it wraps, and every option costs horizontal space whether or not
/// anyone wants it. A button that opens a sheet costs the same at any
/// number, which is the shape this needs to be before a third language
/// arrives rather than after.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  AppLanguage _current(String code) => kAppLanguages.firstWhere(
        (l) => l.code == code,
        orElse: () => kAppLanguages.first,
      );

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final settings = AppSettingsScope.of(context);
    final current = _current(settings.locale.languageCode);

    return Semantics(
      button: true,
      // The flag is decoration; the spoken label is the language name.
      label: '${s.languageLabel}: ${current.endonym}',
      onTap: () => _open(context, settings),
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: () => _open(context, settings),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space(2),
              vertical: tokens.space(1.5),
            ),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Text(current.flag, style: const TextStyle(fontSize: 22)),
              SizedBox(width: tokens.space(1.5)),
              Expanded(
                child: Text(
                  current.endonym,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AppSettings settings) {
    final s = Strings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = sheetContext.tokens;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.space(2.5),
                  0,
                  tokens.space(2.5),
                  tokens.space(1),
                ),
                child: Text(s.languageLabel,
                    style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              for (final language in kAppLanguages)
                Semantics(
                  // Exclusive choice, so a screen reader announces which
                  // one is on rather than reading four equal buttons.
                  inMutuallyExclusiveGroup: true,
                  checked: language.code == settings.locale.languageCode,
                  label: language.endonym,
                  onTap: () {
                    settings.locale = Locale(language.code);
                    Navigator.of(sheetContext).pop();
                  },
                  child: ExcludeSemantics(
                    child: ListTile(
                      leading: Text(language.flag,
                          style: const TextStyle(fontSize: 26)),
                      title: Text(language.endonym),
                      trailing: language.code == settings.locale.languageCode
                          ? Icon(Icons.check, color: tokens.action)
                          : null,
                      onTap: () {
                        settings.locale = Locale(language.code);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ),
              SizedBox(height: tokens.space(1)),
            ],
          ),
        );
      },
    );
  }
}
