# Environment setup from zero

## Required developer tools

Git, Flutter stable pinned by project config, Dart, supported Python, dependency manager, Docker for local PostgreSQL, Node only for approved design/tooling, Google Cloud/Firebase CLI when cloud work begins. Record versions in future toolchain files rather than relying on “latest”.

## Local bootstrap target

One documented command should eventually validate tool versions, create local config from `.env.example`, start PostgreSQL/emulators, apply migrations, load two fixtures, run API, run Flutter web and execute smoke tests. It must never download unverified binaries or print secrets.

## Local PostgreSQL

The local container may publish PostgreSQL on a non-default port (for example `127.0.0.1:5433` in `eg-postgres`). `packages/data_access/.env.example` and `packages/data_access/alembic.ini` default to `5432`, which matches CI; for local work override with `DATABASE_URL` (Alembic reads it via `migrations/env.py`) or update `.env`:

```bash
DATABASE_URL=postgresql+asyncpg://evidence_gym:evidence_gym@127.0.0.1:5433/evidence_gym
```

Keep the local database migrated to head before running PostgreSQL integration tests: `python -m alembic -c alembic.ini upgrade head` from `packages/data_access`.

## Environment separation

`local`, `dev`, `staging`, `prod` use distinct Firebase apps, GCP projects, service accounts, databases, buckets, keys, budgets and callback URLs. Production data is never copied to local/test.

## Secret handling

Local values in ignored `.env`; cloud values in Secret Manager; CI through OIDC/workload identity. No service-account JSON, personal API key, secret in Remote Config, screenshot, issue, test fixture or generated mobile/web bundle.

## Seed data

Only synthetic/licensed mission fixtures. Stable deterministic IDs are allowed for tests but must be clearly non-production. Golden evidence and expected outputs are versioned.

## Verification checklist

- toolchain versions match;
- local DB reachable and migration applies twice safely;
- JSON/OpenAPI/scenario validation passes;
- guest/auth stub works;
- API health/readiness differ correctly;
- one trace ID crosses request;
- Flutter shows deterministic mission;
- offline/LLM-disabled flow completes;
- tests do not need production credentials.
