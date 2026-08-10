# Local corpus audit

## Inventory before restructuring

| Original | Approx. role | Quality note |
|---|---|---|
| `a.md` | 110-line product seed | highest-priority intent; concise but architecture ambiguous |
| `UNESCO.md` | 1,325-line hackathon/winner research | useful, repeated sections and some unsupported inference |
| `UNESCO_MIL_Hackathon_2026_Research_Dossier.md` | 5,984-line master dossier | strongest synthesis/source library; intentionally broad, not architecture |
| `Приклади наукових робіт на тематику нашої ідеї.md` | 1,574-line prior-art notes | mojibake, duplicated AI material, unverified numbers/snippets |
| `README.md` | one-line repository name | replaced with project entry point |

## Canonicalization

Raw files are preserved under `docs/00-source/` with descriptive ASCII names. They are evidence/backlog, not implementation source of truth. This numbered documentation pack resolves their conflicts explicitly.

## Main resolved conflicts

- `Trust/Suspicious/Investigate` is the initial prediction, not final binary verdict.
- One FastAPI backend replaces Node/FastAPI/Java ambiguity.
- Flutter mobile/web is primary; Stitch design artifacts are translated, not a parallel React product.
- MVP target is 16–24; younger/classroom/organization needs remain later gates.
- Curated/versioned cases and deterministic fallback precede open-web verification.
- LLM coaches; deterministic reviewed data/scoring owns conclusions.
- Two excellent demo cases replace a giant feature platform during submission week.

## Known encoding issue

The scientific/prior-art file displays mojibake and appears recoverable by interpreting bytes through Windows-1251/UTF-8. It is preserved as-is to avoid silent alteration; use the reviewed synthesis/claim register instead.
