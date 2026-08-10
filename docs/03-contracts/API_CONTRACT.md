# API contract guide

The normative endpoint/shape subset is `contracts/openapi.yaml`. This document defines semantics that schemas alone cannot express.

## Conventions

- Base path `/v1`; HTTPS only.
- `Authorization: Bearer <Firebase ID token>` except public catalog/demo endpoints.
- Mutations that may be retried require `Idempotency-Key` (UUID/opaque 8–128 chars).
- Concurrency-sensitive resources use `version`; stale updates return `409`.
- Cursor pagination: `limit` and opaque `nextCursor`.
- Locale uses `Accept-Language`; content response states effective locale.
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
- Conclusion requires prediction and at least one evidence action unless the mission explicitly tests critical ignoring.
- Completion is one transaction; repeated key returns original receipt.
- AI/provider failure never corrupts attempt; error is retryable or deterministic fallback is returned.

## Evidence response semantics

Every item includes `evidenceId`, type, source display metadata, retrieval time, verification status and limitations. `not_found` means not found in queried providers, never fabricated. The client must not restyle `unknown` as false.

## Compatibility

Clients ignore unknown response fields. Servers reject unknown enum values in mutations unless schema explicitly allows extension. Minimum supported client version can gate non-security UX; security updates may force upgrade with a safe explanation.
