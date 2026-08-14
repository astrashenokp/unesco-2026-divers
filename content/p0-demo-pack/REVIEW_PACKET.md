# P0 demo pack review packet

Status: review-stage submission demo, not public publication approval.

Review owner lane: Evidence Guardian. The lane is recorded here, not in
`review.reviewerIds`, because `reviewerIds` is reserved for actual human
sign-off. This packet exists so the team can review the same concrete evidence,
limitations and test artifacts before submission. Do not change pack or mission
status to `approved` or `restricted` until a human reviewer records sign-off with
`reviewedAt`.

## Scope

- Pack: `p0-demo-pack` version `0.1.0`.
- Missions: `authentic-media-wrong-context`, `ai-citation-integrity`.
- Canonical pack locale: English mission prose. Ukrainian UI/demo strings are
  present as review stubs but are not claimed as reviewed mission localization.
- Intended use: deterministic hackathon/submission demo and local integration.
- Not intended use: public content publication, live emergency verification, or
  a claim that model safety has been broadly proven.

## Checks Required Before Public Publication

- Fact/content: source titles, source dates, source limits and claim wording.
- License: USGS public-domain status and attribution; team-created citation
  fixture status.
- Accessibility: media alt text, text-only completion path, warning language.
- AI safety: no gold leakage, binary-oracle verdict, invented evidence, prompt
  injection compliance or `not_found` as fabrication.
- Demo integrity: Flutter demo path and API demo path show the same P0 mission
  set, IDs, action labels and minimum evidence policy.

## Current Review Result

- Schema/hash validation: ready for review.
- Deterministic evidence path: ready for review.
- Coach eval gate: deterministic fixture preflight artifact present.
- Human publication approval: pending.

## Remaining Sign-Off Fields

When a human reviewer approves public publication, update each reviewed manifest
or mission from `review` to `approved` or `restricted`, add `reviewedAt`, retain
the reviewer ID, and keep this packet with the submitted snapshot.
