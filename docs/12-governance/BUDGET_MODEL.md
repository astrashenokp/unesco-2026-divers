# Budget and sustainability model

Use this model to estimate a 90-day pilot and a 12-month operating case. Enter ranges and record assumptions; false precision is less useful than visible uncertainty.

## Cost categories

| Category | Driver | Pilot assumption | Monthly low/base/high | Cost-control trigger |
|---|---|---|---:|---|
| Hosting and storage | sessions, assets, retention | [assumption] | [range] | cache/retention/cap review |
| AI inference | feedback calls, tokens, fallback rate | [assumption] | [range] | quota, cheaper path, deterministic fallback |
| Monitoring/security | events, logs, scans, incident support | [assumption] | [range] | sampling without losing incident evidence |
| Content production | scenarios, sourcing, review, translation | [assumption] | [range] | prioritise reusable packs and partner review |
| Research and safeguarding | recruitment, facilitation, accessibility, advice | [assumption] | [range] | never cut required protection to hit growth target |
| Legal/compliance | contracts, privacy, rights | [assumption] | [range] | stage-gated specialist review |
| Design/accessibility | testing, captions, assistive-tech checks | [assumption] | [range] | include in definition of release |
| Partner delivery | training, support, travel/materials | [assumption] | [range] | cohort and self-service limits |
| Contingency | uncertainty and incidents | [%] | [range] | explicit release approval |

## Unit economics worksheet

- Monthly active learners: `M`.
- Sessions per learner: `S`.
- Variable cost per session: `V`.
- Monthly fixed operating cost: `F`.
- Monthly programme/support cost: `P`.
- Estimated monthly cost: `F + P + (M × S × V)`.
- Cost per active learner: `total / M`.
- Cost per completed core loop: `total / completed loops`.

Report AI cost separately so a provider or prompt change cannot hide in aggregate infrastructure spend.

## Funding paths to test

- grants and challenge funding for public-interest validation;
- institutional pilot or facilitator programme fees;
- sponsorship with strict editorial and data independence;
- open educational content plus paid implementation/support;
- research and distribution partnerships.

Do not fund free learner access by selling personal or behavioural data. Do not allow a sponsor to select conclusions or suppress corrections.

## Scenario analysis

For low/base/high cases record user volume, session frequency, inference rate, content-review throughput, partner support load, cash runway, and the action triggered if actual spend exceeds the case for two periods.

## Approval rules

Every material spend or grant commitment records amount/range, source of funds, restrictions, procurement/approval authority, renewal/cancellation date, data/IP implications, and an exit plan.
