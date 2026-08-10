# Contributing

This repository uses trunk-based development with short-lived branches and explicit path ownership.

## Current ownership

The four-programmer workload baseline is balanced at **25% per role**:

- Role 1: Flutter/Web, experience, accessibility and frontend-security.
- Role 2: API/domain, application integrations/webhooks, experiments and API-security.
- Role 3: AI/retrieval, learning/content, evals and AI/content safety.
- Role 4: gameplay, PostgreSQL/Redis, GCP/IaC, infrastructure/data security, CI/CD and reliability.

Evidence Guardian audits independently but does not own fixes. Security remediation follows the affected code owner. Database changes require Role 2 review of domain/transaction intent and Role 4 review of physical schema, migration and recovery. The normative detail is the [ownership matrix](docs/03-contracts/OWNERSHIP_MATRIX.md).

## Before coding

1. Choose one issue with acceptance criteria.
2. Confirm the issue is P0/P1 in `docs/01-product/MVP_SCOPE.md`.
3. Identify the owning role and affected contract.
4. Create a branch: `feat/<issue>-<slug>`, `fix/<issue>-<slug>`, `docs/<issue>-<slug>`, or `sec/<issue>-<slug>`.

## Pull request contract

- one outcome per PR;
- link issue and ADR when architectural;
- list API/event/schema changes;
- include tests, screenshots for UI, and threat note for trust-boundary changes;
- update docs in the same PR;
- no generated code or secret files unless explicitly approved;
- two approvals for auth, privacy, AI safety, infrastructure, or contract-breaking changes.

See [Git workflow](docs/05-delivery/GIT_WORKFLOW.md) and [Definition of Done](docs/03-contracts/DEFINITION_OF_DONE.md).
