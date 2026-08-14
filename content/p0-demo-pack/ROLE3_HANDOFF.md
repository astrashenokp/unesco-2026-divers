# Role 3 handoff: P0 mission fixtures and Socratic coach gate

## Goal / status

Integration-ready review packet - Role 3 has created schema-first P0 mission
fixtures, deterministic evidence responses, a bounded coach output contract and
an eval gate for the two demo missions. The pack is in `review` state with an
Evidence Guardian review lane documented in `REVIEW_PACKET.md`; it is not
marked `approved` and `reviewerIds` remains empty until human sign-off records
`reviewedAt`.

## Changed

- `contracts/mission-fixture.schema.json`: strict mission fixture contract with
  explicit `testsCriticalIgnoring` and mandatory deterministic evidence
  responses. Deterministic responses must include at least one evidence item and
  one limitation. The contract is `schemaVersion: 2` because accessibility and
  rubric eval hooks are required fields. `forbiddenLeakageTerms` is now required
  with `minItems: 1` (gold-leakage guard cannot be empty). `media.url` is
  required by schema when `media.type` is `image`, `video`, or `audio`.
- `contracts/openapi.yaml`: public `Mission` projections now include required
  `accessibility` fields so Role 1 can render media-independent paths through
  the API contract.
- `docs/01-product/RUBRIC_AND_XP_GUIDANCE.md`,
  `docs/01-product/GAME_AND_LEARNING_DESIGN.md`,
  `docs/03-contracts/API_CONTRACT.md`,
  `docs/03-contracts/SCENARIO_PACK_SPEC.md` and
  `docs/04-security/AI_SAFETY.md`: rubric/XP guidance states that scoring
  rewards investigation quality, confidence calibration, uncertainty handling
  and responsible sharing, not guessing or learner intelligence.
- `services/api/src/evidence_gym_api/catalog/api.py` and
  `mission_fixture_reader.py`: public read-only catalog projections for
  `GET /catalog/path` and `GET /missions/{missionId}`. These projections expose
  only OpenAPI-safe mission fields and do not leak gold evidence, deterministic
  responses, hints, rubric or eval hooks.
- `content/p0-demo-pack/manifest.json`: review-stage P0 demo pack manifest with
  mission SHA-256 hashes and explicit review metadata.
- `content/p0-demo-pack/REVIEW_PACKET.md`, `locales/en.arb`,
  `locales/uk.arb`, `sources/` and `SIGNATURE.UNSIGNED`: review packet, source
  packets, canonical English locale metadata, Ukrainian UI/demo title stubs and
  unsigned review marker for pack-completeness review without pretending the
  pack is publicly signed.
- `content/p0-demo-pack/media/flood-context-card.jpg`: checked-in
  public-domain flood photo from USGS, courtesy of Metro Transit Authority, used
  by Mission 1.
- `content/p0-demo-pack/missions/authentic-media-wrong-context.json`:
  review-stage mission for authentic media used in misleading context.
- `content/p0-demo-pack/missions/ai-citation-integrity.json`: review-stage
  mission for AI-suggested academic citation checking.
- `contracts/coach-output.schema.json`: structured output contract for coach
  responses before mapping to the public Hint API.
- `content/p0-demo-pack/coach-policy.md`: P0 Socratic coach policy and fallback
  behavior.
- `evals/coach/p0-eval-cases.json`: release thresholds and critical eval cases.
- `evals/coach/run_gate.py`: executable threshold gate for coach/model run
  results.
- `evals/coach/p0-fixture-results.json`: checked-in deterministic fixture
  preflight result artifact that passes the release gate for the P0 fallback
  path. It is a fallback-contract artifact, not a model-run artifact or broad
  live-model safety claim.
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
- Every P0 `evidenceActions[].deterministicResponse` is required and non-empty.
  Each response item includes source metadata directly: publisher, source type,
  retrieval timestamp, license and limitations. Demo evidence must not require
  live Crossref/OpenAlex/search/C2PA calls.
- Coach output must validate against `contracts/coach-output.schema.json` before
  learner display.
- OpenAPI evidence-action shape follows ADR-009: evidence-action requests carry
  `version`, evidence results carry `attemptVersion`, hints do not advance
  `Attempt.version`, and completion is atomic.
- ADR-008 remains the source of truth for foreign attempts, guest auth,
  idempotency retention and `testsCriticalIgnoring`; ADR-009 supersedes its
  earlier checkpoint wording for `reflected`.
- P0 process XP uses levels 0-4 from the version-pinned rubric. The current
  runtime signal is completed evidence-action count capped at 4; qualitative
  action-quality guidance remains in reviewed rubric text, skill tags and eval
  hooks unless a future schema-reviewed scorer is introduced. XP is not a truth,
  intelligence or trustworthiness score, `insufficient_evidence` can be correct,
  and the AI coach cannot award XP.

## Role-specific handoff

### Role 1 - Frontend and experience

Role 1 consumes the public catalog/API projection and learner-safe runtime
responses only. Do not render gold evidence, accepted assessments, forbidden
leakage terms, deterministic response internals, rubric eval hooks or coach eval
case content before completion.

- Fields to render: public `Mission` fields `id`, `version`, `title`, `claim`,
  `media`, `accessibility`, `reactions`, `evidenceActions`,
  `evidenceActions[].id`, `evidenceActions[].type`,
  `evidenceActions[].label`, `skillTags`, `contentWarnings`,
  `testsCriticalIgnoring`, `minimumCompletionEvidence` and runtime
  `EvidenceResult`/`Hint` responses. Do not expect fixture-only locale, arena,
  presentation context, action descriptions, action costs or action-level skill
  tags from the public mission projection unless a schema-first contract change
  adds them.
- Evidence action labels: use the reviewed labels from
  `evidenceActions[].label`; keep action IDs stable and hidden as implementation
  identifiers except where test/debug output needs them.
- Hint levels: render public `Hint.level` and `Hint.fallback`; hints come from
  the coach boundary after schema validation or deterministic fallback, not from
  mission fixture `hintLadder` directly.
- Alt text/transcripts: render `presentation.media.altText`,
  `presentation.media.transcript` when present, and the accessibility
  alternatives from `presentation.accessibility.mediaAlternatives` and
  `presentation.accessibility.interactionNotes`.
- Localization notes: P0 mission fixture prose is currently English. Preserve UI
  Ukrainian localization for chrome/error states, allow text expansion, and do
  not machine-translate claim/evidence text without reviewed localized mission
  content. `manifest.locales` lists only reviewed canonical pack locales; the
  checked-in Ukrainian ARB file is a UI/demo-title stub.
- Acceptance signal: both P0 missions are playable from public API data, evidence
  cards show source publisher/provenance without truth-oracle cues, and 200%
  text plus screen-reader paths still work.

### Role 2 - Backend and domain

Role 2 owns the API/use-case mapping and domain invariants. Role 2 should not
weaken mission fixture validation, trust client-provided score/completion state
or turn deterministic demo behavior into live provider dependency.

- Mission fixture schema: load P0 missions through
  `contracts/mission-fixture.schema.json` and the hash-verifying
  `FileMissionPolicyReader`; reject duplicate JSON keys, hash mismatches,
  invalid date-time/URI formats and paths outside the reviewed pack.
- `testsCriticalIgnoring`: map the explicit fixture boolean to the pinned
  attempt policy. If `true`, the conclusion can ignore minimum evidence under
  ADR-008; if `false`, enforce `rubric.minimumCompletionEvidence`.
- Deterministic response format: every `evidence_action_id` has
  `deterministicResponse` with `actionId`, `status`, non-empty `items`,
  non-empty top-level `limitations`, item `evidenceId`, `retrievedAt`,
  `verificationStatus` and direct `source` metadata with source type, publisher,
  retrievedAt, license and limitations.
- Policy reader expectations: start attempts against the version-pinned mission
  policy, return `attemptVersion` after evidence actions, preserve `not_found`
  as a limited lookup status and never call Crossref/OpenAlex/C2PA/search in P0
  demo mode.
- Acceptance signal: API contract tests cover the public `Mission`,
  `EvidenceResult` and ADR-009 version behavior, including provider outage and
  duplicate/stale evidence-action paths.

### Role 4 - Game, data, security and reliability

Role 4 owns progression/runtime gates and any persistence or CI path that turns
the rubric into durable learner state. Role 4 should not add semantic truth
scoring or let model output mutate XP/progress.

- Rubric inputs: use the version-pinned mission rubric, especially
  `rubric.processLevels`, `rubric.minimumCompletionEvidence`,
  `rubric.confidenceCalibration` and the learner's completed evidence-action
  count.
- Skill tags: preserve reviewed `learning.skillTags`,
  `evidenceActions[].skillTags` and `rubric.processLevels[].skillTags` as
  instrumentation/progression metadata; do not reinterpret tags as a truth or
  intelligence score.
- Progression/XP guidance: process level is `min(usedEvidenceActions, 4)` for
  P0. XP is server-side, deterministic, idempotent and independent of whether
  the initial prediction was right. `insufficient_evidence` can receive full
  process XP when the investigation supports that conclusion.
- Demo deterministic assumptions: P0 demo must run from checked-in fixtures and
  deterministic fallback paths during provider/model outages; live provider
  adapters are future work and must be behind schema-reviewed contracts and
  outage tests.
- Acceptance signal: progression tests prove no truth/verdict/model-score input
  reaches `award_xp`, completion remains idempotent, and demo fallback is part of
  release verification.

### Evidence Guardian

Evidence Guardian audits independently and routes findings back to the affected
owner. It does not absorb implementation responsibility and does not publish,
deploy, mutate learner state or approve content alone.

- Eval thresholds: `evals/coach/p0-eval-cases.json` and
  `evals/coach/run_gate.py` are the release gate. Critical, release-blocking,
  gold leakage, prompt/tool misuse, secret/PII disclosure, publication mutation,
  forged citation, invented evidence ref, unsupported verdict,
  `not_found`-as-fabricated, conflicting evidence misuse, insufficient evidence
  misuse and hard-rule consistency failures allow zero failures.
- AI/content safety risks: verify prompt injection resistance, malformed model
  JSON fallback, provider timeout fallback, deterministic guard fallback,
  Socratic tone, no binary truth score and no automatic false/harmful label for
  generated content.
- Forbidden leakage: pre-completion coach/UI output must not reveal gold
  conclusions, accepted assessments, hidden evidence graph answers or
  `forbiddenLeakageTerms`.
- Source provenance requirements: every displayed evidence item must trace to
  source type, publisher, retrieval timestamp, license/use basis and limitations;
  `not_found` remains a limited lookup result, not proof of fabrication.
- Acceptance signal: the eval gate passes with zero critical failures and any
  non-critical wording issue is recorded as a handoff flag only when it does not
  violate a safety, privacy or contract rule.

## Safety and data

- Fixtures are `review`; they are stable for integration and submission demo
  review, but they are not public publication approval until a human reviewer
  adds `reviewedAt`.
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
- `python3 -m json.tool evals/coach/p0-fixture-results.json`
- `python3 evals/coach/run_gate.py --suite evals/coach/p0-eval-cases.json --results evals/coach/p0-fixture-results.json`
- `PYTHONPATH=/tmp/evidence-gym-pydeps:services/api/src:packages/data_access/src:packages/gameplay/src python3 -m pytest services/api/tests/test_contract.py services/api/tests/test_mission_fixtures.py services/api/tests/test_deterministic_evidence_provider.py services/api/tests/test_learning_api.py services/api/tests/test_coach_evals.py services/api/tests/test_coach_gate_runner.py -q -p no:cacheprovider` - 86 passed.
- `PYTHONPATH=/tmp/evidence-gym-pydeps:services/api/src:packages/data_access/src:packages/gameplay/src python3 -m pytest services/api packages/gameplay/tests -q -p no:cacheprovider` - 256 passed, 1 skipped.
- `PYTHONPATH=/tmp/evidence-gym-pydeps:services/api/src:packages/data_access/src:packages/gameplay/src python3 -m pytest services/api packages/gameplay/tests --collect-only -q -p no:cacheprovider` - 257 tests collected.
- `dart analyze` from `apps/learner` - no issues found.
- `flutter test` from `apps/learner` - 55 passed.

## Risks / assumptions

- The two missions are review-stage training fixtures. Public release still
  needs final human fact/content/accessibility/license sign-off, including a
  re-check of the USGS public-domain source page and attribution for Mission 1.
- The eval gate is executable against `evals/coach/p0-fixture-results.json` for
  the deterministic fixture path. That file is intentionally labelled as
  deterministic preflight, not model-run proof. A future live-model harness must
  produce its own result artifact before live model exposure.
- Coach eval suite `coach-p0-gate` is now version `0.3.0`; result JSON files
  from earlier fixture sets should be regenerated before release review.
- JSON Schema validation is wired through the `services/api[test]` dependency
  set with date-time/URI format checking for the manifest and both P0 mission
  fixtures. The reader also rejects duplicate JSON properties, hash mismatches,
  duplicate mission versions and paths outside the reviewed missions folder.
- Deterministic evidence responses now fail schema/fixture tests if they omit
  evidence items, limitations, retrieval timestamps or direct source metadata.
- Semantic fixture tests enforce unique action/evidence IDs, ordered hint/rubric
  levels, non-inverted confidence ranges and duplicate-free coach eval results.
- Rubric/XP tests enforce process levels 0-4, monotonic XP guidance, required
  skill-tag coverage, documented confidence/responsible-sharing guidance and no
  truth/verdict/model-score input to `award_xp`.
- Public catalog tests enforce unauthenticated path/mission access, accessibility
  projection, default ASGI pack wiring and no gold/rubric/hint/eval leakage in
  mission responses.
- Mission fixtures now expose explicit presentation accessibility fields and
  rubric eval hooks that reference known coach eval cases.
- The coach gate runner enforces critical, release-blocking and category-specific
  zero-failure thresholds for gold leakage, prompt/tool misuse, secret or PII
  disclosure, publication/state mutation, forged citations, invented evidence
  refs, unsupported verdicts, conflicting evidence collapse, insufficient
  evidence misuse and `not_found`-as-fabricated regressions.
- The fallback gate covers provider timeout, malformed model JSON and
  deterministic guard fallback, and requires each fallback mode to pass for every
  P0 mission.
- Eval result files must match the suite ID and use strict JSON booleans for
  `caseResults[].passed`; string values such as `"false"` are rejected.
- Flutter offline demo now renders the same two P0 mission IDs and evidence
  action IDs as the checked-in Role 3 pack, with Ukrainian and English
  learner-facing strings. The canonical mission fixtures remain English until a
  schema-reviewed multi-locale pack format is added.

## Next

- Role 2 / Evidence Guardian: preserve the default demo evidence path through
  `FixtureDeterministicEvidenceProvider` while reviewing any future provider
  adapter. Acceptance: P0 demo mode continues to read checked-in fixtures, pins
  mission version, returns `attemptVersion`, and never calls a live provider.
- Role 1: keep the demo-key path aligned to the checked-in P0 pack mission IDs,
  action IDs and minimum-evidence policy. Acceptance: both P0 missions are
  playable with accessible alt text and no binary truth cues.
- Role 4: preserve rubric/skill-tag XP/progression rules without letting AI
  award XP. Acceptance: completion remains idempotent, process XP is
  server-side, and any future semantic action-quality scorer is a schema-first
  contract change rather than model discretion.
- Evidence Guardian: run AI/content safety review against the eval thresholds.
  Acceptance: zero critical failures before demo/pilot exposure.
