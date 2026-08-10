# Data model

## Logical schema

| Table | Key fields | Notes |
|---|---|---|
| `users` | `id`, `firebase_uid`, `locale`, `created_at` | minimal profile; Firebase UID unique |
| `consents` | `user_id`, `policy_version`, `purpose`, `granted_at/revoked_at` | purpose-specific |
| `scenario_packs` | `id`, `slug`, `version`, `status`, `locale`, `manifest_hash` | published immutable |
| `missions` | `id`, `pack_id`, `schema_version`, `content_json`, `review_expires_at` | validated against schema |
| `sources` | `id`, `canonical_id/url`, `publisher`, `retrieved_at`, `license` | normalized metadata |
| `mission_sources` | `mission_id`, `source_id`, `role`, `snapshot_ref` | gold evidence graph edges |
| `attempts` | `id`, `user_id`, `mission_id`, `state`, `pre/post_confidence`, `version` | optimistic lock/version |
| `evidence_actions` | `id`, `attempt_id`, `type`, `request_json`, `result_ref` | redact before storage |
| `conclusions` | `attempt_id`, three axes, rationale refs, share decision | one final version plus audit |
| `xp_ledger` | `id`, `user_id`, `attempt_id`, `rule`, `amount` | append-only, idempotent |
| `skill_states` | `user_id`, `skill`, `mastery`, `due_at`, `algorithm_version` | explainable scheduler |
| `receipts` | `id`, `attempt_id`, `payload_json`, `hash`, `created_at` | immutable |
| `reports` | `id`, `reporter_id?`, `mission_id`, `reason`, `status` | limited visibility |
| `audit_log` | `id`, actor, action, object, timestamp, metadata | tamper-evident export/retention |
| `outbox` | `id`, `topic`, `aggregate_id`, `payload`, `published_at` | same transaction as domain write |

## Data classes

| Class | Examples | Default retention |
|---|---|---|
| Public content | published pack metadata | life of version/license |
| Account | UID, locale, settings | account life + short deletion window |
| Learning | attempts, skill state, receipt | user controlled; policy-defined |
| Sensitive/child data | age band, consent | minimize; never store exact birth date unless required |
| User input/upload | URL/text/media | ephemeral by default; TTL hours/days |
| Operational logs | trace/error metadata | 30 days pilot, no content bodies |
| Analytics | pseudonymous events | aggregate early; delete raw within 90 days pilot |

Exact retention needs legal/product approval before production.

## Migration rules

- backward-compatible expand/migrate/contract;
- schema migration and app deploy separately reversible;
- no destructive production migration without verified backup/restore drill;
- pack schema uses explicit version and migration tool;
- timestamps UTC; display localized; IDs UUIDv7/opaque.

## Index baseline

Index `attempts(user_id,state,updated_at)`, `skill_states(user_id,due_at)`, `missions(pack_id,status)`, `sources(canonical_id)`, `outbox(published_at,id)`, `reports(status,created_at)`. Add indexes from query plans, not speculation.
