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
