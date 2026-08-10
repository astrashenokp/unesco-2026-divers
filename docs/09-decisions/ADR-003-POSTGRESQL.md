# ADR-003: PostgreSQL is the system of record

Status: Accepted — 2026-08-10

## Decision

Use Cloud SQL PostgreSQL for content versions, attempts, evidence actions, conclusions, XP ledger, progress, reports, audit and outbox. Cloud Storage owns large immutable artifacts.

## Rationale

Core completion requires relational invariants and transactions; content/review/version/audit queries are richer than a document-first MVP warrants.

## Consequences

Connection pooling, migrations, backup/restore and index discipline required. Firebase/analytics projections are not authoritative. Revisit distributed data only after measured scale/residency needs.
