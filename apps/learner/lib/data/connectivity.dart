import 'package:flutter/widgets.dart';

/// Whether the app currently believes it can reach the API.
///
/// Deliberately **not** a network-interface check. A device can be on
/// wi-fi with no route out, behind a captive portal, or facing a server
/// that is simply down — and all three feel identical to a learner. What
/// matters is whether our requests are getting answers, so this is
/// driven by the outcome of real calls rather than by the radio.
///
/// It is therefore always slightly behind reality: it learns the network
/// is gone from the first request that fails, not before. That is the
/// honest trade, and it is why nothing in the UI is gated on this — it
/// changes how things are *described*, never what is *allowed*. A
/// learner who is actually online must never be locked out by a stale
/// flag.
class Connectivity extends ChangeNotifier {
  Connectivity({bool online = true}) : _online = online;

  bool _online;
  bool get isOnline => _online;

  /// Called by the repository after every request.
  void report({required bool reachable}) {
    if (_online == reachable) return;
    _online = reachable;
    notifyListeners();
  }
}

/// Provides [Connectivity] and rebuilds dependents when it changes.
class ConnectivityScope extends InheritedNotifier<Connectivity> {
  const ConnectivityScope({
    super.key,
    required Connectivity connectivity,
    required super.child,
  }) : super(notifier: connectivity);

  /// Returns the shared instance, or a permanently-online stand-in when
  /// there is no scope above — tests and previews should not have to
  /// build one to render a widget that merely asks.
  static Connectivity of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConnectivityScope>()?.notifier ??
      Connectivity();
}
