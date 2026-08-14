# Role 4 reports persistence handoff: `POST /v1/reports`

## Goal / status

Durable persistence for learner content reports is implemented and verified by
Role 4. Role 2 can implement the last unimplemented public operation against the
`ReportRepository` port described below. Decision: [ADR-010](../docs/09-decisions/ADR-010-REPORTS-PERSISTENCE.md), issue #33.

## Changed (Role 4)

- `packages/data_access/src/data_access/schema.py`: `reports` table
  (`id`, `reporter_id`, `mission_id`, `mission_version?`, `reason`, `detail?`,
  `status` default `pending`, `created_at`; reason/status check constraints;
  index `reports(status, created_at)`).
- `packages/data_access/migrations/versions/0005_reports.py`: additive,
  reversible migration (upgrade and downgrade exercised in CI).
- `packages/data_access/src/data_access/reports.py`:
  `SqlAlchemyReportRepository` plus value objects `SubmittedReport`,
  `StoredReportResult` and the `ReportRepository` protocol.
- `packages/data_access/tests/`: PostgreSQL integration tests (commit, replay
  no-duplicate, conflict, rollback, concurrent same-key) and an aiosqlite
  unit test.

## Port Role 2 consumes

`packages/data_access/src/data_access/reports.py` defines:

```python
@dataclass(frozen=True)
class SubmittedReport:
    report_id: str
    reporter_id: str
    mission_id: str
    mission_version: str | None
    reason: str
    detail: str | None
    submitted_at: datetime

@dataclass(frozen=True)
class StoredReportResult:
    request_fingerprint: str
    report: SubmittedReport
    expires_at: datetime

class ReportRepository(Protocol):
    async def get(self, scope: IdempotencyScope, *, at: datetime) -> StoredReportResult | None: ...
    async def put(self, scope: IdempotencyScope, result: StoredReportResult) -> None: ...
```

`IdempotencyScope(route, learner_id, key)` is the shared scope used by every
other idempotent operation. `request_fingerprint` must be a content hash of the
normalized request (`missionId`, `reason`, `detail`); same fingerprint means
the same logical submission and is the replay/conflict key.

## Use-case contract for `POST /v1/reports`

1. Derive `reporter_id` exclusively from the verified bearer principal.
2. Validate `missionId`, `reason` (enum), optional `detail` (≤ 1000 chars),
   and the required `Idempotency-Key`. Resolve `mission_version` server-side
   from the mission catalog when available; the column is nullable.
3. `get(scope)` first: if a stored result exists with a matching fingerprint,
   replay it and return the original `202` — no new report.
4. Otherwise build `SubmittedReport` (with a fresh `report_id`) and
   `StoredReportResult` (expiry = now + 24h) and `put(scope, result)`.
5. On success return `202` with no moderation state.
6. On `RepositoryConflict` return `409 idempotency-key-conflict`.
7. On `DataAccessError` (or any persistence failure) return `503` — never a
   `202` the service cannot stand behind. Log nothing that contains `detail`.

Do not persist bearer tokens, request headers or device identifiers. Do not
expose report rows, `status`, reviewer identity or queue position.

## Reliability semantics Role 4 verified

- Report, idempotency record and `report.submitted.v1` outbox event commit in
  one transaction; rollback removes all three.
- Same key + same fingerprint: no duplicate report or event.
- Same key + different fingerprint: `RepositoryConflict`.
- Concurrent same-key submission produces exactly one report.
- The outbox payload carries no `detail` and no reporter identity.
