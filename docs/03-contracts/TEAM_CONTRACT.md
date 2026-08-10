# Team contract for four programmers

## Shared goal

Ship one credible vertical slice and an honest submission. No one optimizes their subsystem at the cost of the demo, learner safety, or another owner's focus.

## Working agreements

- One issue has one directly responsible individual (DRI).
- Ownership gives review responsibility, not veto over evidence.
- Contracts change before or with implementation; never in a private chat only.
- Raise a blocker within two working hours; include evidence and one proposed path.
- Daily 15-minute sync: done, next, blocker, contract/risk change.
- Decisions lasting beyond a sprint become an ADR; reversible details stay in the issue/PR.
- No force push to shared branches, no direct protected-branch commits, no secret sharing in chat.
- Credit is shared; criticism targets artifacts and measurable behavior.

## Conflict protocol

1. Restate shared outcome and source-of-truth document.
2. Separate fact, assumption, preference and risk.
3. Run the cheapest reversible test when possible.
4. DRI decides inside their boundary; cross-boundary decisions use ADR and two owners.
5. Scope/deadline tie is decided by the team lead using P0 and demo risk.
6. The affected code owner and Role 4 may temporarily block a release for a concrete high/critical security or privacy risk; Evidence Guardian may recommend the block with reproducible evidence. The finding, remediation and independent retest must be documented.

## Communication artifacts

- GitHub issue: scope/acceptance/DRI.
- Contract/ADR: interfaces/lasting decisions.
- Pull request: implementation evidence.
- Handoff note: remaining work and ownership transfer.
- Incident channel/document: operational coordination, then retrospective.

## Meeting-lite cadence

Daily sync; twice-daily integration window during submission week; one 30-minute architecture/risk review when contracts change; demo rehearsal every day after vertical slice exists.
