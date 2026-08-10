# Team of four programmers

The percentage is a planning baseline for the agreed scope, not a measure of seniority or value. Rebalance when measured work changes, but keep the ownership boundaries below.

| Role | Planned share | Primary code outcome |
|---|---:|---|
| 1 — Frontend & Experience | 25% | accessible Flutter/Web learner experience and client security |
| 2 — Backend & Domain | 25% | correct API/domain use cases and application integrations |
| 3 — AI, Learning & Content | 25% | grounded coach, evidence tools, evals, reviewed packs and AI safety |
| 4 — Game Platform, Data, Security & Reliability | 25% | progression, persistence, infrastructure security and reliability |

## Role 1 — [Frontend & Experience Engineer](ROLE_1_FRONTEND_EXPERIENCE.md)

Owns the Flutter/Web learner app, design system, localization, accessibility, offline states, client API integration and visual demo quality. Owns remediation of client-side security and privacy findings. Contract edge: generated API client and scenario presentation model.

## Role 2 — [Backend & Domain Engineer](ROLE_2_BACKEND_DOMAIN.md)

Owns FastAPI endpoints, domain/use-case logic, application authorization, session/attempt orchestration, non-AI application integrations/webhooks, feature-flag and experiment orchestration, idempotent application behavior and OpenAPI/event producer contracts. Owns remediation of API, domain and application-integration security findings. Does not independently own physical database design or cloud runtime.

## Role 3 — [AI, Learning & Content Engineer](ROLE_3_AI_LEARNING_CONTENT.md)

Owns evidence actions, Socratic policy/prompts, AI gateway/evals/fallback, mission fixtures/content quality, learning rubric and research claim discipline. Owns remediation of prompt, model, retrieval and content-safety findings. Cannot publish sensitive content alone.

## Role 4 — [Game Platform, Data, Security & Reliability Engineer](ROLE_4_GAME_DATA_SECURITY_RELIABILITY.md)

Owns progression and gamification code, PostgreSQL/Redis implementation, migrations/indexes/query performance, data integrity, backup/restore, infrastructure and data security, CI/CD, observability, performance and release automation. It is not the sole fixer for security defects in code owned by Roles 1–3.

## Security and QA agent

Evidence Guardian is an independent automated reviewer, not a fifth programmer and not a substitute for human accountability. It audits all four areas, reports reproducible findings and can recommend a release block; the owner of the affected code implements and verifies the fix. Role 4 maintains the security/reliability gates and resolves platform, data, infrastructure and pipeline findings.

## Shared database boundary

- Role 2 defines domain invariants, transaction intent and repository needs.
- Role 4 implements physical schema, constraints, migrations, indexes, caching, backup and operational controls.
- Any contract-affecting or destructive migration requires both Roles 2 and 4 to review it and documented recovery evidence.

## Daily integration

- A consumes mocked OpenAPI/fixtures and delivers accessible client states.
- B implements the API contract and domain use cases against repository interfaces.
- C supplies versioned evidence packs, deterministic behavior and AI coach evaluation.
- D implements progression/data/runtime plumbing and keeps the complete flow observable, secure and repeatable.
- Evidence Guardian audits the integrated flow; each code owner fixes findings in their boundary.

Each role has a durable prompt in this folder. Human owners remain accountable for decisions made with agents.
