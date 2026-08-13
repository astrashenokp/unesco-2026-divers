# Role 4 persistence handoff: attempts, predictions, evidence actions, and hints

## Goal / status

Ready for persistence implementation — Role 2 has defined the domain invariants,
repository behavior, authorization checks, idempotency semantics, optimistic
versioning and transaction intent for `StartAttempt`, `SubmitPrediction`,
`UseEvidenceAction`, and `RequestHint`.

## Changed

- `src/evidence_gym_api/learning/attempt.py`: pure Attempt aggregate.
- `src/evidence_gym_api/learning/value_objects.py`: opaque typed identifiers.
- `src/evidence_gym_api/learning/ports.py`: persistence and transaction protocols.
- `src/evidence_gym_api/learning/use_cases.py`: application orchestration.
- `src/evidence_gym_api/learning/testing.py`: non-production in-memory adapters.
- `tests/test_attempt.py` and `tests/test_learning_use_cases.py`: executable behavior.

## Contracts and decisions

The public Hint contract stays learner-facing and pre-completion only:
`contracts/openapi.yaml` and `contracts/coach-output.schema.json` cap exposed
hint levels at 4. Implement these ports without leaking physical persistence
objects into the domain:

- `AttemptRepository.get/add/save`
- `MissionPolicyReader.get_policy`
- `IdempotencyRepository.get/put`
- `EvidenceIdempotencyRepository.get_evidence/put_evidence`
- `HintIdempotencyRepository.get_hint/put_hint`
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
- `UseEvidenceAction`: evidence idempotency lookup, attempt ownership/version
  validation, deterministic provider result, attempt update and the complete
  evidence-response snapshot insert share one transaction. A provider failure
  must not mutate the attempt or create an idempotency record.
- `RequestHint`: hint idempotency lookup, ownership/state validation and the safe
  provider-or-fallback response snapshot share one idempotency operation. It does
  not save the attempt or advance `Attempt.version`.

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

### Atomic completion follow-up

`POST /attempts/{id}/conclusion` now depends on
`AtomicCompletionWriter.complete`. Its concrete Role 4 implementation must write
the completed attempt snapshot, immutable receipt, XP ledger entries, progress
projection, outbox event and `StoredCompletionResult` in the same database
transaction. The current SQL attempt repository accepts only a one-version
advance, while completion advances through the logical `concluded` and
`completed` stages; the atomic writer must persist the final snapshot without
making either intermediate stage observable.

Role 2 now supplies `GameplayCompletionScorer`, which reads the pinned Role 3
`rubric.processLevels`, converts them to Role 4 `gameplay.ProcessLevel` values,
and delegates the award to `gameplay.award_xp()`. The PostgreSQL writer must
persist the returned stable `rule_code`, amount and level; it must not introduce
another XP table or scoring formula.

### Receipt query follow-up

`GET /receipts/{receiptId}` now depends on `ReceiptReader.get_for_learner`.
The production adapter must query the immutable receipt and its owning attempt
in one authorization-filtered read using both `receipt_id` and `learner_id`.
Missing and foreign receipts must both return `None`; the adapter must never
expose a receipt-owner existence oracle. It maps the stored public payload to
`EvidenceReceipt` without recalculating its hash or returning internal learner,
XP, outbox, or persistence fields.

### Progress query follow-up

`GET /me/progress` now depends on `ProgressReader.get_for_learner`. The
production PostgreSQL adapter must read `learner_progress` and all matching
`skill_states` for the server-derived learner ID. A learner with no projection
row returns `ProgressResult(total_xp=0, skills=())`, not `404`. Skill mastery
and due dates must be returned from the stored Role 4 gameplay projection; the
query must not recalculate XP, mastery, scheduling, or accept a learner ID from
the client.
