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

  /// The server would not accept who we are, or cannot check.
  ///
  /// 401 and 503-with-a-verifier-code are one situation from the
  /// learner's side: signing in is not available right now. Splitting
  /// them into two messages would describe our internals rather than
  /// their problem.
  bool get isAuthUnavailable =>
      problem.status == 401 ||
      problem.code == 'identity-verifier-unavailable';

  bool get isConflict => problem.status == 409;
  bool get isRateLimited => problem.status == 429;

  /// This client's copy of the attempt is behind the server's.
  ///
  /// Keyed on the code, never on the 409 alone. Several unrelated
  /// situations share that status — a replayed idempotency key, and a
  /// conclusion submitted before enough evidence was checked — and they
  /// call for opposite responses. Treating them alike would offer to
  /// restart the mission of a learner who had simply not checked enough
  /// yet, throwing away work they had not finished doing.
  ///
  /// Both spellings are accepted because the server and the demo pack
  /// disagree about casing (`stale-attempt-version` against
  /// `minimum_evidence_not_met`); matching only one would silently miss.
  bool get isStaleVersion => const {
        'stale-attempt-version',
        'stale_attempt_version',
        'attempt-conflict',
        'attempt_conflict',
      }.contains(problem.code);

  /// The conclusion needs more evidence behind it before it can be
  /// submitted. Not a fault to recover from — a step not yet done.
  bool get needsMoreEvidence => const {
        'minimum_evidence_not_met',
        'minimum-evidence-not-met',
      }.contains(problem.code);

  /// This evidence action has already advanced this attempt.
  ///
  /// A curated action counts once (#25): replaying it with a new
  /// idempotency key is rejected so that one action cannot be used to
  /// inflate the evidence count, the hint level, completion
  /// eligibility, skill mastery or XP.
  ///
  /// The third distinct meaning of 409 on this endpoint, which is why
  /// none of these read the status. Nothing was lost when it happens —
  /// the learner already has this result — so it needs neither a
  /// restart nor an alarm.
  bool get evidenceAlreadyUsed => const {
        'evidence-action-already-used',
        'evidence_action_already_used',
      }.contains(problem.code);

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

  /// Notified after every request with whether the server answered at
  /// all.
  ///
  /// Optional, so the client stays usable without one. Driven by request
  /// outcomes rather than by a network-interface check, because a device
  /// can be on wi-fi with no route out, behind a captive portal, or
  /// facing a server that is down — and all three feel identical to a
  /// learner.
  void Function({required bool reachable})? onReachability;

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
      final response = await call();
      // A 500 is the server answering, which is a different thing from
      // being unreachable. Only transport failure counts as offline.
      onReachability?.call(reachable: true);
      return response;
    } on EvidenceGymApiException {
      rethrow;
    } catch (_) {
      onReachability?.call(reachable: false);
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
