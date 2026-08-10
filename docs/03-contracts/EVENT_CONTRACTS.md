# Event contracts

## Envelope

```json
{
  "eventId": "opaque",
  "eventType": "mission.completed.v1",
  "occurredAt": "2026-08-10T12:00:00Z",
  "producer": "learning",
  "subjectId": "attempt-id",
  "correlationId": "trace-id",
  "schemaVersion": 1,
  "data": {}
}
```

Events are facts in past tense. Consumers deduplicate by `eventId`. At-least-once delivery is assumed; ordering is guaranteed only per aggregate when explicitly configured.

## Catalog

| Event | Required data | Consumers |
|---|---|---|
| `attempt.started.v1` | attempt, mission/version, pseudonymous learner | analytics |
| `evidence.action_completed.v1` | attempt, action type, status, duration bucket | analytics, quality |
| `mission.completed.v1` | attempt, mission/version, skill deltas, calibration bucket | analytics, scheduler |
| `receipt.created.v1` | receipt, attempt, hash | audit |
| `pack.published.v1` | pack/version/hash/locale/review expiry | CDN/cache, audit |
| `mission.quarantined.v1` | mission/version/reason code | catalog, trust |
| `content.corrected.v1` | old/new version, correction category | affected-attempt notifier |
| `user.deletion_requested.v1` | subject and deadline, no extra PII | privacy workflow |

## Privacy

No prompt, raw URL query, uploaded media, free-text rationale, exact confidence for small cohorts, email, Firebase UID, IP, or device advertising ID in analytics events. Operational events may use restricted identifiers under shorter retention.

## Evolution

Add optional fields within a version; never change meaning/type. Breaking changes publish a new event name. Keep a compatibility consumer test and dead-letter replay runbook.
