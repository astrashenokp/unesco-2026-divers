# Product decision log

Use this log for product, programme, content, research, and operating decisions. Architecture decisions belong in `docs/09-decisions`.

## Decision template

| Field | Value |
|---|---|
| ID | PD-### |
| Date / status | YYYY-MM-DD — proposed/accepted/reversed/superseded |
| Decision | One testable sentence |
| Context | What changed or became known |
| Options considered | At least two genuine alternatives |
| Evidence | Links or evidence IDs |
| Consequences | Benefits, costs, risks, exclusions |
| Affected docs/claims | Exact locations |
| Review trigger | Date, result, threshold, or external change |

## Initial decisions

### PD-001 — Teach a verification process, not a binary detector

- Status: accepted; foundational.
- Decision: the core learning outcome is a transferable investigation process and calibrated confidence.
- Consequence: detection tools may appear only as fallible signals; marketing cannot promise universal truth classification.
- Sources of truth: concept, PRD, learning design, AI safety.
- Re-open trigger: none without rewriting the product thesis.

### PD-002 — Curated-first scenario publication

- Status: accepted; see ADR-007.
- Decision: no fully autonomous generation-to-publication path.
- Consequence: every published scenario has provenance, rights state, review state, and version.
- Re-open trigger: a validated governance model that preserves equal or stronger safeguards.

### PD-003 — Separate current evidence from targets

- Status: accepted.
- Decision: proposal, pitch, website, and analytics distinguish demonstrated results, sourced facts, targets, and hypotheses.
- Consequence: every material public claim maps to the evidence appendix.
- Re-open trigger: none; wording may evolve but evidence discipline remains.
