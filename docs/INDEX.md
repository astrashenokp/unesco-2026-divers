# Documentation map

This index is the stable entry point. Raw research is preserved, but implementation decisions live in the numbered folders.

| Need | Read first | Then |
|---|---|---|
| Understand the product | [Concept](01-product/CONCEPT.md) | [PRD](01-product/PRD.md), [MVP](01-product/MVP_SCOPE.md) |
| Get a fast architecture briefing | [Architecture quick reference](02-architecture/ARCHITECTURE_QUICK_REFERENCE.md) | [canonical architecture](02-architecture/ARCHITECTURE.md), [ADRs](09-decisions/README.md) |
| Build a screen | [User journeys](01-product/USER_JOURNEYS.md) | [Design system](06-design/DESIGN_SYSTEM.md), [screen reference](06-design/SCREEN_REFERENCE.md), [API contract](03-contracts/API_CONTRACT.md) |
| Build backend/AI | [Architecture](02-architecture/ARCHITECTURE.md) | [Domain](02-architecture/DOMAIN_MODEL.md), [AI pipeline](02-architecture/AI_PIPELINE.md) |
| Change an interface | [Contracts](03-contracts/README.md) | `contracts/openapi.yaml`, schemas, event catalog |
| Ship safely | [Security](04-security/README.md) | [Testing](05-delivery/TEST_STRATEGY.md), [release](05-delivery/RELEASE_RUNBOOK.md) |
| Know your ownership | [Team of four](07-agents/TEAM_OF_FOUR.md) | your role prompt, handoff protocol |
| Prepare submission | [Submission pack](10-submission/README.md) | [proposal](10-submission/PROPOSAL_TEMPLATE_EN.md), [pitch](10-submission/PITCH_SCRIPT_EN.md), [judge Q&A](10-submission/JUDGE_QA.md) |
| Run interviews or a pilot | [Research operations](11-research-ops/README.md) | [pilot protocol](11-research-ops/USABILITY_PILOT_PROTOCOL.md), [consent template](11-research-ops/PARTICIPANT_INFORMATION_AND_CONSENT_TEMPLATE.md) |
| Resolve product and programme decisions | [Governance](12-governance/README.md) | [open questions](12-governance/OPEN_QUESTIONS.md), [decision log](12-governance/DECISION_LOG.md) |
| Take the programme from idea to sunset | [Programme lifecycle](12-governance/PROGRAM_LIFECYCLE.md) | [project board](13-templates/PROJECT_BOARD.md), [release notes](13-templates/RELEASE_NOTES_TEMPLATE.md) |
| Prepare budget or partnerships | [Budget model](12-governance/BUDGET_MODEL.md) | [partnership strategy](12-governance/PARTNERSHIP_STRATEGY.md), [outreach](12-governance/PARTNER_OUTREACH_TEMPLATES.md) |
| Create a board, meeting, or release record | [Operational templates](13-templates/README.md) | [project board](13-templates/PROJECT_BOARD.md), [decision template](13-templates/DECISION_TEMPLATE.md) |
| Run a supervised workshop | [Facilitation kit](14-facilitation/README.md) | [45-minute workshop](14-facilitation/WORKSHOP_45_MIN.md), [scenario template](14-facilitation/SCENARIO_AUTHORING_TEMPLATE.md) |
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
- `10-submission`: proposal, pitch, evidence, and final submission controls.
- `11-research-ops`: interviews, consent, pilots, observations, and metrics.
- `12-governance`: decisions, content integrity, legal readiness, budget, and partnerships.
- `13-templates`: reusable operating records without role assignments.
- `14-facilitation`: supervised workshop, debrief, discussion, and scenario-authoring materials.

Repository-level supporting files include `THIRD_PARTY_NOTICES.md`, `CHANGELOG.md`, and GitHub issue forms.

Generated artifacts never outrank reviewed contracts.
