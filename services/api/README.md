# Evidence Gym API

FastAPI modular-monolith scaffold for the learner API. The normative learner
contract remains [`contracts/openapi.yaml`](../../contracts/openapi.yaml).

## Local development

Requires Python 3.12 or 3.13.

```bash
python -m venv .venv
python -m pip install -e ".[test]"
python -m uvicorn evidence_gym_api.main:app --reload
python -m pytest
```

Operational endpoints are deliberately outside the contract's `/v1` learner
surface:

- `GET /health` reports process liveness.
- `GET /ready` reports whether injected runtime dependencies are ready.

Every response includes `X-Trace-ID`. A valid incoming `X-Trace-ID` is
propagated; otherwise the API generates a UUID. Errors use
`application/problem+json` and match the contract's Problem fields.

The learning package currently provides pure attempt-domain behavior,
application ports, deterministic in-memory test adapters, and the `StartAttempt`
and `SubmitPrediction` use cases. Persistence implementers should follow
[`ROLE4_PERSISTENCE_HANDOFF.md`](ROLE4_PERSISTENCE_HANDOFF.md).

Implemented public catalog endpoints:

- `GET /catalog/path`
- `GET /missions/{missionId}`

The public mission projection exposes only the OpenAPI mission fields and
accessibility alternatives. It deliberately omits deterministic evidence
responses, accepted assessments, gold evidence graphs, hints, rubric/eval hooks,
and licensing notes. The default ASGI entry point wires these endpoints to the
checked-in P0 demo pack through the hash-verifying `FileMissionPolicyReader`.

Implemented learner mutations:

- `POST /attempts`
- `POST /attempts/{attemptId}/prediction`

Both require a verified Firebase bearer principal and `Idempotency-Key`. The
repository contains only a fake verifier for tests; runtime Firebase verification
must be injected through the application factory.

`FileMissionPolicyReader` validates Role 3's checked-in pack manifest and mission
schema, verifies each SHA-256, rejects unsafe paths or duplicate versions, and
returns only the exact version requested by `StartAttempt`.

`FixtureDeterministicEvidenceProvider` reads only the selected action's validated
`deterministicResponse` from that exact mission version. It returns immutable,
normalized evidence data, preserves `not_found` as uncertainty, exposes no gold
assessment or rubric fields, and never calls a live provider. The state-changing
evidence HTTP endpoint remains intentionally unwired until its optimistic-version
request semantics are agreed in the shared API contract.
