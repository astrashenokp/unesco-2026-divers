# gstack-inspired delivery playbook

We adapt the public, MIT-licensed [garrytan/gstack](https://github.com/garrytan/gstack) idea of opinionated role/stage separation. This is a clean project-specific workflow, not a copy of third-party prompts.

## Stages and artifacts

| Stage | Question | Exit artifact |
|---|---|---|
| Think | Is this the right user/problem/outcome? | issue with hypothesis/non-goals |
| Plan | Can four owners build it without interface ambiguity? | acceptance, paths, contracts, risks |
| Build | What is the smallest vertical implementation? | focused PR |
| Review | Is behavior/architecture/safety correct? | review findings/decisions |
| Test | Does evidence cover happy/adversarial/degraded paths? | reproducible report |
| Ship | Can we release/rollback truthfully? | release checklist/digest |
| Reflect | What should system/process learn? | ADR/eval/regression/action |

## Gates

No Build before acceptance/owner; no Ship before Test; no stage agent can approve its own high-risk work alone. Agents suggest; named humans own scope, publication, merge and deploy.

## Tool efficiency

Use concise `rg/tree/git/test failures` output like RTK when useful, but preserve a raw artifact/escape hatch. Do not use pxpipe image compression for contracts, source code, IDs, hashes, security, eval gold data or incident work because silent loss is unacceptable.

## Installation stance

Do not run upstream setup/install/autoupdate as part of this architecture pack. If the team later pilots gstack/RTK/pxpipe, pin a commit/release, review permissions/hooks/telemetry/license, use non-production credentials and record the decision.
