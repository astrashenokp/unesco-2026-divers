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
| [flutter/samples](https://github.com/flutter/samples) | Flutter org license (BSD-3-Clause-style; verify `LICENSE` before copying) | reference idioms for `PageView`/adaptive layout/implicit animations used in `apps/learner` | vendoring whole sample apps, or treating samples as production-hardened |

## Flutter UI and animation sources

Checked 2026-08-12. These are candidate sources for animation and layout technique in `apps/learner`. Licence governs what may be **copied**; anything may be **read**.

| Repository | Licence | Adopt | Do not do |
|---|---|---|---|
| [lohanidamodar/flutter_ui_challenges](https://github.com/lohanidamodar/flutter_ui_challenges) | MIT | best first stop — broad catalogue of self-contained screens and effects; copy with attribution | assume every sample is null-safe or current |
| [justkawal/UI](https://github.com/justkawal/UI) | MIT | small focused animation samples | treat as a maintained package |
| [HeavenOSK/flutter_swipable_stack](https://github.com/HeavenOSK/flutter_swipable_stack) | MIT | swipe/stack gesture technique if a card deck is ever needed | add as a dependency for a single effect we can hand-roll |
| [cscoderr/flutter_advanced](https://github.com/cscoderr/flutter_advanced) | Apache-2.0 | recent (2026) advanced animation patterns; keep the NOTICE if code is copied | drop the Apache attribution requirement |
| [iampawan/Flutter-UI-Kit](https://github.com/iampawan/Flutter-UI-Kit) | Apache-2.0 | layout ideas | copy verbatim — last touched 2022, predates current APIs |
| [mitesh77/Best-Flutter-UI-Templates](https://github.com/mitesh77/Best-Flutter-UI-Templates) | **MIT + extra clause** | read freely; copy only for this non-commercial hackathon build | treat as clean MIT — see note below |
| [putraxor/flutter-login-ui](https://github.com/putraxor/flutter-login-ui) | **NONE** | look at it and write our own version from scratch | copy any code — see note below |

### Two that need care

**`putraxor/flutter-login-ui` has no licence file at all.** No licence means all rights reserved: reading it is fine, copying any of it is not, regardless of the repository being public. It is also unmaintained since 2021 and predates null safety. Treat it as a screenshot, not as source.

**`mitesh77/Best-Flutter-UI-Templates` is MIT with a clause appended** asking that the software not be used for selling and earning. That extra condition contradicts MIT's unrestricted grant, which is why GitHub reports it as `NOASSERTION` rather than MIT. For a non-commercial hackathon entry the author's intent is clearly satisfied, but it is not clean MIT, and it must not be copied into anything commercial later without asking the author. If Evidence Gym ever monetises, any code traced to this repository has to be removed or relicensed.

### Rule for all of them

Copying is a licensing act, so it needs the same discipline as any dependency: record what was taken and from where in `THIRD_PARTY_NOTICES.md`, preserve the copyright notice, and mark adaptations. Prefer learning the technique and writing our own widget — our components carry semantics, reduced-motion paths and design tokens that none of these samples have, so a verbatim copy usually has to be rewritten anyway.

## Public APIs shortlist policy

Prefer official primary providers already justified in raw research: Crossref/OpenAlex for metadata, Google Fact Check/ClaimReview for discovery, C2PA SDK/spec for provenance. Every adapter needs ToS/license/privacy/quota/SLA/retention/residency/commercial-use review, timeout/cache/circuit/fallback and contract tests.

## Attribution

This documentation summarizes public ideas and links sources. If source code/assets/text are later copied or distributed, create `THIRD_PARTY_NOTICES.md`, preserve required license/notices, mark adaptations and review compatibility/rights per item.
