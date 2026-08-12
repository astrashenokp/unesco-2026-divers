# Role 4 persistence handoff: attempts and predictions

## Goal / status

Ready for persistence implementation — Role 2 has defined the domain invariants,
repository behavior, authorization checks, idempotency semantics, optimistic
versioning and transaction intent for `StartAttempt` and `SubmitPrediction`.

## Changed

- `src/evidence_gym_api/learning/attempt.py`: pure Attempt aggregate.
- `src/evidence_gym_api/learning/value_objects.py`: opaque typed identifiers.
- `src/evidence_gym_api/learning/ports.py`: persistence and transaction protocols.
- `src/evidence_gym_api/learning/use_cases.py`: application orchestration.
- `src/evidence_gym_api/learning/testing.py`: non-production in-memory adapters.
- `tests/test_attempt.py` and `tests/test_learning_use_cases.py`: executable behavior.

## Contracts and decisions

No contract changed. Implement these ports without leaking physical persistence
objects into the domain:

- `AttemptRepository.get/add/save`
- `MissionPolicyReader.get_policy`
- `IdempotencyRepository.get/put`
- `TransactionManager.transaction`

Required invariants:

- Attempt ownership comes from the verified server-side principal.
- `mission_id` and `mission_version` are pinned for the lifetime of an attempt.
- `version` starts at 1 and every successful domain mutation increments it once.
- `save(..., expected_version=N)` succeeds only while the stored version is `N`.
- An idempotency scope is `(route, learner_id, key)`.
- Same scope and fingerprint replays the stored original result.
- Same scope with a different fingerprint is a conflict.
- Idempotency results expire after 24 hours. After expiry the same key may be
  reused; Role 4 owns TTL enforcement and the cleanup job.
- `StartAttempt`: idempotency lookup, exact mission-policy lookup, attempt insert and
  idempotency-result insert share one transaction.
- `SubmitPrediction`: idempotency lookup, attempt ownership/version validation,
  attempt update and idempotency-result insert share one transaction.

The physical schema, constraints, indexes, migration order, isolation/locking
strategy and recovery procedure remain Role 4 decisions. The implementation must
map uniqueness/concurrency failures to `RepositoryConflict` without returning raw
database errors to callers.

## Safety and data

- `learner_id` is restricted authentication-derived data; do not log its raw value.
- Idempotency records must not contain bearer tokens or request headers.
- Stored result snapshots contain only the domain response required for replay.
- Authorization must be evaluated before returning any attempt outside its
  learner-scoped idempotency record.
- Delete expired idempotency records without retaining request bodies or tokens.

## Verification

Run from the repository root:

```powershell
& '.\services\api\.venv\Scripts\python.exe' -m pytest -q -p no:cacheprovider
```

The in-memory implementation is the behavioral reference, not a production data
store. A concrete adapter must pass the same use-case tests plus integration tests
for rollback, duplicate keys and concurrent stale-version updates.

## Risks / assumptions

- `MissionPolicy.tests_critical_ignoring` maps the reviewed, version-pinned
  `testsCriticalIgnoring` contract field, defined by
  `contracts/mission-fixture.schema.json` and ADR-008, and must never come from
  the client.
- A new idempotency key submitted after a prediction has already succeeded is a
  state conflict, not a replay.
- Conclusion uses one atomic transaction. `concluded`, `reflected` and
  `completed` are internal ordered stages, but no intermediate checkpoint is
  expected to survive rollback. A same-key retry repeats the transaction; after
  a successful commit it replays the original completion response.

## Next

Role 4: propose the physical mapping and migration/recovery plan. Acceptance
requires both Role 2 review of invariant/transaction compatibility and Role 4
evidence that rollback and concurrent retry tests pass.
