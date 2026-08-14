# Role 4 handoff: PostgreSQL wired into the API composition

## Goal / status

Done — the ASGI entry point now serves the full learning flow against
PostgreSQL when `DATABASE_URL` is set, and keeps the existing in-memory
composition as the no-database default. Ownership-sensitive wiring lands in
Role 2 files (`main.py`, `app.py`, the three `api.py` dependency functions);
this document is the Role 4 → Role 2 review handoff.

## Changed

- `packages/data_access/src/data_access/readers.py` (new):
  `SqlAlchemyReceiptReader`, `SqlAlchemyProgressReader`.
- `packages/data_access/src/data_access/readiness.py` (new):
  `DatabaseReadinessProbe`.
- `packages/data_access/src/data_access/__init__.py`: exports the new adapters.
- `packages/data_access/tests/test_readers.py` (new, sqlite, no DB required):
  receipt ownership/no-existence-oracle mapping, progress projection and zero
  projection for new learners, readiness probe live/unreachable.
- `packages/data_access/tests/test_postgres_readers.py` (new, skipif no
  `DATABASE_URL`): owned-receipt-only reads, XP + skill-state projection,
  readiness probe against the real database.
- `services/api/src/evidence_gym_api/persistence.py` (new): `ServicesFactory`
  building `LearningServices`/`ReceiptServices`/`ProgressServices` over one
  isolated `AsyncSession`, plus `UuidAttemptIdGenerator`.
- `services/api/src/evidence_gym_api/app.py`: `create_app` accepts `database`
  and `services_factory`; both stored on `app.state`.
- `services/api/src/evidence_gym_api/learning/api.py`,
  `receipt/api.py`, `progress/api.py`: the three service dependencies became
  async-generator dependencies — they yield the explicitly provided services
  when present (unchanged test path), otherwise open `async with
  database.session()` and build services from the factory, closing the session
  after the response.
- `services/api/src/evidence_gym_api/main.py`: `DATABASE_URL` set → `Database`
  + `DatabaseReadinessProbe` + `ServicesFactory`; unset → previous in-memory
  composition unchanged.
- `services/api/pyproject.toml`: added `evidence-gym-data-access>=0.1,<0.2` dependency.
- `services/api/tests/test_persistence_wiring.py` (new, skipif no
  `DATABASE_URL`): full `/v1` flow over the wired app — ready probe, start,
  predict, evidence action, conclude, owned receipt 200, foreign receipt 404,
  progress with XP.
- `.github/workflows/pr.yml`: the PostgreSQL step now also runs
  `services/api/tests/test_persistence_wiring.py`.
- `CHANGELOG.md`: Unreleased → Added entries.

## Contracts and decisions

- No contract, schema, or ADR change. The three ports this fulfils were already
  declared and documented in `services/api/ROLE4_PERSISTENCE_HANDOFF.md`
  (Receipt query and Progress query follow-ups) and `operational.ReadinessProbe`.
- `SqlAlchemyReceiptReader` filters ownership inside one `receipts ⋈ attempts`
  query; missing and foreign receipts both return `None` (no existence oracle),
  and the stored public payload maps to `EvidenceReceipt` without recalculating
  the hash.
- `SqlAlchemyProgressReader` reads `learner_progress` + `skill_states` for the
  server-derived learner ID; a missing projection row yields
  `ProgressResult(total_xp=0, skills=())`, never 404.
- One HTTP request binds exactly one use case, so one session per request is
  correct and closed after the response.
- `data_access` imports in `persistence.py` are deferred to method bodies to
  avoid the module-level import cycle (`data_access` → codec →
  `evidence_gym_api` → `app` → `learning/api` → `persistence`).
- Persistent attempt IDs use a UUID suffix instead of the per-process counter,
  so restarting an instance or running two factories against one database
  cannot collide on `attempt-pg-1`.

## Safety and data

- Authorization stays server-side: receipts and progress are queried only by the
  verified `Principal` subject; the client can never select a learner.
- The readiness probe performs a bare `SELECT 1`; no data is read or logged.
- No bearer tokens, request bodies, or raw learner identifiers enter logs or
  stored snapshots (no new storage paths added beyond the existing ones).
- Fallback without `DATABASE_URL` keeps the local/demo experience and the
  existing unit-test path byte-identical.

## Verification

Local run (repo root, `.venv`):

- Without DB: `pytest packages/gameplay services/api packages/data_access`
  → 241 passed.
- With `DATABASE_URL=postgresql+asyncpg://evidence_gym:evidence_gym@127.0.0.1:5433/evidence_gym`:
  `pytest packages/data_access services/api` → 205 passed.
- Alembic cycle on PostgreSQL: `upgrade head` → `downgrade base` → `upgrade
  head` → `upgrade head` → all data-access + wiring tests green.
- Migration offline SQL generation (`upgrade head --sql`) succeeds.
- `bandit -q -r packages/gameplay/src services/api/src packages/data_access/src`
  → clean.
- Smoke: `uvicorn evidence_gym_api.main:app` with `DATABASE_URL` →
  `GET /ready` returns `{"status":"ready"}`, `GET /v1/catalog/path` serves.

## Risks / assumptions

- The three dependency functions changed from plain `def` to async generators;
  the explicit-services branch (all existing tests) is untouched, but Role 2
  review should confirm the per-request session lifecycle matches API intent.
- `services/api` now declares an `evidence-gym-data-access` dependency; CI installs all three
  editable packages in one step, so ordering is not an issue, but the wheel
  dependency is now real.
- The local dev database had to be reset from `0005_reports` (reports work is on
  a separate PR) back to this branch's head so the integration tests run on
  schema 0001–0004. No production impact.
- Concurrent requests share the engine pool (`pool_size=5`, `max_overflow=10`);
  the idempotency/versioning adapters already translate uniqueness/race failures
  to `RepositoryConflict`.

## Next

- Owner: Role 2 — review `main.py`/`app.py`/`api.py` composition and the
  per-request session pattern. Acceptance: PR approved with CI green
  (Python+contracts+migrations step now also proves the wired HTTP flow on
  PostgreSQL).
- Owner: Evidence Guardian — independent QA/security pass on the wiring.
- Once approved and merged, #38 (reports persistence) merges next; its only
  overlap is the additive `data_access/__init__.py` exports.
