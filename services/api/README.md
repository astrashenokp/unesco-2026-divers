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

The runtime denies cross-origin browser access and has no identity verifier by
default. For local Flutter Web development, choose an explicit browser port and
enable the deterministic verifier only in the development environment:

```powershell
$env:EVIDENCE_GYM_ENV = "development"
$env:EVIDENCE_GYM_CORS_ORIGINS = "http://localhost:8080"
$env:EVIDENCE_GYM_DEV_IDENTITY_ENABLED = "true"
$env:EVIDENCE_GYM_DEV_IDENTITY_TOKEN = "replace-with-a-local-token"
$env:EVIDENCE_GYM_DEV_LEARNER_ID = "local-learner"
python -m uvicorn evidence_gym_api.main:app --reload
```

Only explicit HTTP(S) origins are accepted; wildcards are rejected. The local
verifier refuses to start outside `EVIDENCE_GYM_ENV=development`, accepts only
the configured token, and is not a replacement for Firebase verification.

Operational endpoints are deliberately outside the contract's `/v1` learner
surface:

- `GET /health` reports process liveness.
- `GET /ready` reports whether injected runtime dependencies are ready.

Every response includes `X-Trace-ID`. A valid incoming `X-Trace-ID` is
propagated; otherwise the API generates a UUID. Errors use
`application/problem+json` and match the contract's Problem fields.

The learning package currently provides pure attempt-domain behavior,
application ports, deterministic local in-memory adapters, and use cases for
starting attempts, submitting predictions, using deterministic evidence actions
and requesting bounded Socratic hints. Persistence implementers should follow
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
- `POST /attempts/{attemptId}/evidence-actions`
- `POST /attempts/{attemptId}/hints`

All require a verified Firebase bearer principal and `Idempotency-Key`. The
repository contains only a fake verifier for tests/local composition checks;
runtime Firebase verification must be injected through the application factory.

`FileMissionPolicyReader` validates Role 3's checked-in pack manifest and mission
schema, verifies each SHA-256, rejects unsafe paths or duplicate versions, and
returns only the exact version requested by `StartAttempt`.

`FixtureDeterministicEvidenceProvider` reads only the selected action's validated
`deterministicResponse` from that exact mission version. It returns immutable,
normalized evidence data, preserves `not_found` as uncertainty, exposes no gold
assessment or rubric fields, and never calls a live provider. The
`POST /attempts/{attemptId}/evidence-actions` endpoint validates ownership and
optimistic versioning, records the action atomically, supports idempotent retries,
and returns the updated `attemptVersion` required by the shared API contract.

`POST /attempts/{attemptId}/hints` returns the reviewed deterministic fallback
when no safe model provider is configured. It validates allowed actions,
available evidence refs, forbidden leakage terms and safety flags before a hint
reaches the learner. Unsafe, malformed or unavailable provider output degrades
to the reviewed `hintLadder` entry through `FixtureCoachProvider`; level 5 is
never exposed before conclusion, and hints never advance `Attempt.version`.
