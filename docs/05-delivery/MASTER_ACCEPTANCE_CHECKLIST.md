# Master acceptance checklist

## Product

- One-sentence concept, audience and differentiators are consistent everywhere.
- Trust/Suspicious/Investigate is initial prediction, not final verdict.
- Three axes and insufficient evidence are first-class.
- Two demo cases are complete, submission-audited and memorable; public
  publication approval remains a separate content-review gate.

## Learning

- XP rewards evidence process and justified updating.
- Coach does not reveal gold early.
- Transfer/calibration are measured separately from engagement.
- Claims distinguish evidence from hypothesis.

## Client

- Web/Android core path, loading/error/offline/retry.
- English/Ukrainian; 200% text; keyboard/screen reader; reduced motion.
- Status is not color-only; media has alternatives.
- No secret or authoritative scoring logic on client.

## API/data

- OpenAPI/schema/event compatibility.
- Authz, idempotency, concurrency and transaction invariants.
- XP ledger/receipt/outbox atomically correct.
- Migration, backup and restore evidence.

## AI/providers

- Structured bounded hints and evidence refs.
- Injection/leakage/hallucination/conflict/unknown/outage evals.
- Deterministic fallback and cost/latency caps.
- `not found != fabricated`; metadata != support.

## Content/trust

- Source, retrieval/version/license/reviewer/expiry/accessibility.
- Report/quarantine/correction/audit.
- No UGC/open URL/upload before launch gates.

## Security/privacy

- Threat/control test plan, IAM/MFA/OIDC/secrets/WAF/rates.
- No critical/high known exploitable release issue.
- PII/log/prompt review; retention/deletion/export.
- Child/education/privacy review before younger classroom deployment.

## Operations

- SLO dashboards, alerts, owner, runbook, rollback/kill switches.
- Provider/LLM/DB/deploy failure rehearsals.
- Cost budgets/quotas and support ownership.
- PR workflow runs tests, migrations, secrets, SAST/SCA and dependency gates with read-only permissions.
- Load probe records p95 evidence against a local/staging endpoint.

## Submission

- English proposal ≤10 MB and video ≤3 minutes.
- Captions, sources, honest implementation/roadmap distinction.
- Clean-device/live/offline/recorded demo.
- Early upload and two-person confirmation.

## Production/scale

- Legal/privacy/subprocessor/license and external review complete.
- Education pilot evidence exists.
- Service extraction/scaling has measured trigger and owner.
