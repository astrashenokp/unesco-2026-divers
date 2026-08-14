# Game and learning design

## Learning backbone

- Lateral reading: leave the claim and inspect who is behind it, what other sources say, and what evidence supports it.
- Inoculation/prebunking: safely expose manipulation techniques before real encounters.
- Retrieval and spacing: resurface a skill after increasing intervals; do not use streaks as the scheduler.
- Metacognition: ask for confidence and what evidence could change the learner's mind.
- Transfer: assess on unseen topics/formats, not memorized cases.

## Mission state machine

`ready → predicted → investigating → concluded → reflected → completed`

Only the server may transition `completed` and award XP. A client retry uses the same idempotency key.

## Process XP rubric

Normative scoring guidance lives in `docs/01-product/RUBRIC_AND_XP_GUIDANCE.md`.
The short ladder below is the P0 shape every mission rubric must follow.

| Level | Evidence behavior | XP guidance |
|---|---|---|
| 0 | instinct only | minimal completion XP |
| 1 | inspected source identity/date | +1 action quality |
| 2 | found primary evidence | +2 |
| 3 | independently corroborated context | +3 |
| 4 | calibrated conclusion and responsible share choice | +4 |

Wrong initial predictions are not punished when the learner investigates well and updates rationally.
`insufficient_evidence` can be the correct conclusion. XP is not a truth,
intelligence, or trustworthiness score, and the AI coach never awards XP.

## Skill map

`source_identity`, `primary_source`, `corroboration`, `context_time_place`, `provenance`, `citation_integrity`, `claim_decomposition`, `uncertainty`, `responsible_sharing`.

## Ethical engagement rules

- No infinite feeds, loot boxes, dark patterns, shame notifications, or public political rankings.
- A streak is optional, non-punitive, and can be paused.
- XP is never evidence that a person is intelligent or trustworthy.
- Notifications default off for minors and avoid urgency manipulation.

## Scenario quality gate

Every mission has a learning objective, gold evidence graph, source snapshot/metadata, jurisdiction/age review, harm note, version, review expiry, accessibility assets, and a second reviewer.
