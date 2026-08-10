# Ownership matrix

Human names/GitHub handles should replace `Person A–D` once agreed. The planned workload split is balanced: A 25%, B 25%, C 25%, D 25%.

| Area | A Frontend | B Backend/Domain | C AI/Learning | D Game/Data/Security |
|---|---:|---:|---:|---:|
| Flutter/Web shell, design, accessibility | A/R | C | C | C |
| API controllers, use cases and domain rules | C | A/R | C | C |
| PostgreSQL/Redis, migrations, indexes, backup | I | R | I | A/R |
| GCP runtime, IaC and platform operations | I | C | I | A/R |
| mission/content model and learning rubric | C | C | A/R | C |
| prompts, AI/retrieval adapters and evals | I | C | A/R | C |
| gameplay, XP, streak, quests and progression | R | R | C | A/R |
| non-AI integrations, webhooks, flags and experiments | C | A/R | C | R |
| client security/privacy remediation | A/R | C | C | C |
| API/domain security remediation | C | A/R | C | C |
| AI/content-safety remediation | C | C | A/R | C |
| platform/data/IAM/supply-chain security | C | C | C | A/R |
| CI/CD, observability, load and release automation | C | R | C | A/R |
| OpenAPI/scenario contract | R | A | R | C |
| pitch/demo vertical integration | R | R | R | A/R |
| submission scope/product story | R | R | R | R |

Legend: `A` accountable, `R` responsible, `C` consulted, `I` informed.

## Path boundaries

- A: `apps/learner`, `packages/design_system`, `docs/06-design`.
- B: `services/api` controllers/use cases/domain, repository interfaces, non-AI integration adapters and API runtime behavior.
- C: `packages/verification`, `content`, `evals`, AI policy versions and AI/retrieval adapters.
- D: `packages/gameplay`, `packages/data_access`, DB migrations, `infra`, runtime reliability tooling, `.github/workflows`, platform/data security controls and release evidence.
- Shared contract paths require cross-owner review and small dedicated PRs.

## Security and QA routing

Evidence Guardian audits all four areas but is not a human role and does not own remediation. A fixes frontend findings, B API/domain/application-integration findings, C AI/content findings, and D platform/data/infrastructure/pipeline findings. D maintains automated gates and assists when a control crosses boundaries.

## Backend/data rule

B defines domain invariants, transaction intent and repository behavior. D owns physical schema, migrations, constraints, indexes, caching and recovery. Both must review compatibility, concurrency and rollback for a data change.

## Integration rule

No two people refactor the same shared module in parallel. Announce a short integration lock in the issue, merge the contract/refactor first, then rebase feature branches.
