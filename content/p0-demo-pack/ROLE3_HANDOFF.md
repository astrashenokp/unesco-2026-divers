# Role 3 handoff: P0 mission fixtures and Socratic coach gate

## Goal / status

Partial but integration-ready - Role 3 has created schema-first P0 mission
fixtures, deterministic evidence responses, a bounded coach output contract and
an eval gate for the two demo missions.

## Changed

- `contracts/mission-fixture.schema.json`: strict mission fixture contract with
  explicit `testsCriticalIgnoring` and mandatory deterministic evidence
  responses.
- `content/p0-demo-pack/manifest.json`: draft P0 demo pack manifest with
  mission SHA-256 hashes and draft-only review metadata.
- `content/p0-demo-pack/missions/authentic-media-wrong-context.json`: draft
  mission for authentic media used in misleading context.
- `content/p0-demo-pack/missions/ai-citation-integrity.json`: draft mission for
  AI-suggested academic citation checking.
- `contracts/coach-output.schema.json`: structured output contract for coach
  responses before mapping to the public Hint API.
- `content/p0-demo-pack/coach-policy.md`: P0 Socratic coach policy and fallback
  behavior.
- `evals/coach/p0-eval-cases.json`: release thresholds and critical eval cases.
- `evals/coach/run_gate.py`: executable threshold gate for coach/model run
  results.
- `services/api/tests/test_contract.py`, `test_mission_fixtures.py`, and
  `test_coach_evals.py`: contract/fixture/eval guard tests.

## Contracts and decisions

- `testsCriticalIgnoring` is an explicit boolean in checked-in P0 mission
  fixtures. Role 2 maps it to `Attempt.allows_no_evidence_conclusion`.
- Every P0 `evidenceActions[].deterministicResponse` is required. Demo evidence
  must not require live Crossref/OpenAlex/search/C2PA calls.
- Coach output must validate against `contracts/coach-output.schema.json` before
  learner display.
- No OpenAPI endpoint shape changed.
- ADR-008 remains the source of truth for foreign attempts, guest auth,
  idempotency retention and `reflected`.

## Safety and data

- Fixtures are `draft`; they are stable for integration but not public
  publication approval.
- Demo source packets are team-created deterministic content, not live emergency
  or live registry claims.
- No raw user uploads, personal data, secrets or live learner prompts are stored.
- Mission 2 preserves the hard rule: `not_found` means not found in queried
  sources, not fabricated.
- AI cannot score, award XP, publish content, mutate attempt state or reveal gold
  conclusions before completion.

## Verification

- `python3 -m json.tool contracts/mission-fixture.schema.json`
- `python3 -m json.tool contracts/coach-output.schema.json`
- `python3 -m json.tool content/p0-demo-pack/manifest.json`
- `python3 -m json.tool content/p0-demo-pack/missions/authentic-media-wrong-context.json`
- `python3 -m json.tool content/p0-demo-pack/missions/ai-citation-integrity.json`
- `python3 -m json.tool evals/coach/p0-eval-cases.json`
- `python3 -m pytest services/api -q -p no:cacheprovider` - 111 passed.
- `python3 -m pytest services/api --collect-only -q` - 111 tests collected.

## Risks / assumptions

- The two missions are draft deterministic training fixtures. Public release
  still needs independent fact/content/accessibility review and licensed media
  replacement or explicit approval of team-created demo assets.
- The eval gate is executable against a result JSON file, but the model-run
  harness that produces those results still needs to plug into it.
- JSON Schema validation is wired through the `services/api[test]` dependency
  set with date-time/URI format checking for the manifest and both P0 mission
  fixtures.
- Semantic fixture tests enforce unique action/evidence IDs, ordered hint/rubric
  levels, non-inverted confidence ranges and duplicate-free coach eval results.
- The coach gate runner enforces critical, release-blocking and category-specific
  zero-failure thresholds for gold leakage, invented evidence and
  `not_found`-as-fabricated regressions.
- Eval result files must match the suite ID and use strict JSON booleans for
  `caseResults[].passed`; string values such as `"false"` are rejected.
- Ukrainian learner-facing mission localization is not yet authored; one
  Ukrainian hard-rule eval case is included for coach behavior.

## Next

- Role 2: implement `MissionPolicyReader` against
  `contracts/mission-fixture.schema.json` and deterministic evidence-action
  responses. Acceptance: reads both fixtures, pins mission version, maps
  `testsCriticalIgnoring`, and never calls a live provider in demo mode.
- Role 1: render mission claim/media/actions/hints from fixtures. Acceptance:
  both missions are playable with accessible alt text and no binary truth cues.
- Role 4: map rubric/skill tags into XP/progression rules without letting AI
  award XP. Acceptance: completion remains idempotent and process XP is
  server-side.
- Evidence Guardian: run AI/content safety review against the eval thresholds.
  Acceptance: zero critical failures before demo/pilot exposure.
