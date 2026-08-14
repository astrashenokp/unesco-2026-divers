# Scenario pack specification

A scenario pack is a portable, versioned, reviewable learning-content bundle.
Manifest JSON validation is defined in `contracts/scenario-pack.schema.json`.
Mission fixture JSON validation is defined in `contracts/mission-fixture.schema.json`.

## Layout

```text
pack/
  manifest.json
  missions/<mission-id>.json
  media/<licensed-assets>
  locales/en.arb
  locales/uk.arb
  sources/<optional-lawful-snapshots-or-metadata>
  SIGNATURE
```

## Manifest minimum

- unique `id`, semantic `version`, `schemaVersion`;
- title/description and BCP 47 locales;
- primary audience/age band, license and draft/review status;
- author IDs, drafted date, review-expiry date, and reviewer sign-off only for
  approved/restricted packs;
- ordered mission references and SHA-256 hashes;
- accessibility/low-bandwidth availability;
- content warnings and region notes.

## Mission minimum

- one learning objective and skill tags;
- presented claim/context/media with accessibility alternatives;
- media assets referenced by `asset://<manifest-id>/...` resolve to checked-in
  files inside the reviewed pack directory;
- allowed initial reactions;
- evidence actions and stable evidence IDs;
- deterministic response for every P0 evidence action, so demo mode never depends on live third-party APIs;
- gold evidence graph with source identity/retrieval/license metadata;
- accepted three-axis assessments, including uncertainty ranges;
- Socratic hint ladder and forbidden leakage terms;
- rubric with process levels 0-4, skill tags, confidence calibration,
  responsible-sharing and uncertainty guidance, eval hooks,
  correction/history metadata, reviewer sign-off;
- explicit `testsCriticalIgnoring` boolean in P0 fixtures. Mission fixture
  `schemaVersion: 2` requires this field; legacy/pre-v2 importers may only
  default an omitted value to `false` during migration before validating as v2.
  Role 2 maps the explicit v2 value to
  `Attempt.allows_no_evidence_conclusion`. When `true`, the conclusion endpoint
  accepts zero evidence actions for this mission version because the mission is
  deliberately testing whether the learner concludes without investigating
  (ADR-008).

Mission fixture `schemaVersion: 2` makes presentation accessibility and rubric
eval hooks mandatory. `rubric.evalHooks` includes `coachEvalCaseRefs` for the
release gate, `observableSignals` for process-scoring instrumentation, and
`blockingFailureSignals` for failures that should stop publication or demo
promotion.

Rubric semantics are defined in
`docs/01-product/RUBRIC_AND_XP_GUIDANCE.md`. XP is server-awarded from the
version-pinned rubric and must never be treated as a truth, intelligence or
trustworthiness score. The AI coach may explain the reviewed rubric after
completion but must not award XP or decide score.

## Publication gates

Schema valid; hashes valid; sources reachable or lawfully snapshotted; media license recorded; accessibility assets present; bias/harm review complete; two reviewers for real/sensitive cases; expiry date present; deterministic offline path passes.

## Trust

Pack signatures prove integrity/publisher identity, not truth. Clients reject hash/signature mismatch, unsupported schema, future publish date, expired critical revocation, path traversal and oversized/decompression-bomb assets.
