# Product personas and permissions

These are product roles, separate from the four programmer roles.

| Role | MVP | Permissions |
|---|---:|---|
| Guest learner | yes | local/demo missions and ephemeral progress; no private sharing/admin |
| Learner/Investigator | yes | own attempts/progress/receipts/reports; never another learner's data |
| Educator/Facilitator | P1/P2 | assign reviewed packs; see privacy-safe aggregates, not private prompts/history |
| Content Editor | P2 | draft content/source packets; cannot self-publish sensitive case |
| Fact-check Reviewer | seed/admin | review evidence/accepted outcomes/corrections; audited |
| Publisher | P2 | publish reviewed immutable pack with step-up auth; separated where possible |
| Organization Admin | P2 | membership/config/aggregate reports within tenant; no content truth override |
| Security/Moderator | seed/admin | quarantine/report/incident audit by least privilege; no silent edit |
| Research Viewer | P2 | approved anonymized/aggregated study export only |
| MIL Ambassador | P2 | submit drafts/facilitate; publication still reviewed |

## Permission principles

Deny by default; resource/tenant ownership server-side; no role from client claim alone; admin MFA/step-up/audit; teacher access is purpose-bound; no “superadmin” for daily use; learner can export/delete according to policy.

## Accountless and minors

Guest is the safest demo. MVP primary band 16–24; expanding younger requires the child/privacy gates in `docs/04-security/PRIVACY.md` before public launch.
