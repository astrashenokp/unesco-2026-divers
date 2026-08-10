# Metrics dictionary

Metrics are decision tools, not decoration. Every metric requires an owner, event/data source, denominator, window, segmentation policy, quality check, and interpretation limit.

| Metric | Definition | Denominator/window | Primary use | Guardrail / limitation |
|---|---|---|---|---|
| Core-loop completion | Eligible sessions reaching responsible-share/end state | Started eligible sessions, by scenario version | Usability | Cannot prove learning |
| Evidence inspection rate | Sessions opening at least one relevant evidence item | Started eligible sessions | Process adoption | Opening does not mean understanding |
| Evidence quality | Rubric score for selected evidence | Completed scored tasks | Immediate performance | Rubric must be blind/versioned where feasible |
| Confidence calibration | Alignment of stated confidence with task evidence/accuracy | Scored tasks | Metacognition | Not comparable across uncalibrated scenario difficulty |
| Revision rate | Sessions where confidence/conclusion changes after investigation | Sessions with pre/post response | Willingness to update | A change is not automatically correct |
| Transfer score | Performance on unseen format/topic | Participants completing transfer task | Near transfer | Requires controlled content difficulty |
| Delayed retention | Performance after predeclared delay | Participants reached at follow-up | Retention | Attrition bias must be reported |
| Critical safety incident | Event meeting safety taxonomy threshold | Absolute count and rate | Stop/mitigate | Never optimise away through averaging |
| Accessibility task success | Completion with declared access mode | Sessions by access mode | Inclusion | Small groups require privacy-safe reporting |
| Scenario correction rate | Published packs corrected/withdrawn | Active scenario versions per period | Content quality | Low rate may reflect weak reporting |

## Counter-metrics

Track alongside engagement:

- excessive session duration or repeated failure;
- notification opt-out and complaint rate;
- exposure to harmful content;
- overconfident answers after feedback;
- accessibility failure rate;
- moderator help required;
- privacy or deletion requests;
- unequal outcomes across meaningful, safely reportable segments.

## Reporting rules

- Always show numerator and denominator with percentages.
- Mark exploratory analysis and avoid post-hoc causal language.
- Preserve scenario, rubric, product, and metric-definition versions.
- Suppress or aggregate small cells to reduce re-identification risk.
- Never use a single engagement metric as the product’s north star.
