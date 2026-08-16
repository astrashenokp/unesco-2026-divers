import 'dart:convert';

import 'package:evidence_gym_learner/data/api_client.dart';
import 'package:evidence_gym_learner/data/audience.dart';
import 'package:evidence_gym_learner/data/mission_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A published build holds no credential, so it can read the API's
/// public catalog and nothing else. Before this the release path did not
/// even try: `_signIn` took the bundled branch unconditionally, the live
/// code became unreachable, and the compiler removed it — a deployed
/// copy could not have contacted its own API whatever `API_BASE_URL`
/// said.
///
/// These pin the two ways the replacement could still be wrong: reaching
/// for an endpoint that is known to refuse, and letting the server's
/// view of progress overwrite the device's.
void main() {
  const learnerMission = 'authentic-media-wrong-context';
  const otherMission = 'ai-citation-integrity';

  MissionRepository local() => DemoMissionRepository(
        localeCode: () => 'en',
        audience: () => AudienceMode.adult,
      );

  String pathJson(List<Map<String, dynamic>> nodes) => jsonEncode({
        'version': '9.9.9',
        'locale': 'en',
        'nodes': nodes,
      });

  /// Answers catalog reads and fails the test on anything else, so an
  /// accidental authenticated call is a failure rather than a 401 a
  /// learner would meet at runtime.
  EvidenceGymApiClient clientServing(String body, {int status = 200}) {
    return EvidenceGymApiClient(
      baseUrl: Uri.parse('https://api.example/'),
      authTokenProvider: () async => null,
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          anyOf(contains('/catalog/path'), contains('/catalog/missions/')),
          reason: 'only the public catalog may be requested without a '
              'credential; ${request.method} ${request.url} would be refused',
        );
        expect(
          request.headers.containsKey('Authorization'),
          isFalse,
          reason: 'no credential ships in a release build, so none may be sent',
        );
        return http.Response(
          body,
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  test('the server lists the missions and the device supplies progress',
      () async {
    // The server has never seen this learner, so it reports every node
    // as available — which is exactly what it reports after they finish
    // one. Taking its states verbatim would freeze the path.
    final repository = ConnectedCatalogRepository(
      clientServing(pathJson([
        {'missionId': learnerMission, 'title': 'From the server', 'state': 'available'},
        {'missionId': otherMission, 'title': 'Also from the server', 'state': 'available'},
      ])),
      local: local(),
    );

    final before = await repository.getLearningPath();
    expect(before.nodes.map((n) => n.missionId),
        containsAll(<String>[learnerMission, otherMission]));
    expect(before.nodes.first.title, 'From the server',
        reason: 'the catalog itself comes from the API');

    final localPath = await local().getLearningPath();
    expect(
      before.nodes.map((n) => n.state),
      localPath.nodes.map((n) => n.state),
      reason: 'state belongs to the device, which is where attempts happen',
    );
  });

  test('a mission the device does not know keeps the server\'s node',
      () async {
    final repository = ConnectedCatalogRepository(
      clientServing(pathJson([
        {'missionId': 'published-later', 'title': 'Newly published', 'state': 'locked'},
      ])),
      local: local(),
    );

    final path = await repository.getLearningPath();
    expect(path.nodes.single.missionId, 'published-later');
    expect(path.nodes.single.state, 'locked',
        reason: 'nothing local to overlay, so the server is the only source');
  });

  test('a refused catalog degrades to the bundled pack and says so',
      () async {
    final repository = ConnectedCatalogRepository(
      clientServing(
        jsonEncode({
          'type': 'about:blank',
          'title': 'Server error',
          'status': 500,
          'code': 'internal_error',
        }),
        status: 500,
      ),
      local: local(),
    );

    expect(repository.isServingLocal, isFalse);
    final path = await repository.getLearningPath();
    expect(path.nodes, isNotEmpty,
        reason: 'the bundled pack is the same reviewed content, so a failed '
            'catalog read costs the learner nothing');
    expect(repository.isServingLocal, isTrue,
        reason: 'the difference must be reportable rather than invisible');
  });

  test('starting and finishing never reaches the network', () async {
    // The MockClient fails the test on any non-catalog request, so this
    // passing is the assertion: the whole practice flow is local.
    final repository = ConnectedCatalogRepository(
      clientServing(pathJson(const [])),
      local: local(),
    );

    final mission = await repository.getMission(learnerMission);
    final attempt = await repository.startAttempt(mission.id, mission.version);
    expect(attempt.id, isNotEmpty);

    final progress = await repository.getMyProgress();
    expect(progress, isNotNull);
  });

  test('nothing a learner does leaves the device', () {
    final repository = ConnectedCatalogRepository(
      clientServing(pathJson(const [])),
      local: local(),
    );

    expect(repository.isDemo, isTrue,
        reason: 'reading a public catalog records nothing; the notices that '
            'depend on this must stay accurate');
  });
}
