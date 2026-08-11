import 'package:flutter/material.dart';

/// User-controlled presentation settings.
///
/// These are deliberately *presentation only* — nothing here changes what
/// the server scores or awards, so a learner can adapt the interface to
/// themselves without changing the learning contract.
///
/// NOTE: not persisted yet — settings reset when the app restarts.
/// Wiring `shared_preferences` here is a small, self-contained follow-up.
class AppSettings extends ChangeNotifier {
  AppSettings({
    Locale locale = const Locale('uk'),
    bool simpleLanguage = false,
    bool forceReduceMotion = false,
    double textScale = 1.0,
  })  : _locale = locale,
        _simpleLanguage = simpleLanguage,
        _forceReduceMotion = forceReduceMotion,
        _textScale = textScale;

  Locale _locale;
  bool _simpleLanguage;
  bool _forceReduceMotion;
  double _textScale;

  Locale get locale => _locale;
  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
  }

  /// Shorter sentences and plainer words across explanatory copy — for
  /// younger learners, non-native readers, and anyone who finds dense
  /// text tiring. It never hides a safety or provenance caveat.
  bool get simpleLanguage => _simpleLanguage;
  set simpleLanguage(bool value) {
    if (_simpleLanguage == value) return;
    _simpleLanguage = value;
    notifyListeners();
  }

  /// In-app switch on top of the OS-level reduce-motion setting, which is
  /// still respected independently. This can only ever *add* calm.
  bool get forceReduceMotion => _forceReduceMotion;
  set forceReduceMotion(bool value) {
    if (_forceReduceMotion == value) return;
    _forceReduceMotion = value;
    notifyListeners();
  }

  /// 1.0–2.0. The layout is required to survive 200% without clipping,
  /// so this slider is also how we make that testable by hand.
  double get textScale => _textScale;
  set textScale(double value) {
    final clamped = value.clamp(1.0, 2.0);
    if (_textScale == clamped) return;
    _textScale = clamped;
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
