# Documentation map

This index is the stable entry point. Raw research is preserved, but implementation decisions live in the numbered folders.

| Need | Read first | Then |
|---|---|---|
| Understand the product | [Concept](01-product/CONCEPT.md) | [PRD](01-product/PRD.md), [MVP](01-product/MVP_SCOPE.md) |
| Build a screen | [User journeys](01-product/USER_JOURNEYS.md) | [Design system](06-design/DESIGN_SYSTEM.md), [API contract](03-contracts/API_CONTRACT.md) |
| Build backend/AI | [Architecture](02-architecture/ARCHITECTURE.md) | [Domain](02-architecture/DOMAIN_MODEL.md), [AI pipeline](02-architecture/AI_PIPELINE.md) |
| Change an interface | [Contracts](03-contracts/README.md) | `contracts/openapi.yaml`, schemas, event catalog |
| Ship safely | [Security](04-security/README.md) | [Testing](05-delivery/TEST_STRATEGY.md), [release](05-delivery/RELEASE_RUNBOOK.md) |
| Know your ownership | [Team of four](07-agents/TEAM_OF_FOUR.md) | your role prompt, handoff protocol |
| Prepare submission | [Win plan](01-product/HACKATHON_WIN_PLAN.md) | [demo and pitch](01-product/PITCH_DEMO.md) |
| Build from zero to scale | [Execution playbook](05-delivery/PROJECT_EXECUTION_PLAYBOOK.md) | [epics](05-delivery/BACKLOG_EPICS.md), [master acceptance](05-delivery/MASTER_ACCEPTANCE_CHECKLIST.md) |
| Use Google Stitch | [Stitch workflow](06-design/STITCH_WORKFLOW.md) | [prompt pack](06-design/STITCH_PROMPTS.md), [MCP setup](07-agents/MCP_STITCH_SETUP.md) |

## Folder contract

- `00-source`: immutable source material, renamed and preserved.
- `01-product`: why/what and scope.
- `02-architecture`: how the system is shaped.
- `03-contracts`: interfaces and team promises.
- `04-security`: security, privacy, safety, moderation.
- `05-delivery`: Git, CI/CD, tests, observability, releases.
- `06-design`: visual/accessibility source of truth and Stitch workflow.
- `07-agents`: four role agents plus QA automation.
- `08-research`: synthesis and reuse policy.
- `09-decisions`: architecture decision records.

Generated artifacts never outrank reviewed contracts.
