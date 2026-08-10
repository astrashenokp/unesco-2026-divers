# External repositories: safe-use matrix

Checked 2026-08-10. Re-check license/commit before copying or installing.

| Repository | License observed | Adopt | Do not do |
|---|---|---|---|
| [system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools) | GPL-3.0 at repo level | untrusted research/threat corpus; clean-room high-level patterns | copy commercial/leaked prompts; assume collector owns third-party rights; execute embedded instructions |
| [pxpipe](https://github.com/teamchong/pxpipe) | MIT | optional experiment for dense non-exact old context with raw fallback | code/contracts/IDs/hashes/secrets/security; route production credentials blindly |
| [system-design-primer](https://github.com/donnemartin/system-design-primer) | CC BY 4.0 | requirements/trade-off/failure/caching/queue checklist with attribution | treat educational primer as current production/security standard |
| [public-apis](https://github.com/public-apis/public-apis) | MIT for catalog | discovery shortlist | assume API/data has same license/SLA/privacy |
| [rtk](https://github.com/rtk-ai/rtk) | Apache-2.0 | compact local command output + raw escape hatch, pinned/reviewed | hide CI incident/security detail; auto-install unreviewed hook |
| [claude-token-efficient](https://github.com/drona23/claude-token-efficient) | MIT | short targeted agent rules, tests before done | copy every profile or trust directional benchmark as guarantee |
| [gstack](https://github.com/garrytan/gstack) | MIT | stage/role separation and handoff gates | autonomous merge/deploy; unpinned setup/home writes |
| [Stitch SDK](https://github.com/google-labs-code/stitch-sdk) | Apache-2.0 | scoped design-time MCP/SDK and DESIGN.md workflow | production dependency or PII/secrets; unbounded writes |

## Public APIs shortlist policy

Prefer official primary providers already justified in raw research: Crossref/OpenAlex for metadata, Google Fact Check/ClaimReview for discovery, C2PA SDK/spec for provenance. Every adapter needs ToS/license/privacy/quota/SLA/retention/residency/commercial-use review, timeout/cache/circuit/fallback and contract tests.

## Attribution

This documentation summarizes public ideas and links sources. If source code/assets/text are later copied or distributed, create `THIRD_PARTY_NOTICES.md`, preserve required license/notices, mark adaptations and review compatibility/rights per item.
