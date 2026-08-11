# Contract hub

Contracts are the shared boundary between four owners. Prose explains intent; machine-readable files are validated in CI.

- [API contract](API_CONTRACT.md) → `contracts/openapi.yaml`
- [Event contracts](EVENT_CONTRACTS.md)
- [Scenario pack specification](SCENARIO_PACK_SPEC.md) → `contracts/scenario-pack.schema.json` and `contracts/mission-fixture.schema.json`
- Socratic coach output → `contracts/coach-output.schema.json`
- [Team contract](TEAM_CONTRACT.md)
- [Ownership matrix](OWNERSHIP_MATRIX.md)
- [Definition of Done](DEFINITION_OF_DONE.md)

## Change policy

1. Additive change first.
2. Producer and at least one affected consumer approve.
3. Add contract tests/fixtures before implementation merge.
4. Mark deprecated fields; do not silently repurpose them.
5. Breaking change requires new API/schema version, migration and sunset date.

Server time is UTC ISO 8601; IDs are opaque strings; all errors use Problem Details-like JSON and include `traceId`.
