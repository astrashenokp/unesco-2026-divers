# Release runbook

## Go/no-go

- P0 acceptance and two golden missions pass.
- Contract/migration compatibility verified.
- No blocking security/accessibility/AI-safety finding.
- Backup/rollback and provider kill switches verified.
- Dashboards/alerts staffed; budget/quota adequate.
- Demo offline fallback and recorded backup work.
- PR security and supply-chain gates pass; artifact digest and SBOM are recorded.

## Steps

1. Freeze release commit/tag; record artifact digests/SBOM/eval versions.
2. Deploy staging by digest; run migration job and full release suite.
3. Smoke manually on target web/Android devices and both locales.
4. Approve production environment; shift small traffic.
5. Watch errors, latency, DB, cost and safety signals; increase gradually.
6. Record release result and known limitations.

## Rollback triggers

Authz/privacy/security incident, failed mission completion/XP integrity, broken accessibility on core path, error/SLO burn, uncontrolled LLM/provider cost, dangerous AI policy regression or inability to complete offline demo.

The current hardening branch does not deploy to GCP. It proves local/staging
checks and keeps production deployment behind the future protected environment,
OIDC and human approval gate.

## Submission release

Export English proposal and video; verify size/duration/subtitles/links; test from a clean device; upload early; capture confirmation, timestamp and checksums; two members verify independently.
