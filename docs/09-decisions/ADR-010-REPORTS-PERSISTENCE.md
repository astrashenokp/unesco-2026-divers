# ADR-010: Durable persistence for learner content reports

Status: Accepted — 2026-08-14
Related: [GitHub issue #33](https://github.com/astrashenokp/unesco-2026-divers/issues/33)

## Context

`POST /v1/reports` is the last unimplemented public operation. The OpenAPI
contract promises a `202 Accepted` only when the report is **durably stored or
queued**, and a `503` when it is not — accepting and discarding is explicitly
forbidden. Issue #33 asks Role 4 to confirm the persistence and reliability
half: store vs queue, transaction boundary, retention and deletion, encryption
and access, rate limiting, retry and delivery failure, and migration/recovery.

No report table, repository or durable queue existed before this decision. The
transactional outbox table already implemented for `mission.completed.v1`
(ADR-009, migration `0003`) provides the durable-delivery mechanism without a
new broker.

## Decision

### 1. Storage: PostgreSQL `reports` table plus the existing transactional outbox

A report is written to the `reports` table as the authoritative store, and a
`report.submitted.v1` event is written to the existing `outbox` table in the
same transaction. The outbox is the durable delivery queue to the future Role 3
moderation workflow; no external broker (Pub/Sub) is added for the MVP. A report
never exists without its outbox event and vice versa.

### 2. Transaction boundary

Report insert, idempotency record and outbox event are committed in one
transaction, mirroring the atomic completion writer. `202` is only returned
after commit; a failure that leaves no commit removes all three effects. A
persistence failure raises `DataAccessError` so the application boundary answers
`503` in preference to a `202` the service cannot stand behind. A unique-key
conflict maps to `RepositoryConflict` for `409`.

### 3. Retention and deletion

Reports are user-supplied input and are treated as sensitive by default.
Retention for the pilot is bounded (90 days as the default class in
`DATA_MODEL.md` "User input/upload", pending legal/product approval). The
`reporter_id` is stored so that account deletion can cascade; deletion behavior
is documented in the persistence handoff and remains gated on the
account-deletion workflow (OQ-002). `detail` free text and reporter identity are
restricted fields.

### 4. Encryption and access controls

Encryption is at rest at the Cloud SQL level (provider default). Access to
stored reports is limited to authorized reviewers/operators via application
authorization and least-privilege database roles; the public API never exposes
report rows, moderation state or queue position. Bearer tokens, request headers
and device identifiers are not stored. The outbox payload contains no
`detail` and no reporter identity, so the delivery path does not carry the
sensitive fields.

### 5. Rate limiting and abuse controls

`POST /reports` is rate-limited per learner (and defended by Cloud Armor at the
edge) before a live review workflow exists, so the endpoint cannot become a free
abuse or storage channel. The client already understands `429`. Enforcement of
the application-level limit is a follow-up and does not block this persistence
decision.

### 6. Retry and delivery-failure behavior

- Same `Idempotency-Key` and same content (fingerprint) replays the original
  acceptance; no second report, no second event, no second idempotency record.
- Same key with different content is a conflict (`RepositoryConflict` → `409`).
- A new key after success is a separate submission subject to the same limits
  (Role 2 decides whether it is treated as a state conflict, as with
  completion).
- The outbox provides at-least-once delivery; consumers deduplicate by
  `event_id` per `EVENT_CONTRACTS.md`. Idempotency records follow the existing
  24-hour TTL with the Role 4 cleanup job.
- When persistence is unavailable the submission fails visibly (`503`) rather
  than being silently accepted.

### 7. Migration, rollback, backup and recovery

Migration `0005_reports` is additive and reversible (upgrade and downgrade are
exercised in CI). The `reports` table is covered by the same backup/restore
procedure as the rest of the schema; production restore remains gated on the
provider PITR/restore drill. The expand/migrate/contract rule applies: schema
and application deploy remain separately reversible.

## Consequences

- Role 2 can implement `POST /reports` against `ReportRepository` (see
  `services/api/ROLE4_REPORTS_HANDOFF.md`): validate, derive the reporter only
  from the verified principal, compute the idempotency fingerprint, call
  `put`, and map `DataAccessError` → `503`, `RepositoryConflict` → `409`.
- Role 3 owns the moderation lifecycle: consuming `report.submitted.v1`,
  transitions of `reports.status`, and the review queue. The status check
  constraint is deliberately minimal until that workflow is designed.
- `report.submitted.v1` is added to the event catalog; it carries no `detail`
  and no reporter identity, and consumers must not require them.
- `reports.status` is internal-only. The public contract exposes no moderation
  state, reviewer identity or queue position (unchanged).
