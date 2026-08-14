import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/audience.dart';

/// User-controlled presentation settings.
///
/// Deliberately *presentation only* — nothing here changes what the
/// server scores or awards, so a learner can adapt the interface to
/// themselves without changing the learning contract.
///
/// Choices persist across restarts. For the learners who need larger
/// text or less motion, having to set it again on every launch is the
/// difference between an app they can use and one they abandon.
class AppSettings extends ChangeNotifier {
  AppSettings({
    Locale locale = const Locale('uk'),
    bool simpleLanguage = false,
    bool forceReduceMotion = false,
    double textScale = 1.0,
    ThemeMode themeMode = ThemeMode.system,
    AudienceMode audience = AudienceMode.adult,
    bool prefetchMissions = true,
    SharedPreferences? store,
  })  : _locale = locale,
        _simpleLanguage = simpleLanguage,
        _forceReduceMotion = forceReduceMotion,
        _textScale = textScale,
        _themeMode = themeMode,
        _audience = audience,
        _prefetchMissions = prefetchMissions,
        _store = store;

  static const _kLocale = 'settings.locale';
  static const _kSimple = 'settings.simpleLanguage';
  static const _kReduceMotion = 'settings.forceReduceMotion';
  static const _kTextScale = 'settings.textScale';
  static const _kThemeMode = 'settings.themeMode';
  static const _kAudience = 'settings.audience';
  static const _kPrefetch = 'settings.prefetchMissions';

  final SharedPreferences? _store;

  Locale _locale;
  bool _simpleLanguage;
  bool _forceReduceMotion;
  double _textScale;
  ThemeMode _themeMode;
  AudienceMode _audience;
  bool _prefetchMissions;

  /// Loads saved choices. Falls back to defaults if storage is
  /// unavailable — a settings store that cannot be read must never stop
  /// the app from starting.
  static Future<AppSettings> load() async {
    try {
      final store = await SharedPreferences.getInstance();
      return AppSettings(
        locale: Locale(store.getString(_kLocale) ?? 'uk'),
        simpleLanguage: store.getBool(_kSimple) ?? false,
        forceReduceMotion: store.getBool(_kReduceMotion) ?? false,
        textScale: store.getDouble(_kTextScale) ?? 1.0,
        themeMode: ThemeMode.values.asNameMap()[store.getString(_kThemeMode)] ??
            ThemeMode.system,
        audience: AudienceMode.values.asNameMap()[store.getString(_kAudience)] ??
            AudienceMode.adult,
        prefetchMissions: store.getBool(_kPrefetch) ?? true,
        store: store,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  /// Writes are fire-and-forget: a failed write costs a preference, and
  /// blocking the UI on disk would be a worse trade.
  void _persist(void Function(SharedPreferences store) write) {
    final store = _store;
    if (store == null) return;
    try {
      write(store);
    } catch (_) {
      // Ignored on purpose — see above.
    }
  }

  Locale get locale => _locale;
  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    _persist((s) => s.setString(_kLocale, value.languageCode));
    notifyListeners();
  }

  /// Who this session's content is for.
  ///
  /// The one setting here that is *not* purely presentational: it
  /// changes which missions exist for this learner, because the younger
  /// mode leaves out the harsher case material. It changes nothing about
  /// scoring — the same skills, the same three axes, the same rubric.
  ///
  /// It is a suitability choice, not an access control, and the UI says
  /// so. Anyone can change it here; pretending a soft toggle is a
  /// safeguarding gate would be worse than not having one, because a
  /// school or parent would then rely on it.
  AudienceMode get audience => _audience;
  set audience(AudienceMode value) {
    if (_audience == value) return;
    _audience = value;
    _persist((s) => s.setString(_kAudience, value.name));
    notifyListeners();
  }

  /// Shorter sentences and plainer words across explanatory copy — for
  /// younger learners, non-native readers, and anyone who finds dense
  /// text tiring. It never hides a safety or provenance caveat.
  ///
  /// On in the younger mode unless the learner turns it off. Reading age
  /// and content suitability are not the same thing, so this stays a
  /// separate switch rather than being forced — a twelve-year-old who
  /// reads well should not be handed simplified text they did not ask
  /// for.
  bool get simpleLanguage => _simpleLanguage;
  set simpleLanguage(bool value) {
    if (_simpleLanguage == value) return;
    _simpleLanguage = value;
    _persist((s) => s.setBool(_kSimple, value));
    notifyListeners();
  }

  /// In-app switch on top of the OS-level reduce-motion setting, which is
  /// still respected independently. This can only ever *add* calm.
  bool get forceReduceMotion => _forceReduceMotion;
  set forceReduceMotion(bool value) {
    if (_forceReduceMotion == value) return;
    _forceReduceMotion = value;
    _persist((s) => s.setBool(_kReduceMotion, value));
    notifyListeners();
  }

  /// Keep the next few missions on the device.
  ///
  /// On by default, and the default is the argued part. A learner who
  /// loses connection mid-path with nothing cached simply stops, and the
  /// people most likely to lose connection are the ones this product is
  /// most for. The cost is a little storage and a little data, which is
  /// why it is a switch rather than a silent behaviour — someone paying
  /// per megabyte is entitled to turn it off, and should be able to find
  /// where.
  bool get prefetchMissions => _prefetchMissions;
  set prefetchMissions(bool value) {
    if (_prefetchMissions == value) return;
    _prefetchMissions = value;
    _persist((s) => s.setBool(_kPrefetch, value));
    notifyListeners();
  }

  /// Light, dark, or whatever the device is set to.
  ///
  /// Defaults to [ThemeMode.system], because someone who has set their
  /// phone to dark has already answered this question and should not be
  /// asked twice. The explicit choices exist because the device setting
  /// is often not a preference at all — it is a schedule, or a battery
  /// saver — and a learner reading at night should be able to overrule
  /// it without changing their whole phone.
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _persist((s) => s.setString(_kThemeMode, value.name));
    notifyListeners();
  }

  /// 1.0–2.0. The layout must survive 200% without clipping, so this
  /// slider is also how that gets tested by hand.
  double get textScale => _textScale;
  set textScale(double value) {
    final clamped = value.clamp(1.0, 2.0);
    if (_textScale == clamped) return;
    _textScale = clamped;
    _persist((s) => s.setDouble(_kTextScale, clamped));
    notifyListeners();
  }
}

/// Provides [AppSettings] and rebuilds dependents when it changes.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope?.notifier != null, 'AppSettingsScope is missing above this widget');
    return scope!.notifier!;
  }
}
