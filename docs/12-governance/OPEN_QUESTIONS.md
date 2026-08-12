# Open questions register

Resolve these deliberately; do not allow implementation convenience to answer them by accident.

| ID | Question | Why it matters | Needed evidence/input | Decision deadline | Status |
|---|---|---|---|---|---|
| OQ-001 | What exact age range and launch jurisdictions are in scope? | Consent, safeguarding, language, and legal duties differ | target-user research and legal review | before participant recruitment | open |
| OQ-002 | What persists for anonymous use beyond the MVP demo (linking, retention, abuse controls at scale)? | Changes privacy, continuity, and abuse controls | user journey and threat review | before public beta | open — MVP demo mechanism answered by ADR-008 (Firebase Anonymous Auth, ephemeral pseudonymous state, no separate auth path) |
| OQ-003 | Which languages are launch-critical? | Affects content review, accessibility, and moderation capacity | partner and audience evidence | before content freeze | open |
| OQ-004 | What content categories are prohibited or supervised-only? | Prevents harmful amplification | safeguarding and editorial review | before scenario publication | open |
| OQ-005 | What proves immediate learning and transfer? | Prevents impact overclaiming | pilot methodology review | before impact claims | open |
| OQ-006 | Which data can be collected from minors, if any? | High privacy and trust risk | legal/safeguarding necessity assessment | before collection | open |
| OQ-007 | What is the final repository/content license? | Controls contribution and reuse | rights inventory and owner decision | before public release | open |
| OQ-008 | Which third-party AI/design services may receive project data? | Vendor privacy and confidentiality | ToS/DPA/data-flow review | before real data is sent | open |
| OQ-009 | Who can approve, correct, withdraw, and translate scenarios? | Editorial accountability | governance and partner agreement | before contributor intake | open |
| OQ-010 | What is the sustainable funding model? | Determines access and incentives | budget and partner discovery | before scale commitment | open |
| OQ-011 | What is the support and incident response promise? | Sets operational expectation | capacity and risk review | before public launch | open |
| OQ-012 | What evidence can be shared publicly from pilots? | Consent and re-identification risk | consent scope and disclosure review | before publication | open |
| OQ-013 | Do we build an under-16 mode, and if so what gates come first? | `PERSONAS_AND_PERMISSIONS.md` sets the band at 16–24 and requires the child/privacy gates in `PRIVACY.md` before going younger. Building the UI first would route minors through a product whose safeguarding is unfinished | legal/safeguarding necessity assessment, DPIA, consent model for minors | before any under-16 UI is written | open — raised by Role 1, 2026-08-12 |
| OQ-014 | Which additional task formats enter scope, and what P0 work is dropped to pay for them? | Boosters, transfer tests and peer challenges are P1/P2 in `MVP_SCOPE.md`; adding them without removing equivalent effort is how a hackathon deadline is missed | named owner, acceptance criteria, the P0 item being traded away, security/privacy note | before implementation starts | open — raised by Role 1, 2026-08-12 |

## Closure rule

An item is closed only when its decision ID, date, rationale, evidence, constraints, and re-open trigger are recorded in the decision log or an ADR.
