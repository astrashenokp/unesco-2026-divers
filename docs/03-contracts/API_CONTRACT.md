# API contract guide

The normative endpoint/shape subset is `contracts/openapi.yaml`. This document defines semantics that schemas alone cannot express.

## Conventions

- Base path `/v1`; HTTPS only.
- `Authorization: Bearer <Firebase ID token>` except public catalog/demo endpoints. Guest sessions use Firebase Anonymous Auth (`signInAnonymously()`); the server verifies the resulting token the same way as any other principal — there is no separate demo-only auth path (ADR-008).
- Mutations that may be retried require `Idempotency-Key` (UUID/opaque 8–128 chars). The server retains the `(route, principal, key) → response` mapping for **24 hours**, matching the RPO in `NON_FUNCTIONAL_REQUIREMENTS.md`. The same key replayed with a different request body within the window returns `409` (`idempotency-key-conflict`); after 24 hours the key may be reused (ADR-008).
- Concurrency-sensitive resources use `version`; stale updates return `409`.
- Any `attempts/{attemptId}/...` route returns `404` (never `403`) when the attempt does not exist or is not owned by the caller, matching `GET /receipts/{receiptId}`. This avoids an existence oracle for IDs the caller does not own (ADR-008).
- Cursor pagination: `limit` and opaque `nextCursor`.
- Locale uses `Accept-Language`; content response states effective locale.
- Public mission projections expose accessibility alternatives from reviewed
  mission fixtures so the client can render media-independent completion paths.
- Errors: `type`, `title`, `status`, `code`, `detail`, `traceId`, optional field errors.

## MVP resources

| Method/path | Meaning | Owner |
|---|---|---|
| `GET /v1/catalog/path` | published learning path | platform/catalog |
| `GET /v1/missions/{id}` | exact published mission version | platform/catalog |
| `POST /v1/attempts` | start/resume attempt | platform/learning |
| `POST /v1/attempts/{id}/prediction` | initial reaction/confidence | platform/learning |
| `POST /v1/attempts/{id}/evidence-actions` | execute curated/provider action | AI + platform boundary |
| `POST /v1/attempts/{id}/hints` | get bounded hint | AI/coach |
| `POST /v1/attempts/{id}/conclusion` | atomically complete/score | platform/scoring |
| `GET /v1/receipts/{id}` | reproducible Evidence Receipt | platform/receipt |
| `GET /v1/me/progress` | skill/path/XP projection | platform/learning |
| `POST /v1/reports` | report harmful/incorrect content | security/trust |

## State transition rules

- Create attempt selects and pins `missionId` + `missionVersion`.
- Prediction accepted only in `ready`; idempotent replay returns same state.
- Evidence/hints accepted only in `predicted|investigating`.
- Conclusion requires prediction and the pinned mission version's `minimumCompletionEvidence` actions unless the pinned mission version has `testsCriticalIgnoring: true` (ADR-008).
- `POST /attempts/{id}/conclusion` is the only client call for the concluding phase: `ConclusionInput` carries the three axes plus `postConfidence` and `shareDecision`. In one transaction the server validates and scores the conclusion, records confidence and share decision, creates the receipt, awards XP, writes the outbox event and marks the attempt `completed`. There is no separate "reflection" endpoint (ADR-009).
- `concluded` and `reflected` are logical stages of that endpoint, not separately durable states. No client may depend on observing them. An earlier version of this document described `reflected` as a resumable checkpoint; that was incorrect, because an intermediate state written inside a transaction does not survive its rollback (ADR-009 supersedes ADR-008 decision 5).
- Completion is all-or-nothing. If the transaction does not commit, everything rolls back and a same-key retry re-runs the operation. If it commits, a same-key retry returns the original result — no duplicate XP, receipt or outbox event.
- Evidence actions carry `version` like prediction and conclusion, and stale values return `409` (ADR-009).
- Every mutation that advances `Attempt.version` returns the new value, so the client can construct its next call. `EvidenceResult` carries `attemptVersion` for this reason; there is no `GET /attempts/{id}` to fall back on.
- `POST /attempts/{id}/hints` does not advance `Attempt.version` and does not take `version`. Asking for help must never fail on a concurrency race.
- AI/provider failure never corrupts attempt; error is retryable or deterministic fallback is returned.

## Evidence response semantics

Every item includes `evidenceId`, type, source display metadata, retrieval time, verification status and limitations. `not_found` means not found in queried providers, never fabricated. The client must not restyle `unknown` as false.

## Compatibility

Clients ignore unknown response fields. Servers reject unknown enum values in mutations unless schema explicitly allows extension. Minimum supported client version can gate non-security UX; security updates may force upgrade with a safe explanation.
