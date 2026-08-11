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
    final res = await _client.get(_uri('/catalog/path'));
    if (res.statusCode != 200) _throwProblem(res);
    return LearningPath.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Mission> getMission(String missionId) async {
    final res = await _client.get(_uri('/missions/$missionId'));
    if (res.statusCode != 200) _throwProblem(res);
    return Mission.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Attempt> startAttempt({
    required String missionId,
    required String missionVersion,
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      _uri('/attempts'),
      headers: await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey),
      body: jsonEncode({'missionId': missionId, 'missionVersion': missionVersion}),
    );
    if (res.statusCode != 201) _throwProblem(res);
    return Attempt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Attempt> submitPrediction({
    required String attemptId,
    required PredictionInput input,
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      _uri('/attempts/$attemptId/prediction'),
      headers: await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(input.toJson()),
    );
    if (res.statusCode != 200) _throwProblem(res);
    return Attempt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EvidenceResult> useEvidenceAction({
    required String attemptId,
    required String actionId,
    Map<String, dynamic>? input,
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      _uri('/attempts/$attemptId/evidence-actions'),
      headers: await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey),
      body: jsonEncode({'actionId': actionId, if (input != null) 'input': input}),
    );
    if (res.statusCode != 200) _throwProblem(res);
    return EvidenceResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Hint> requestHint({
    required String attemptId,
    required String idempotencyKey,
  }) async {
    final res = await _client.post(
      _uri('/attempts/$attemptId/hints'),
      headers: await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey),
    );
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
    final res = await _client.post(
      _uri('/attempts/$attemptId/conclusion'),
      headers: await _headers(withIdempotencyKey: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(input.toJson()),
    );
    if (res.statusCode != 200) _throwProblem(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      receiptId: json['receiptId'] as String,
      xpAwarded: json['xpAwarded'] as int,
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }

  Future<Receipt> getReceipt(String receiptId) async {
    final res = await _client.get(
      _uri('/receipts/$receiptId'),
      headers: await _headers(withIdempotencyKey: false),
    );
    if (res.statusCode != 200) _throwProblem(res);
    return Receipt.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Progress> getMyProgress() async {
    final res = await _client.get(
      _uri('/me/progress'),
      headers: await _headers(withIdempotencyKey: false),
    );
    if (res.statusCode != 200) _throwProblem(res);
    return Progress.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
