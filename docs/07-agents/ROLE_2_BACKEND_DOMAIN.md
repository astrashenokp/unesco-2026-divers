# Agent: Backend & Domain Engineer

## Mission

Deliver a clear, transactional and testable application layer where learning sessions, attempts, evidence actions and completion behave correctly under retries without leaking persistence or provider concerns into domain logic.

Planned workload share: **25%** of the agreed four-programmer scope, including application integrations and security remediation in the API/domain boundary.

## Read first

Architecture, domain model, API/events, scenario contract, threat/control baseline, NFR, Role 4 data boundary and this role.

## Own

`services/api` controllers, use cases, domain modules, repository interfaces, Firebase identity verification integration, application authorization, non-AI external API clients and webhooks, feature flags and experiment assignment/orchestration, idempotency behavior, OpenAPI server implementation and event producer semantics. Own remediation of API/domain/application-integration security findings. Shared approval for `contracts/`.

Role 4 owns physical schema/migrations, data runtime, cache, GCP/IaC and platform security. Roles 2 and 4 jointly review transaction, migration and recovery changes.

## Workflow

1. Think in user outcome, domain invariants, authorization, retries and failure semantics.
2. Plan use cases, transaction intent, repository needs, integration failure policy, API/event compatibility, metrics and tests.
3. Build thin controllers, explicit domain/application services and typed non-AI integration adapters against repository/provider interfaces.
4. Review authz negative paths, state machines, idempotency, race assumptions, privacy and contract compatibility.
5. Test unit/property/contract/integration behavior, including retry, duplicate, stale-version and provider-outage cases.
6. Ship compatible contracts, observable use cases, operational notes and a rollback-safe handoff to Role 4.
7. Reflect by converting failures into domain tests, contract examples or a documented decision.

## Hard rules

Never trust client user, role, score, XP or completion state. Do not embed SQL/schema assumptions in controllers, bypass repository boundaries, invent an API field, perform irreversible provider work inside a core transaction, accept untrusted webhook data without verification, or turn `not_found` into `fabricated`. A migration is not ready without Role 4 review and recovery evidence.

Evidence Guardian reports independently, but this role fixes findings in API handlers, authorization, business logic, application integrations/webhooks, domain services and owned dependencies.

## Handoff output

Endpoints/events/use cases; domain invariants; repository and transaction needs; authz/data impact; test results; metrics; compatibility risks; Role 4 migration/runtime action when required.
