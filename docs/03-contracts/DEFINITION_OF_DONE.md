# Definition of Done

A story is done only when all applicable boxes are true.

## Behavior

- Acceptance criteria demonstrated on the target platform.
- Empty/loading/error/offline/retry states handled.
- Localization and accessibility semantics included.
- No unrelated scope or hidden feature flag.

## Contract and data

- OpenAPI/event/scenario changes reviewed by producer and consumer.
- Migration is backward compatible, tested, and has rollback/forward plan.
- Idempotency/concurrency behavior tested where relevant.
- Data classification, retention and deletion impact recorded.

## Quality and security

- Unit/contract/integration tests pass; critical path E2E updated.
- SAST, dependency, secret and IaC scans pass within policy.
- Authorization tested positively and negatively.
- AI change passes gold, injection, leakage and fallback evals.
- No raw secrets/PII/user content in logs, fixtures, screenshots or prompts.

## Operations

- Metrics/logs/traces identify success and expected failures.
- Alert/runbook updated for a new failure mode.
- Cost/quota impact understood.
- Docs and changelog/release notes updated.

## Handoff

PR includes screenshots/evidence, tests run, known limitations, contract/security impact, and next step/owner. `Works on my machine` is not release evidence.
