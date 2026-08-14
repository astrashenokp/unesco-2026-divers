# Rubric and XP guidance

XP rewards the investigation process, not guessing, truth detection, or learner
intelligence. The reviewed mission rubric explains what quality of work the
learner practised; server-side gameplay awards the deterministic amount from
that version-pinned rubric.

## Non-negotiable principles

- A wrong initial prediction is not punished when the learner investigates well,
  updates confidence rationally, and communicates uncertainty responsibly.
- `insufficient_evidence` can be the correct conclusion when the available
  evidence does not support a stronger label.
- XP is not a truth score, intelligence score, trustworthiness score, or
  personality signal.
- The AI coach never awards XP, mutates scoring state, or decides whether a
  learner was correct. It may only explain the reviewed rubric after completion.
- More clicks must not pay unbounded XP. P0 process level is capped at level 4.

## P0 process levels

| Level | Process quality | XP guidance |
|---|---|---|
| 0 | Instinct only: the learner concludes from fluency, appearance, or prior belief without using evidence. | Minimal completion XP. |
| 1 | Source or provenance check: the learner inspects who is behind the item, where it came from, or whether the first source is known. | Low XP for starting the verification loop. |
| 2 | Primary or direct evidence check: the learner finds a source record, registry result, original context, date/place signal, or claim decomposition that narrows the question. | Moderate XP for moving beyond surface cues. |
| 3 | Corroborated and qualified investigation: the learner compares independent evidence, handles conflicts, and avoids overclaiming from a limited lookup. | High XP for evidence quality and uncertainty handling. |
| 4 | Calibrated conclusion and responsible sharing: the learner separates the three axes, updates confidence, accepts `insufficient_evidence` when warranted, and chooses a share decision that does not amplify unsupported claims. | Top P0 XP, capped. |

The runtime P0 scoring signal is intentionally simple: process level is derived
from completed evidence-action count and capped at 4, while qualitative guidance
lives in curated `rubric.processLevels`, `skillTags`, `confidenceCalibration`,
and `evalHooks`. A future semantic action-quality scorer is a contract change;
it must remain server-side, deterministic/reviewable, and independent of the AI
coach.

## Skill tags

- `source_identity`: who published, reposted, registered, or is accountable for
  the evidence.
- `primary_source`: a direct source, source packet, registry record, original
  context, or closest available primary reference.
- `corroboration`: comparison against independent evidence or the absence of
  expected supporting records.
- `context_time_place`: date, location, event context, or stale/out-of-context
  reuse.
- `provenance`: lineage of media, citation, screenshot, metadata, or repost
  chain.
- `citation_integrity`: whether citation parts, DOI-like strings, registry
  metadata, and cited claims align.
- `claim_decomposition`: separating citation existence, claim support, media
  authenticity, context integrity, and other subclaims.
- `uncertainty`: naming limits, conflicts, provider gaps, and confidence ranges
  without collapsing them into a binary verdict.
- `responsible_sharing`: deciding whether and how to share, correct, or withhold
  amplification based on evidence limits.

## Action quality

Quality is not raw volume. A good action sequence:

- starts with source/provenance rather than visual or fluent-content trust;
- uses direct or primary evidence when available;
- corroborates context instead of treating one source as universal proof;
- separates media authenticity, claim veracity, and context integrity;
- cites only evidence IDs that exist in the mission result set;
- names limitations and missing evidence.

Low-quality action use includes clicking many redundant actions, treating
`not_found` as fabrication, treating fluent citation formatting as support,
ignoring conflicts, or using evidence from one axis to score another.

## Confidence calibration

The learner should be rewarded for justified movement, not for being maximally
confident. Good calibration includes lowering confidence when evidence is weak,
raising confidence when independent evidence aligns, and keeping confidence
moderate when there are missing records or conflicts. A confidence change without
a cited evidence reason is not high-quality investigation.

## Responsible sharing

The share decision is part of the learning outcome. A high-quality conclusion
can be `do_not_share`, `share_with_context`, or `continue_investigating`,
depending on evidence limits. The product must not reward viral amplification,
panic, dunking, or certainty theatre.

## Uncertainty handling

`insufficient_evidence` is an evidence-grounded outcome, not a failure state.
Learners should distinguish:

- not found in queried sources;
- unavailable provider or malformed response;
- conflicting evidence;
- evidence that supports one axis but not another;
- source/citation existence versus support for the cited claim.

When uncertainty remains, the correct behaviour is to name what is known, what is
not known, and what evidence would change the conclusion.
