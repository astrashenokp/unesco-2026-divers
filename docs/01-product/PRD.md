# Product requirements

## Objective

Demonstrate that a learner can perform a better verification process and better calibrate confidence after a short, delightful session.

## P0 functional requirements

| ID | Requirement | Acceptance signal |
|---|---|---|
| P0-01 | Start one guest or signed-in learning session | session resumes after interruption without duplicate XP |
| P0-02 | Show a mission with claim, media, context and accessibility alternative | media has caption/transcript/alt text |
| P0-03 | Capture choice and 0–100 confidence before investigation | immutable pre-answer stored with consent-safe identifiers |
| P0-04 | Offer bounded evidence actions | each action returns source, date, excerpt/summary and provenance |
| P0-05 | Provide Socratic hints | no hidden gold verdict is exposed before conclusion |
| P0-06 | Capture three-axis conclusion and `insufficient evidence` | schema validation succeeds |
| P0-07 | Capture post-investigation confidence/share decision | calibration delta is computed server-side |
| P0-08 | Generate Evidence Receipt | receipt reproduces the sources/actions used |
| P0-09 | Award process XP and update learning path | idempotent completion, no double rewards |
| P0-10 | Provide two curated demo missions | deterministic demo works offline from cached pack |
| P0-11 | Ukrainian/English localization shell | no hard-coded learner-facing P0 strings |
| P0-12 | Collect pilot metrics with consent | export contains no raw prompt/upload or direct identity |

## Quality requirements

- Core API p95 below 500 ms excluding external AI/search; hint p95 target below 4 s with progressive UI.
- 99.5% monthly availability pilot target; demo has offline fallback.
- WCAG 2.2 AA for web semantics and equivalent Flutter accessibility checks.
- No high/critical known vulnerabilities at release.
- AI coach grounded-answer faithfulness and policy pass rates at least 95% on the gold eval set; any failure blocks autonomous exposure.

## Analytics events

Minimal events: `mission_started`, `prediction_submitted`, `evidence_action_used`, `hint_requested`, `conclusion_submitted`, `confidence_updated`, `receipt_viewed`, `booster_completed`. Event payloads use pseudonymous IDs and enumerations, not content bodies.

## Open product decisions

- Final brand after a trademark/domain check.
- Exact lower age limit after consent/legal review; default MVP is 16+.
- Whether accountless local-only use is included in demo or immediately after.
