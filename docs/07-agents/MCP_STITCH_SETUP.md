# Google Stitch MCP setup for the QA bot

## Architecture

`Evidence Guardian → local allowlist proxy/adaptor → https://stitch.googleapis.com/mcp`

The adaptor exposes only approved read tools and validates project/screen IDs, response size, timeout and audit metadata. It prevents a compromised prompt/tool description from broadening authority.

## Credentials

Use `STITCH_API_KEY` for a personal prototype or OAuth/access token + `GOOGLE_CLOUD_PROJECT` according to current official setup. Store in local environment/secret manager, never `.md`, app bundle, logs or Git. Rotate on exposure. The checked-in example is `config/mcp/stitch.qa-bot.example.json` and contains placeholders only.

## Allowlist

Default: list/get projects/screens, fetch screen image/HTML, extract design context. Optional human-approved: generate screen/variant in a sandbox project. Deny: delete, publish, share, organization/admin changes, arbitrary URL fetch and deployment.

## QA invocation

Provide approved `projectId`, `screenIds`, viewport and local/staging target. The bot reads screenshots/context, captures implementation, checks semantic token/component intent and accessibility, and writes a local redacted report. Human decides fixes.

## Data policy

Only synthetic/approved hackathon designs. No learner PII, private Drive content, production URLs/tokens, unpublished sensitive source material or copyrighted media without permission.

## Verification

Before use: inspect current tool list/descriptions; confirm allowlist; run with fake project/invalid ID; verify denied write; ensure secrets do not appear in logs; cap time/calls/cost; test revocation/offline behavior.

Primary references: [Stitch SDK](https://github.com/google-labs-code/stitch-sdk), [official Google codelab](https://codelabs.developers.google.com/design-to-code-with-antigravity-stitch), and [Google Labs overview](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-ai-ui-design/).
