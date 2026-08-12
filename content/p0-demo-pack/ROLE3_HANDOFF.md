# Role 3 handoff: P0 mission fixtures and Socratic coach gate

## Goal / status

Integration-ready draft - Role 3 has created schema-first P0 mission fixtures,
deterministic evidence responses, a bounded coach output contract and an eval
gate for the two demo missions. The branch has been merged with `origin/main`
through ADR-009 and the deterministic fixture reader/provider work.

## Changed

- `contracts/mission-fixture.schema.json`: strict mission fixture contract with
  explicit `testsCriticalIgnoring` and mandatory deterministic evidence
  responses. The contract is `schemaVersion: 2` because accessibility and
  rubric eval hooks are required fields. `forbiddenLeakageTerms` is now
  required with `minItems: 1` (gold-leakage guard cannot be empty). `media.url`
  is required by schema when `media.type` is `image`, `video`, or `audio`.
- `contracts/openapi.yaml`: public `Mission` projections now include required
  `accessibility` fields so Role 1 can render media-independent paths through
  the API contract.
- `services/api/src/evidence_gym_api/catalog/api.py` and
  `mission_fixture_reader.py`: public read-only catalog projections for
  `GET /catalog/path` and `GET /missions/{missionId}`. These projections expose
  only OpenAPI-safe mission fields and do not leak gold evidence, deterministic
  responses, hints, rubric or eval hooks.
- `content/p0-demo-pack/manifest.json`: draft P0 demo pack manifest with
  mission SHA-256 hashes and draft-only review metadata.
- `content/p0-demo-pack/media/flood-context-card.jpg`: checked-in
  public-domain flood photo from USGS, courtesy of Metro Transit Authority, used
  by Mission 1.
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
- `services/api/tests/test_contract.py`, `test_catalog_api.py`,
  `test_mission_fixtures.py`, `test_mission_fixture_reader.py`,
  `test_deterministic_evidence_provider.py` and `test_coach_evals.py`:
  contract/catalog/fixture/reader/provider/eval guard tests.

## Contracts and decisions

- `testsCriticalIgnoring` is an explicit boolean in checked-in P0 mission
  fixtures. Role 2 maps it to `Attempt.allows_no_evidence_conclusion`.
- `rubric.minimumCompletionEvidence` is mapped to
  `Attempt.minimum_required_evidence_actions` when the attempt is started, so
  mission-version policy is pinned and enforced before conclusion. The public
  mission projection exposes `minimumCompletionEvidence` so clients can disable
  conclusion affordances before the server returns a policy conflict.
- Mission fixture `schemaVersion: 2` is a deliberate contract bump for required
  accessibility alternatives and `rubric.evalHooks`.
- Pack-local media URLs use `asset://<manifest-id>/...` and resolve to
  checked-in files under the reviewed pack directory.
- Public catalog endpoints are wired to the hash-verifying
  `FileMissionPolicyReader`; the default ASGI entry point serves the checked-in
  P0 demo pack for local/demo integration.
- Every P0 `evidenceActions[].deterministicResponse` is required. Demo evidence
  must not require live Crossref/OpenAlex/search/C2PA calls.
- Coach output must validate against `contracts/coach-output.schema.json` before
  learner display.
- OpenAPI evidence-action shape follows ADR-009: evidence-action requests carry
  `version`, evidence results carry `attemptVersion`, hints do not advance
  `Attempt.version`, and completion is atomic.
- ADR-008 remains the source of truth for foreign attempts, guest auth,
  idempotency retention and `testsCriticalIgnoring`; ADR-009 supersedes its
  earlier checkpoint wording for `reflected`.

## Safety and data

- Fixtures are `draft`; they are stable for integration but not public
  publication approval.
- Mission 1 uses a real public-domain USGS flood photo as checked-in media, but
  the Munich claim and supporting demo context are not live emergency claims.
  Mission 2 remains a team-created deterministic citation fixture, not a live
  registry claim.
- No raw user uploads, personal data, secrets or live learner prompts are stored.
- Mission 2 preserves the hard rule: `not_found` means not found in queried
  sources, not fabricated. Its registry lookup exposes citable
  `E-DOI-NOT-FOUND` evidence with academic-registry provenance, timestamp and
  limitations.
- AI cannot score, award XP, publish content, mutate attempt state or reveal gold
  conclusions before completion.

## Verification

- `python3 -m json.tool contracts/mission-fixture.schema.json`
- `python3 -m json.tool contracts/coach-output.schema.json`
- `python3 -m json.tool content/p0-demo-pack/manifest.json`
- `python3 -m json.tool content/p0-demo-pack/missions/authentic-media-wrong-context.json`
- `python3 -m json.tool content/p0-demo-pack/missions/ai-citation-integrity.json`
- `python3 -m json.tool evals/coach/p0-eval-cases.json`
- `python3 -m pytest services/api -q -p no:cacheprovider` - 153 passed.
- `python3 -m pytest services/api --collect-only -q` - 153 tests collected.

## Risks / assumptions

- The two missions are draft training fixtures. Public release still needs
  independent fact/content/accessibility/license review, including a re-check of
  the USGS public-domain source page and attribution for Mission 1.
- The eval gate is executable against a result JSON file, but the model-run
  harness that produces those results still needs to plug into it.
- JSON Schema validation is wired through the `services/api[test]` dependency
  set with date-time/URI format checking for the manifest and both P0 mission
  fixtures. The reader also rejects duplicate JSON properties, hash mismatches,
  duplicate mission versions and paths outside the reviewed missions folder.
- Semantic fixture tests enforce unique action/evidence IDs, ordered hint/rubric
  levels, non-inverted confidence ranges and duplicate-free coach eval results.
- Public catalog tests enforce unauthenticated path/mission access, accessibility
  projection, default ASGI pack wiring and no gold/rubric/hint/eval leakage in
  mission responses.
- Mission fixtures now expose explicit presentation accessibility fields and
  rubric eval hooks that reference known coach eval cases.
- The coach gate runner enforces critical, release-blocking and category-specific
  zero-failure thresholds for gold leakage, invented evidence and
  `not_found`-as-fabricated regressions.
- Eval result files must match the suite ID and use strict JSON booleans for
  `caseResults[].passed`; string values such as `"false"` are rejected.
- Ukrainian learner-facing mission localization is not yet authored; one
  Ukrainian hard-rule eval case is included for coach behavior.

## Next

- Role 2: wire the deterministic evidence provider into the evidence-action use
  case while preserving ADR-009 version checks. Acceptance: reads both fixtures,
  pins mission version, maps `testsCriticalIgnoring`, returns `attemptVersion`
  and never calls a live provider in demo mode.
- Role 1: render mission claim/media/actions from the public catalog API and
  hints from the coach boundary. Acceptance: both missions are playable with
  accessible alt text and no binary truth cues.
- Role 4: map rubric/skill tags into XP/progression rules without letting AI
  award XP. Acceptance: completion remains idempotent and process XP is
  server-side.
- Evidence Guardian: run AI/content safety review against the eval thresholds.
  Acceptance: zero critical failures before demo/pilot exposure.
