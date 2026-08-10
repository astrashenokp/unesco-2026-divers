# Scaling roadmap

## Stage 0 — hackathon

One regional Cloud Run API, one worker, Postgres, Storage, curated packs, simple in-process next-activity selection. Optimize reliability and demo polish.

## Stage 1 — education pilot

Connection pooling, CDN packs, Pub/Sub outbox, read replicas only if measured, background analytics, organization boundaries in schema, deletion/export workflows, feature flags and load tests.

## Stage 2 — multi-region audience

Decide regional/data-residency topology, cache immutable catalogs globally, partition analytics, isolate content authoring from learner traffic, formal incident rotation and capacity plans.

## Extraction triggers

Extract a service only when at least one is true:

- independent deploy cadence causes recurring coordination incidents;
- distinct security/data boundary needs isolation;
- resource profile or scaling differs materially;
- ownership team is stable and separate;
- measured latency/failure blast radius justifies it.

Likely first extractions: verification-provider workers, content-authoring service, analytics pipeline. Identity, XP ledger and attempt transaction stay together longer.

## Capacity sketch

For 100k monthly active learners, assume 5 sessions/learner/month, 2 missions/session, 6 evidence actions/mission: about 1M attempts and 6M evidence actions monthly. Most reads hit immutable pack caches; external/AI calls require quotas, deduplication and budget gates. Validate with real usage before sharding.

## Backpressure

Bound request size, concurrent provider calls and per-user queues; use exponential backoff + jitter, dead-letter topics, circuit breakers and a degraded curated-only mode. Never retry non-idempotent calls without an idempotency key.
