import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Missions kept on the device so a lost connection does not end the
/// session.
///
/// The setting for this shipped before the cache did, which meant the
/// switch promised something nothing implemented. This is that
/// something.
///
/// **What is cached and what is not.** Missions and the path are
/// published, reviewed, immutable-per-version content — safe to keep and
/// safe to re-read. Attempts, receipts and progress are not cached at
/// all: they are the learner's own record, they change, and a stale copy
/// shown as current would be the app lying about their own work. An
/// offline learner can therefore *read* a mission but not complete one,
/// which is the honest half of the feature.
///
/// **Storage.** `SharedPreferences`, which on web is `localStorage` —
/// unencrypted and readable by anything else on the origin. That is
/// acceptable for exactly what is here and would not be for anything
/// else, which is the other reason attempts stay out.
class MissionCache {
  MissionCache(this._store);

  final SharedPreferences? _store;

  static const _keyPrefix = 'cache.mission.';
  static const _pathKey = 'cache.path';

  /// How many missions ahead to keep.
  ///
  /// Small on purpose. The point is to survive a tunnel or a dropped
  /// hotspot, not to make the whole pack available offline — that would
  /// be a download the learner did not ask for, on a connection they may
  /// be paying for by the megabyte.
  static const lookahead = 3;

  /// Everything currently held, so the settings screen can say how much
  /// is actually ready rather than describing an intention.
  int get storedCount =>
      _store?.getKeys().where((k) => k.startsWith(_keyPrefix)).length ?? 0;

  Mission? readMission(String id) {
    final raw = _store?.getString('$_keyPrefix$id');
    if (raw == null) return null;
    try {
      return Mission.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A cache entry that no longer parses is a cache entry from an
      // older build. Treated as absent rather than as an error — the
      // network copy is authoritative anyway.
      return null;
    }
  }

  Future<void> writeMission(String id, Map<String, dynamic> json) async {
    try {
      await _store?.setString('$_keyPrefix$id', jsonEncode(json));
    } catch (_) {
      // Storage full or unavailable. Losing a cache entry costs nothing
      // that a working connection does not restore, so it must never
      // surface as an error to the learner.
    }
  }

  LearningPath? readPath() {
    final raw = _store?.getString(_pathKey);
    if (raw == null) return null;
    try {
      return LearningPath.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writePath(Map<String, dynamic> json) async {
    try {
      await _store?.setString(_pathKey, jsonEncode(json));
    } catch (_) {
      // As above.
    }
  }

  /// Removes everything held.
  ///
  /// Needed because the setting can be turned off, and a switch that
  /// stops adding to a cache while leaving the old one on disk has not
  /// really been turned off.
  Future<void> clear() async {
    final store = _store;
    if (store == null) return;
    try {
      for (final key in store.getKeys().toList()) {
        if (key.startsWith(_keyPrefix) || key == _pathKey) {
          await store.remove(key);
        }
      }
    } catch (_) {
      // Nothing useful to do, and nothing the learner can act on.
    }
  }
}
