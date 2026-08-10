# Failure modes and graceful degradation

| Failure | User behavior | System action |
|---|---|---|
| LLM timeout/refusal | deterministic Socratic hint | circuit breaker; record policy-safe failure code |
| Crossref/OpenAlex down | cached/curated citation evidence | provider health and stale label |
| no network | downloaded demo/pack works | queue non-sensitive progress for sync |
| duplicate submit | same receipt/result | idempotency record, no duplicate XP |
| content corrected | old attempt still reproducible; correction banner | new pack version, audit, optional re-practice |
| media unavailable/license revoked | accessible placeholder/explanation | quarantine version and replace lawfully |
| DB overload | read-only catalog/cache; completion retries safely | shed load, max instances, alert |
| Pub/Sub duplicate | no duplicate projection | event ID inbox/deduplication |
| prompt injection in evidence | ignored as data | delimit, allowlist, output checks, security event |
| compromised external API | adapter disabled | kill switch, alternate/curated fallback |
| analytics outage | learning unaffected | durable outbox with retention/cap |
| bad release | progressive rollback | immutable previous image and compatible schema |

Chaos/rehearsal priority: live-demo offline switch, LLM timeout, duplicate completion, DB restore, bad deploy rollback, leaked non-production credential rotation.
