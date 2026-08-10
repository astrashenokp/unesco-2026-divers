# Ownership matrix

Human names/GitHub handles should replace `Person A–D` once agreed.

| Area | A Frontend | B Platform | C AI/Learning | D Security/Quality |
|---|---:|---:|---:|---:|
| Flutter shell/design/accessibility | A/R | C | C | C |
| API/domain/Postgres | C | A/R | C | C |
| GCP runtime/IaC | I | R | I | A |
| mission/content model | C | C | A/R | C |
| prompts/provider adapters/evals | I | C | A/R | C |
| security/privacy/moderation | C | C | C | A/R |
| CI/CD/test strategy/observability | C | R | C | A/R |
| OpenAPI/scenario contract | R | A | R | C |
| pitch demo integration | A | R | R | R |
| submission scope/product story | R | R | R | A (coordination) |

Legend: `A` accountable, `R` responsible, `C` consulted, `I` informed.

## Path boundaries

- A: `apps/learner`, `packages/design_system`, `docs/06-design`.
- B: `services/api`, `infra`, DB migrations, API runtime.
- C: `packages/verification`, `content`, `evals`, AI policy versions.
- D: `.github/workflows`, security tooling/docs, release evidence, QA bot.
- Shared contract paths require cross-owner review and small dedicated PRs.

## Integration rule

No two people refactor the same shared module in parallel. Announce a short integration lock in the issue, merge the contract/refactor first, then rebase feature branches.
