# ADR-008: Attempt contract clarifications

Status: Accepted — 2026-08-11. **Decision 5 superseded by [ADR-009](ADR-009-ATOMIC-COMPLETION-AND-EVIDENCE-VERSION.md) on 2026-08-12** — it described `reflected` as a resumable checkpoint, which a single transaction cannot provide.

## Context

Role 2 (Backend & Domain) completed the Attempt state machine and asked five questions before implementing `POST /v1/attempts`, `POST /v1/attempts/{id}/prediction`, `.../evidence-actions`, `.../hints`, and `.../conclusion`. Each answer below is derived from already-accepted decisions (ADR-002, ADR-005, `CONTROL_BASELINE.md`, `NON_FUNCTIONAL_REQUIREMENTS.md`) rather than invented fresh.

## Decisions

1. **Foreign/unknown attempt → `404`, never `403`.** All `/attempts/{attemptId}/...` routes return the generic `Problem` `404` when the attempt does not exist or does not belong to the caller. This matches the existing `GET /receipts/{receiptId}` precedent in `contracts/openapi.yaml` and avoids an existence oracle (IDOR enumeration) that a `403` would create. `contracts/openapi.yaml` now declares `404` on `prediction`, `evidence-actions`, `hints`, and `conclusion` alongside the existing `409`.

2. **Guest authentication = Firebase Anonymous Auth, not a local demo principal.** The client calls `signInAnonymously()` and sends the resulting Firebase ID token exactly like any other principal; the server has one token-verification path (issuer/audience/signature/expiry), per `CONTROL_BASELINE.md`. A separate unauthenticated "demo principal" would add a second authorization path and contradict architecture invariant 5 (server-side authorization for every protected action). Anonymous UID state is ephemeral/pseudonymous per `PERSONAS_AND_PERMISSIONS.md`. This answers `OPEN_QUESTIONS.md` OQ-002 for MVP/demo scope only; persistence/linking policy for public beta stays open.

3. **`testsCriticalIgnoring` marks the critical-ignoring exception.** `API_CONTRACT.md` already required "at least one evidence action unless the mission explicitly tests critical ignoring" without a way to express it. Added `testsCriticalIgnoring` to the public `Mission` schema in `contracts/openapi.yaml` as an optional boolean with default `false`, and to the mission-minimum contract in `SCENARIO_PACK_SPEC.md` as the mission-level content policy field (`contracts/scenario-pack.schema.json` only validates the pack manifest, not per-mission JSON). The conclusion endpoint accepts zero evidence actions only when the pinned mission version has this flag set.

   Amendment (2026-08-12): the public OpenAPI `Mission` projection still keeps
   `testsCriticalIgnoring` optional with default `false` for client
   compatibility, but mission fixture `schemaVersion: 2` requires an explicit
   boolean before validation. Legacy/pre-v2 fixture importers may only default a
   missing value during migration before validating as v2.

4. **Idempotency-Key retention = 24 hours per `(route, principal, key)`.** Matches the existing RPO ≤24h figure in `NON_FUNCTIONAL_REQUIREMENTS.md` so the idempotency store and the durability story stay consistent, and comfortably covers a same-day reconnect after an offline/interrupted mission. Same key with a different request body within the window returns `409 Problem` (`idempotency-key-conflict`). After the TTL, the key may be reused with new semantics; Role 4 owns the cleanup job.

5. **`reflected` is a server-persisted checkpoint inside the single `POST /attempts/{id}/conclusion` call, not a separate endpoint.** `ConclusionInput` already carries the three axes plus `postConfidence` and `shareDecision` in one request. The server persists `concluded` after validating/scoring the three-axis assessment, then `reflected` after recording `postConfidence`/`shareDecision`, then `completed` after the receipt is generated and XP is awarded — all in the same transaction. Persisting `reflected` mid-transaction lets a same-key retry resume straight to receipt/XP finalization without re-scoring the conclusion if a partial failure occurs after scoring. The client never calls a distinct "reflect" endpoint for MVP.

## Consequences

`docs/03-contracts/API_CONTRACT.md`, `contracts/openapi.yaml`, `docs/03-contracts/SCENARIO_PACK_SPEC.md`, `docs/04-security/CONTROL_BASELINE.md`, and `docs/12-governance/OPEN_QUESTIONS.md` (OQ-002) are updated to match. Role 2 can implement the four attempt controllers without contract drift; Role 4's persistence handoff should size the idempotency store for a 24h TTL, not indefinite retention.
