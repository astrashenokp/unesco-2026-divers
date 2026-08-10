# Agent and human handoff protocol

Copy this compact template into issue/PR/task output.

```markdown
## Goal / status
Done | partial | blocked — one sentence.

## Changed
- paths and behavior

## Contracts and decisions
- API/event/schema/ADR impact; versions

## Safety and data
- auth/privacy/content/AI/accessibility impact

## Verification
- exact tests/checks and results; artifact links

## Risks / assumptions
- evidence, not vague warnings

## Next
- one action, owner, acceptance condition
```

## Rules

No “done” without test evidence. No hidden local state, private chat decision or undocumented schema. If blocked, state what was tried and the smallest missing decision/access. Exact IDs/hashes/contracts remain text; do not hand them off via lossy screenshot/context compression.

Security/QA findings route to the owner of the affected code: Role 1 frontend, Role 2 API/domain, Role 3 AI/content, Role 4 gameplay/data/infrastructure/integrations. Evidence Guardian verifies independently; it does not absorb implementation responsibility. Database handoffs state both domain invariant/transaction intent and physical migration/recovery evidence.
