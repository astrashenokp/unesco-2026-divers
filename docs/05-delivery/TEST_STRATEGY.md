# Test strategy

## Test pyramid

- Unit: domain invariants, state machine, scoring, calibration, parsing, view models.
- Contract: OpenAPI client/server, provider adapters, events, scenario schema/fixtures.
- Integration: Postgres/outbox/Auth emulator/provider stubs.
- E2E: two golden missions, guest/auth, offline/degraded, report, retry/idempotency.
- Non-functional: accessibility, localization, security, load, recovery and AI evals.

## Four golden paths

1. Authentic media + false context → correct three-axis result and receipt.
2. Hallucinated/mismatched citation → `not found/mismatch`, never automatic fabricated verdict.
3. Provider/LLM outage → deterministic mission completes.
4. Retry/race → one completion and one XP ledger set.

## Property tests

XP never negative; completion idempotent; published pack immutable; state transition cannot skip required stage; confidence in 0–100; three axes independent; unknown evidence never becomes false through serialization.

## UI

Widget/golden tests for major states, but favor semantics and resilient layout over brittle pixels. Manual screen-reader/keyboard/reduced-motion/text-scale/color-independent review on representative devices.

## AI evals

Versioned cases with expected policy properties, not one exact phrase. Record model/prompt/policy/evidence versions. A sample human review remains required; stochastic passes use repeated trials for critical cases.

## Test data

Synthetic or licensed fixtures; no production learner data. Mark legal mocks clearly. Preserve exact IDs/hashes as text, never lossy image compression.
