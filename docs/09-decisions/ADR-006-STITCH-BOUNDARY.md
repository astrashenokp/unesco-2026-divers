# ADR-006: Google Stitch is design-time only

Status: Accepted — 2026-08-10

## Decision

Use Stitch/MCP to explore/read design context and compare approved screens. Production UI is Flutter; checked-in semantic tokens/screenshots/contracts are authoritative. QA MCP is read-only by default and receives no learner data/secrets.

## Rationale

Captures rapid design benefits without runtime/provider lock-in, React duplication or unsafe tool authority.

## Consequences

Frontend translates designs; visual comparison focuses on intent/accessibility, not pixel identity. Generation writes require human confirmation; publish/delete/deploy tools remain absent.
