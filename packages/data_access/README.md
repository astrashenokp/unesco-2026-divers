# Evidence Gym Data Access

PostgreSQL persistence adapters for the Role 2 learning application ports.
The adapters intentionally consume the domain ports from `services/api`; install
the API package in the same environment when running the monorepo integration
tests.

## Local setup

Install the package with test dependencies, start PostgreSQL, then set:

```bash
export DATABASE_URL='postgresql+asyncpg://evidence_gym:evidence_gym@localhost:5432/evidence_gym'
alembic -c alembic.ini upgrade head
```

The package stores authoritative attempts and learner-scoped idempotency
snapshots. It does not store bearer tokens, request headers, prompts, or raw
uploads. Redis is intentionally not part of this baseline.

Run the 24-hour TTL cleanup with:

```bash
python scripts/cleanup_idempotency.py
```

## Recovery

Use the database provider's encrypted backup/PITR tooling for production. Local
restore drills must target an isolated database and verify the migration head,
attempt count, version values, and idempotency expiry behavior before cutover.
The local helpers are `scripts/backup.sh` and `scripts/restore.sh`; restore is
blocked unless `ALLOW_DESTRUCTIVE_RESTORE=1` is explicitly set.
