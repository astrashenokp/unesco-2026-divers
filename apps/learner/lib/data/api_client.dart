import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Thrown for any non-2xx response. Widgets must handle this — no raw
/// endpoint calls or unhandled futures in UI code (ROLE_1_FRONTEND_EXPERIENCE.md).
class EvidenceGymApiException implements Exception {
  EvidenceGymApiException(this.problem);
  final Problem problem;

  bool get isNotFound => problem.status == 404;
  bool get isConflict => problem.status == 409;
  bool get isRateLimited => problem.status == 429;

  /// The request never reached a server. Status 0 is not a real HTTP
  /// status — it is this client's marker for "no answer at all", which
  /// the UI must present as a connection problem rather than as
  /// something the server said.
  bool get isOffline => problem.status == 0;

  @override
  String toString() => 'EvidenceGymApiException(${problem.status} ${problem.code})';
}

/// Generated/typed client per ROLE_1's hard rule: widgets never call
/// endpoints directly. One instance is provided app-wide.
///
/// [authTokenProvider] returns the current Firebase ID token (including
/// anonymous-auth tokens, per ADR-008) or null for public endpoints.
class EvidenceGymApiClient {
  EvidenceGymApiClient({
    required this.baseUrl,
    required this.authTokenProvider,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function() authTokenProvider;
  final http.Client _client;

  final _random = Random.secure();

  /// Opaque idempotency key for one logical mutation. Callers generate one
  /// per user-initiated action and reuse it only for that action's retries.
  String newIdempotencyKey() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<Map<String, String>> _headers({required bool withIdempotencyKey, String? idempotencyKey}) async {
    final token = await authTokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (withIdempotencyKey && idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
  }

  Uri _uri(String path) => baseUrl.resolve('v1$path');

  /// Runs an HTTP call and converts a transport failure into a Problem.
  ///
  /// Anything that is not already an [EvidenceGymApiException] — DNS
  /// failure, no route, TLS error, timeout — becomes `status: 0`. This
  /// deliberately avoids `dart:io`'s `SocketException`, which does not
  /// exist on web; `http` surfaces its own `ClientException` there, and
  /// catching broadly covers both without a platform split.
  ///
  /// Headers must be built *before* calling this. An earlier version
  /// awaited the auth token inside the guarded closure, so an expired
  /// sign-in was swallowed and shown to the learner as "no connection" —
  /// telling someone their internet is down when their session expired.
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call();
    } on EvidenceGymApiException {
      rethrow;
    } catch (_) {
      throw EvidenceGymApiException(
        const Problem(
          type: 'about:blank',
          title: 'No connection',
          status: 0,
          code: 'network_unreachable',
          traceId: 'local',
        ),
      );
    }
  }

  Never _throwProblem(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = <String, dynamic>{};
    }
    body.putIfAbsent('status', () => response.statusCode);
    throw EvidenceGymApiException(Problem.fromJson(body));
  }

  Future<LearningPath> getLearningPath() async {
    final res = await _send(() async => _client.get(_uri('/catalog/path')));
    if (res.statusCode != 200) _throwProblem(res);
    return LearningPath.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Mission> getMission(String missionId) async {
    final res = await _send(() async => _client.get(_uri('/missions/$missionId')));
    if (res.statusCode != 200) _throwProblem(res);
    return Mission.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Attempt> startAttempt({
    required String missionId,
    required String missionVersion,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/attempts'),
      headers: headers,
      body: jsonEncode({'missionId': missionId, 'missionVersion': missionVersion}),
    ));
    if (res.statusCode != 201) _throwProblem(res);
    return Attempt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Attempt> submitPrediction({
    required String attemptId,
    required PredictionInput input,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/attempts/$attemptId/prediction'),
      headers: headers,
      body: jsonEncode(input.toJson()),
    ));
    if (res.statusCode != 200) _throwProblem(res);
    return Attempt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EvidenceResult> useEvidenceAction({
    required String attemptId,
    required String actionId,
    required int version,
    Map<String, dynamic>? input,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/attempts/$attemptId/evidence-actions'),
      headers: headers,
      body: jsonEncode({
        'actionId': actionId,
        'version': version,
        if (input != null) 'input': input,
      }),
    ));
    if (res.statusCode != 200) _throwProblem(res);
    return EvidenceResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Hint> requestHint({
    required String attemptId,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/attempts/$attemptId/hints'),
      headers: headers,
    ));
    if (res.statusCode != 200) _throwProblem(res);
    return Hint.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// [receiptId], [xpAwarded], [progress] — the atomic completion result.
  /// Concluded -> reflected -> completed happens server-side in this one
  /// call (ADR-008); there is no separate "reflect" endpoint.
  Future<({String receiptId, int xpAwarded, Progress progress})> submitConclusion({
    required String attemptId,
    required ConclusionInput input,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/attempts/$attemptId/conclusion'),
      headers: headers,
      body: jsonEncode(input.toJson()),
    ));
    if (res.statusCode != 200) _throwProblem(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      receiptId: json['receiptId'] as String,
      xpAwarded: json['xpAwarded'] as int,
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }

  Future<Receipt> getReceipt(String receiptId) async {
    final headers = await _headers(withIdempotencyKey: false);
    final res = await _send(() async => _client.get(
      _uri('/receipts/$receiptId'),
      headers: headers,
    ));
    if (res.statusCode != 200) _throwProblem(res);
    return Receipt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Reports harmful or incorrect content. The server answers `202` and
  /// deliberately never reveals moderation state, so a reporter cannot
  /// probe what happened to a case.
  Future<void> reportContent({
    required String missionId,
    required String reason,
    String? detail,
    required String idempotencyKey,
  }) async {
    final headers = await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey);
    final res = await _send(() async => _client.post(
      _uri('/reports'),
      headers: headers,
      body: jsonEncode({
        'missionId': missionId,
        'reason': reason,
        if (detail != null) 'detail': detail,
      }),
    ));
    if (res.statusCode != 202) _throwProblem(res);
  }

  Future<Progress> getMyProgress() async {
    final headers = await _headers(withIdempotencyKey: false);
    final res = await _send(() async => _client.get(
      _uri('/me/progress'),
      headers: headers,
    ));
    if (res.statusCode != 200) _throwProblem(res);
    return Progress.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
