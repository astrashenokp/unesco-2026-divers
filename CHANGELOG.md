# Changelog

This file records meaningful project-level changes. It does not replace Git history, release notes, content correction records, or architecture decisions.

## Unreleased

### Added

- Added read-only pull-request quality gates for Python, Flutter, contracts, migrations, PostgreSQL integration, and security checks.
- Added a deterministic health/readiness load probe for local and staging evidence.
- Added PostgreSQL-backed learning services: receipt and progress readers, a database readiness probe, and a per-request session composition wired into the API when `DATABASE_URL` is set.
- Added end-to-end API wiring tests that run the full learning flow against PostgreSQL in CI.

### Security

- Updated FastAPI, Starlette, and pytest dependency bounds to resolve the audited vulnerabilities available in the supported toolchain.
- Added pinned GitHub Actions policy, secret scanning, SAST, dependency auditing, and fork-safe workflow permissions.

### Documentation baseline

- Established the Evidence Gym product, architecture, contracts, safety, delivery, design, research, and decision documentation.
- Added an operational submission, user-research, governance, legal-readiness, sustainability, partnership, and project-template toolkit.

Future entries should use `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` headings where applicable, with links to release evidence and correction notices.
