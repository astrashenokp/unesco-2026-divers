# Dependencies, licenses and external services

## Admission checklist

Need/alternatives; maintained status; license compatibility; provenance; vulnerability history; transitive size; permissions/network/telemetry; data/ToS/privacy; version pin and update/exit plan.

## Rules

- Lock versions; automated upgrade PRs run full tests.
- MIT/Apache/BSD still require notices; CC BY adaptations require attribution/change notice; GPL code is not copied into proprietary/incompatible distribution casually.
- A repository-level license may not grant rights to leaked/third-party content inside it.
- A public API list is discovery only; each provider needs its own due diligence.
- No install script piped from network in CI/prod; verify release/checksum/signature or build reviewed source.
- Keep raw logs/escape hatch when using output compressors.

## Restricted experiments

pxpipe is lossy and unsuitable for code, contracts, IDs/hashes, security or secrets. RTK/gstack hooks are pinned, reviewed and optional; CI security/debug keeps raw output. Collected commercial system prompts are not copied; only clean-room high-level patterns may inform our own short agent files.

Track third-party attribution and decision in `docs/08-research/EXTERNAL_REPOSITORIES.md` and a future `THIRD_PARTY_NOTICES.md` when code is actually vendored/distributed.
