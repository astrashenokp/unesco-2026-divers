# ADR-005: Immutable versioned scenario packs

Status: Accepted — 2026-08-10

## Decision

Learning content ships in validated, hashed, reviewed, localizable packs. Attempts pin a version; corrections create a new version; receipts stay reproducible.

## Rationale

Ground truth changes, external APIs fail and education/community scale needs portable reviewed content.

## Consequences

Publication workflow/license/accessibility/review expiry are mandatory. Pack integrity does not prove truth. Content migrations and cache invalidation require explicit schema/version rules.
