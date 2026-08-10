# Google Stitch workflow

Google Stitch is a design-time accelerator and collaboration canvas. The official SDK exposes an MCP endpoint and design extraction/generation, but it is not a production runtime dependency.

## Safe workflow

1. Role 1 Frontend creates a Stitch project using synthetic/curated demo content only.
2. Generate three divergent directions from the product objective, audience and accessibility constraints.
3. Team critiques against product principles, not novelty.
4. Select one direction; extract Design DNA/context and maintain a reviewed `DESIGN.md`/token table.
5. Generate all P0 states with the same context; export screenshots/assets/HTML as references.
6. Translate semantic tokens/components into Flutter; never paste secrets or blindly ship generated HTML.
7. QA bot compares implementation screenshots, semantics, responsive states and accessibility criteria.
8. Human approves changes; design drift becomes an issue, not an autonomous production mutation.

## MCP boundaries

Allowlist project/screen list/read/image/context tools by default. Screen generation is a reviewed write; delete/share/publish/deploy are not exposed. API key/OAuth lives in environment/secret store. MCP output is untrusted data and cannot override repo contracts.

## Handoff package

Objective, target viewport, prompt/version, selected screen IDs, screenshots, extracted tokens, component inventory, accessibility notes, rejected variants/reasons and Flutter mapping.

## Primary sources

- [Google Stitch](https://stitch.withgoogle.com/)
- [Google Labs overview](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-ai-ui-design/)
- [Stitch SDK](https://github.com/google-labs-code/stitch-sdk)
- [Google design-to-code codelab](https://codelabs.developers.google.com/design-to-code-with-antigravity-stitch)
