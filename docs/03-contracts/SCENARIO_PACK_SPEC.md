# Scenario pack specification

A scenario pack is a portable, versioned, reviewable learning-content bundle. JSON validation is defined in `contracts/scenario-pack.schema.json`.

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
- primary audience/age band, license and author/reviewer IDs;
- created/published/review-expiry dates;
- ordered mission references and SHA-256 hashes;
- accessibility/low-bandwidth availability;
- content warnings and region notes.

## Mission minimum

- one learning objective and skill tags;
- presented claim/context/media with alternatives;
- allowed initial reactions;
- evidence actions and stable evidence IDs;
- gold evidence graph with source identity/retrieval/license metadata;
- accepted three-axis assessments, including uncertainty ranges;
- Socratic hint ladder and forbidden leakage terms;
- rubric, correction/history metadata, reviewer sign-off.

## Publication gates

Schema valid; hashes valid; sources reachable or lawfully snapshotted; media license recorded; accessibility assets present; bias/harm review complete; two reviewers for real/sensitive cases; expiry date present; deterministic offline path passes.

## Trust

Pack signatures prove integrity/publisher identity, not truth. Clients reject hash/signature mismatch, unsupported schema, future publish date, expired critical revocation, path traversal and oversized/decompression-bomb assets.
