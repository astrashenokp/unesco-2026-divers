# Third-party references and notices

This repository currently documents external research and architectural inspiration. Listing a project here does not mean its source code, prompts, assets, trademarks, or datasets are bundled, endorsed, or relicensed by Evidence Gym.

## Referenced repositories

| Project | Repository | Upstream license observed | Use in this repository |
|---|---|---|---|
| gstack | https://github.com/garrytan/gstack | MIT | workflow and separation-of-concerns research |
| system-prompts-and-models-of-ai-tools | https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools | GPL-3.0 at repository level; underlying collected material may have separate rights | untrusted research corpus only; no verbatim prompts intentionally incorporated |
| pxpipe | https://github.com/teamchong/pxpipe | MIT | research into lossy context compression trade-offs |
| system-design-primer | https://github.com/donnemartin/system-design-primer | CC BY 4.0 | system-design checklist inspiration; adapted concepts are independently written |
| public-apis | https://github.com/public-apis/public-apis | MIT for the catalogue | API discovery research; each listed API requires separate terms review |
| rtk | https://github.com/rtk-ai/rtk | Apache-2.0 | compact tool-output pattern research |
| claude-token-efficient | https://github.com/drona23/claude-token-efficient | MIT | concise instruction-pattern research |
| Stitch SDK | https://github.com/google-labs-code/stitch-sdk | Apache-2.0 | documented optional Google Stitch integration research |

For exact links, limitations, provenance, and safe-use decisions, see [External repositories](docs/08-research/EXTERNAL_REPOSITORIES.md).

## Distribution gate

Before distributing any third-party code or asset:

1. pin the exact version/commit;
2. verify the license at that version and the contributor’s authority where material is aggregated;
3. preserve required copyright, license, NOTICE, attribution, and modification statements;
4. scan transitive dependencies and assets separately;
5. verify trademark, terms-of-service, data, and privacy rights independently;
6. record the decision and evidence here.

This file is not a substitute for the full license texts of components that may later be distributed.
