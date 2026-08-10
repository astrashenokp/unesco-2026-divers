# Backlog epics and implementation order

## E0 — Repository and developer experience

Deliverables: Flutter/FastAPI workspaces, local services, CI, lints, testing, OIDC/IaC skeleton, onboarding. Exit: clean clone to green tests and staging.

## E1 — Identity and consent

Guest flow, Firebase token verification, roles, settings, consent versions, deletion/export hooks. Exit: positive/negative authz tests.

## E2 — Content catalog and scenario packs

Schema validator, two reviewed packs, hashes/licenses/accessibility, exact version fetch, local cache. Exit: corrupted/unsupported pack rejected safely.

## E3 — Mission attempt state machine

Start/prediction/evidence/conclusion states, concurrency/version, idempotency. Exit: property/integration tests prove legal transitions.

## E4 — Evidence actions

Curated source/date/context actions, normalization, limitations, provider adapter boundary. Exit: unknown/conflict/unavailable stay distinct.

## E5 — Socratic coach

Hint policy, structured output, allowlisted evidence, deterministic fallback, eval suite/cost caps. Exit: no critical leakage/injection/verdict failure.

## E6 — Scoring, skills and XP

Process rubric, confidence calibration, append-only ledger, skill state, next booster. Exit: retries/races never duplicate XP.

## E7 — Evidence Receipt

Immutable receipt, version/source/action trail, disclaimer, correction link, privacy-safe export. Exit: old receipt reproduces after new content version.

## E8 — Flutter learner experience

Path, mission, prediction, investigation, conclusion, receipt, progress, offline/error/accessibility/localization. Exit: web/Android golden E2E.

## E9 — Trust, reporting and content correction

Report intake, quarantine, correction version, audit, content expiry. Exit: harmful/incorrect pack can be disabled without silent history rewrite.

## E10 — Analytics and impact

Privacy-safe events, outbox, funnel/calibration/process metrics, pilot export and small-cohort guardrails. Exit: no raw content/identity leakage.

## E11 — Reliability, security and operations

Edge/WAF, IAM, secrets, backup/restore, observability/SLO, rate/cost limits, incident/rollback. Exit: release hardening matrix passes.

## E12 — Submission package

Proposal, demo video/subtitles, rehearsal, backup, source appendix, confirmation. Exit: two-person verification before deadline.

## E13 — Education and platform expansion

Reviewed authoring, facilitator/assignment/aggregate view, offline packs, partner/localization workflow. Starts only after P0/P1 evidence.

## Story template

Every backlog item states learner outcome, scope/non-scope, DRI, contract/data/security/a11y impact, acceptance tests, observable signal, rollback/fallback and dependency.
