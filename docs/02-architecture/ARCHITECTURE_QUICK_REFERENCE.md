# Architecture quick reference

This is a navigational summary, not a second source of truth. The canonical detail remains [ARCHITECTURE.md](ARCHITECTURE.md) and accepted ADRs.

## Product boundary

Evidence Gym delivers short, versioned media-literacy scenarios. The core invariant is that learner-visible conclusions and feedback remain traceable to reviewed evidence and scenario versions.

## Core domains

| Domain | Owns | Must not own |
|---|---|---|
| Identity and access | account/session, consent state, permission checks | learning-content truth |
| Learning session | scenario attempt, progress, confidence updates | scenario authoring source |
| Content and provenance | scenarios, evidence, rights, review/version state | user credentials |
| Feedback and AI | bounded feedback request/result, citations, fallback | authoritative truth or irreversible decisions |
| Impact and experimentation | exposure, outcome events, metric versions | raw secrets or unnecessary personal content |
| Safety and moderation | reports, review state, escalation/audit | silent content deletion |

## Critical runtime path

`approved scenario version → session starts → prediction/confidence → evidence inspection → conclusion/evidence selection → bounded feedback → confidence update → safe completion event`

The critical learning path should have a deterministic fallback when an AI provider is unavailable.

## Data classes

- Public: published product and scenario metadata intended for anyone.
- Internal: non-sensitive operational documentation and aggregate data.
- Confidential: unpublished content, partner material, internal analytics.
- Restricted: credentials, authentication material, participant identifiers, safeguarding reports, sensitive research data.

Restricted data never enters prompts, screenshots, public logs, or design tools by default.

## Architecture invariants

1. Start as a modular monolith; extract services only with measured scaling or ownership need.
2. APIs, events, and scenario packs are versioned contracts.
3. Published content is immutable; correction creates a new state/version and preserves audit history.
4. AI output is untrusted, bounded, evidence-linked, observable, and replaceable.
5. Authorization is enforced server-side for every protected action.
6. Analytics uses minimised, pseudonymous data with documented consent and retention.
7. External dependencies have timeouts, failure handling, and an owned fallback.
8. Accessibility and low-bandwidth behaviour are acceptance criteria, not later enhancements.

## Decision routing

- Product outcome or scope: product docs and decision log.
- Domain/system shape: ADR plus canonical architecture update.
- Interface: contract change with compatibility review.
- New data: privacy/security review before collection.
- New scenario/source: content provenance and rights review.
- New AI/external provider: vendor, privacy, safety, failure, and cost review.

## Go/no-go gates

| Gate | Minimum proof |
|---|---|
| Demo | critical loop reproducible; backup evidence available |
| Pilot | consent, safeguarding, versioned protocol, stop conditions |
| Public beta | threat model, incident path, deletion/correction flow, monitoring |
| Partner rollout | agreement, content/data rights, support and exit plan |
| Scale | measured bottleneck, cost model, rollback, capacity evidence |

## Read next

- [Domain model](DOMAIN_MODEL.md)
- [Data model](DATA_MODEL.md)
- [AI pipeline](AI_PIPELINE.md)
- [Failure modes](FAILURE_MODES.md)
- [Non-functional requirements](NON_FUNCTIONAL_REQUIREMENTS.md)
- [Architecture decisions](../09-decisions/README.md)
