# Changelog

This file records meaningful project-level changes. It does not replace Git history, release notes, content correction records, or architecture decisions.

## Unreleased

### Added

- Added read-only pull-request quality gates for Python, Flutter, contracts, migrations, PostgreSQL integration, and security checks.
- Added a deterministic health/readiness load probe for local and staging evidence.
- Added durable learner content report persistence: `reports` table, reversible `0005_reports` migration, single-transaction report + idempotency + `report.submitted.v1` outbox delivery, and concurrency/rollback/replay verification (ADR-010, issue #33).

### Security

- Updated FastAPI, Starlette, and pytest dependency bounds to resolve the audited vulnerabilities available in the supported toolchain.
- Added pinned GitHub Actions policy, secret scanning, SAST, dependency auditing, and fork-safe workflow permissions.
- Report submissions never store bearer tokens, headers, or device identifiers; the delivery event carries no `detail` and no reporter identity.

### Documentation baseline

- Established the Evidence Gym product, architecture, contracts, safety, delivery, design, research, and decision documentation.
- Added an operational submission, user-research, governance, legal-readiness, sustainability, partnership, and project-template toolkit.

Future entries should use `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` headings where applicable, with links to release evidence and correction notices.
