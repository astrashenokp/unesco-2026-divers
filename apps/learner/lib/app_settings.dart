import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences? store,
  })  : _locale = locale,
        _simpleLanguage = simpleLanguage,
        _forceReduceMotion = forceReduceMotion,
        _textScale = textScale,
        _store = store;

  static const _kLocale = 'settings.locale';
  static const _kSimple = 'settings.simpleLanguage';
  static const _kReduceMotion = 'settings.forceReduceMotion';
  static const _kTextScale = 'settings.textScale';

  final SharedPreferences? _store;

  Locale _locale;
  bool _simpleLanguage;
  bool _forceReduceMotion;
  double _textScale;

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

  /// Shorter sentences and plainer words across explanatory copy — for
  /// younger learners, non-native readers, and anyone who finds dense
  /// text tiring. It never hides a safety or provenance caveat.
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
