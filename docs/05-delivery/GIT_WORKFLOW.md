# Git workflow without collisions

## Branching

Protected `main`, short-lived branches, merge queue/squash merge. Names: `feat/123-receipt`, `fix/123-idempotency`, `sec/123-ssrf`, `docs/123-architecture`.

## Work slicing

- one issue/DRI/outcome;
- vertical slices preferred;
- shared contract/refactor in a small PR before parallel consumers;
- avoid drive-by formatting/renames in feature PRs;
- announce short path lock when a shared file must change;
- rebase/update before handoff, resolve conflicts with both owners if semantics change.

## Commit/PR

Conventional intent (`feat:`, `fix:`, `docs:`, `test:`, `sec:`, `chore:`). PR template should state why, scope, screenshots, contract/data/security impact, tests and rollback.

## Protection

Required checks; CODEOWNERS; one approval normally, two for contracts/auth/privacy/AI safety/IaC/release; dismissed stale approvals; no direct push/force push; secret protection; signed release tag when available.

## Merge order

1. contract/schema;
2. server backward-compatible support;
3. client/consumer;
4. telemetry/cleanup;
5. remove deprecated behavior after compatibility window.

## Emergency

Hotfix branch, smallest reversible change, security owner + service owner, same tests, deploy progressively, then follow-up review. Never bypass audit and forget to reconstruct it.
