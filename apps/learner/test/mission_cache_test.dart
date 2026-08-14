import 'package:evidence_gym_learner/data/mission_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The offline setting shipped before the cache did, so the switch
/// promised something nothing implemented. These pin the behaviour the
/// switch now actually has — and the two limits that keep it honest.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<MissionCache> cache() async =>
      MissionCache(await SharedPreferences.getInstance());

  Map<String, dynamic> missionJson(String id, {String version = '1.0.0'}) => {
        'id': id,
        'version': version,
        'title': 'A mission',
        'claim': 'A claim',
        'media': {'type': 'image', 'altText': 'alt'},
        'reactions': ['trust', 'suspicious', 'investigate'],
        'evidenceActions': [
          {'id': 'check', 'type': 'source', 'label': 'Check the source'}
        ],
        'skillTags': ['provenance'],
        'contentWarnings': <String>[],
      };

  test('a cached mission survives a round trip', () async {
    final c = await cache();
    expect(c.readMission('m1'), isNull);
    expect(c.storedCount, 0);

    await c.writeMission('m1', missionJson('m1'));
    final read = c.readMission('m1');
    expect(read, isNotNull);
    expect(read!.id, 'm1');
    expect(c.storedCount, 1);
  });

  test('turning the setting off drops what is already held', () async {
    // A switch that stops adding while leaving the old cache on disk has
    // not really been turned off, and the learner who turned it off to
    // reclaim space would not get any back.
    final c = await cache();
    await c.writeMission('m1', missionJson('m1'));
    await c.writeMission('m2', missionJson('m2'));
    await c.writePath({'version': '1', 'locale': 'en', 'nodes': []});
    expect(c.storedCount, 2);

    await c.clear();
    expect(c.storedCount, 0);
    expect(c.readMission('m1'), isNull);
    expect(c.readPath(), isNull);
  });

  test('an entry from an older build reads as absent, not as an error',
      () async {
    // A cache entry that no longer parses is a cache entry from a
    // previous version of the app. The network copy is authoritative, so
    // this must be a miss rather than a crash on launch.
    SharedPreferences.setMockInitialValues({
      'cache.mission.m1': '{not valid json',
      'cache.path': 'also not json',
    });
    final c = await cache();
    expect(c.readMission('m1'), isNull);
    expect(c.readPath(), isNull);
  });

  test('the cache stores what the server said, not our re-serialisation',
      () async {
    // Written from the raw response body, so a field this build does not
    // model yet still survives into the cache. Re-serialising our own
    // model would silently drop it and the cached copy would differ from
    // the live one in ways nobody could see.
    final c = await cache();
    final json = missionJson('m1')..['somethingNewFromTheServer'] = 42;
    await c.writeMission('m1', json);

    // Round-trips through the parser without losing the mission.
    expect(c.readMission('m1')!.id, 'm1');
  });

  test('the lookahead stays small', () {
    // The point is surviving a tunnel, not making the whole pack
    // available offline — that would be a download the learner did not
    // ask for, on a connection they may be paying for by the megabyte.
    expect(MissionCache.lookahead, lessThanOrEqualTo(5));
  });

  test('no storage means no cache and no crash', () async {
    // Private browsing, a locked-down profile. The cache is a
    // convenience; its absence must not stop the app.
    final c = MissionCache(null);
    expect(c.readMission('m1'), isNull);
    expect(c.readPath(), isNull);
    expect(c.storedCount, 0);
    await c.writeMission('m1', missionJson('m1'));
    await c.clear();
  });
}
