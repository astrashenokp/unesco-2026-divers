# ADR-009: Atomic completion, and `version` on evidence actions

Status: Accepted — 2026-08-12
Supersedes: decision 5 of [ADR-008](ADR-008-ATTEMPT-CONTRACT-CLARIFICATIONS.md)

## Context

Role 2 found that ADR-008 decision 5 and `API_CONTRACT.md` assert two things that cannot both hold:

- completion is **one transaction**, and
- `reflected` is a **persisted checkpoint** a retry can resume from after a partial failure.

An intermediate state written inside a transaction does not survive that transaction's rollback. If the completion rolls back, nothing was persisted — there is no checkpoint to resume from. If it committed, the attempt is already `completed` and there is nothing left to resume.

The checkpoint sentence was wrong when it was written. It described a durability property the chosen transaction model cannot provide, and it would have sent Role 4 building persistence for a state that can never be observed.

Separately, `POST /attempts/{id}/evidence-actions` moves an attempt from `predicted` to `investigating` — a state change — but its request body carries no `version`, while prediction and conclusion both do. The general rule in `API_CONTRACT.md` is that concurrency-sensitive resources use `version`, so this is a gap rather than a deliberate exception.

## Decision

### 1. Completion is atomic, with no observable intermediate state

`POST /attempts/{id}/conclusion` performs, in one transaction:

1. validate and score the three-axis conclusion;
2. record `postConfidence` and `shareDecision`;
3. create the receipt;
4. award XP and update progress;
5. write the outbox event;
6. mark the attempt `completed`;
7. commit.

`concluded` and `reflected` remain **logical stages in the state machine**, useful for describing what the endpoint does and for validation ordering. They are not separately durable and no client may depend on observing them.

Failure semantics:

- **Transaction did not commit** — everything rolls back; the attempt stays where it was. A same-key retry re-runs the whole operation.
- **Transaction committed** — a same-key retry returns the original result. No duplicate XP, no second receipt, no repeated outbox event.

This is what the `Idempotency-Key` retention window in ADR-008 decision 4 already provides. The checkpoint added nothing the key did not already cover.

### 2. `version` is required on evidence actions

`POST /attempts/{id}/evidence-actions` takes `version` in its request body, like prediction and conclusion:

```json
{ "actionId": "check_source", "input": {}, "version": 2 }
```

A stale `version` returns `409`, consistent with every other concurrency-sensitive mutation.

### 3. Mutating responses return the attempt's new version

This is the client-side half of decision 2, and without it decision 2 makes the client's position worse rather than better.

`EvidenceResult` gains the attempt version as it stands after the action. The contract has no `GET /attempts/{id}`, so a client that sends `version` on evidence actions but never learns the resulting value has no way to construct a valid conclusion after its first evidence action. It would guess, and guess wrong, and receive a `409` it cannot recover from.

```yaml
EvidenceResult:
  required: [actionId, status, items, limitations, attemptVersion]
  properties:
    attemptVersion: { type: integer, minimum: 1 }
```

### 4. `/hints` is read-only with respect to `Attempt.version`

Requesting a hint does not change `Attempt.version` and does not carry `version` in its request.

The hint ladder rung is **derived** from state the attempt already holds — evidence actions used, and hints already requested — rather than from a counter that participates in optimistic concurrency. `Hint.level` already communicates the rung to the client, which displays it.

The reason is behavioural, not technical. If hints took part in optimistic concurrency, asking for help immediately after an evidence action could return `409`, and the learner would be told they had a conflict when all they did was ask a question. Asking for help must be the lowest-friction action in the product; a coach that can refuse on a race is worse than no coach.

If a hint request must be counted for rate limiting or cost control, that counter lives outside the attempt aggregate's version.

## Consequences

- `docs/03-contracts/API_CONTRACT.md`, `contracts/openapi.yaml` and the Role 4 persistence handoff drop the checkpoint language and gain the evidence-action `version` and `attemptVersion` response field.
- Role 3 is unaffected — no evidence, content or coach behaviour changes.
- Role 1 must send `version` on evidence actions and track the returned `attemptVersion`. The client currently reads `version` only from the prediction response, which is exactly the bug this prevents.
- ADR-008 decisions 1–4 stand unchanged.

## Alternatives considered

**Keep the checkpoint by splitting completion into two transactions.** Rejected: it makes a partially-completed attempt observable, so a crash between the two commits leaves a learner scored but without a receipt or XP. That is the failure the atomic model exists to prevent, and it buys only the ability to skip re-scoring on retry — work measured in milliseconds.

**Leave evidence actions without `version`.** Rejected: two evidence actions racing would both apply, and the attempt's version would advance without either caller knowing, which surfaces later as an unrecoverable `409` at conclusion.
