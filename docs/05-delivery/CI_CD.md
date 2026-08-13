# CI/CD pipeline

## Pull request stages

1. format/lint/type check;
2. Markdown links/schema/OpenAPI validation;
3. Flutter and Python unit tests;
4. contract + DB migration tests;
5. secret/SAST/SCA/license/IaC/container scans;
6. AI gold/injection/fallback eval subset;
7. ephemeral API + critical E2E; screenshots/accessibility smoke;
8. preview artifact and concise report.

The repository implements the PR stages in `.github/workflows/pr.yml` and
`.github/workflows/security.yml`. Python packages are installed from local
paths, PostgreSQL migrations run against an isolated service database, and
fork pull requests receive no deployment credentials. Workflow actions are
pinned to full commit SHAs and workflow permissions are read-only.

The CI gate is evidence, not a claim of production readiness: a passing PR
does not perform a production deploy or replace the required human review.

## Main/release

Build once; SBOM and provenance; image scan; deploy to staging by digest; migration dry-run; integration/E2E/DAST/load smoke; human approval; progressive production traffic; SLO check; automatic rollback threshold.

## Credential model

GitHub OIDC/workload identity, per-environment service account, protected production environment. No JSON service-account keys. Fork PRs have no secrets and cannot deploy.

## Reproducibility

Lock dependencies and Flutter/Python versions; pin Actions SHA; preserve test/eval version and container digest. Generated code is checked for deterministic diff or generated during build with verified tooling.

## Rollback

Traffic back to previous image digest. Database changes use expand/migrate/contract so old/new app coexist. Feature/provider/coach changes have kill switches; content rolls forward with a corrected version rather than rewriting history.
