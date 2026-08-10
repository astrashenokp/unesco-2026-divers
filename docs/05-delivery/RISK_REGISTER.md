# Risk register

| Risk | L/I | Mitigation | Owner/trigger |
|---|---|---|---|
| P0 scope sprawl | H/H | freeze MVP; swap scope only | lead / any P1 started early |
| AI latency/hallucination | H/H | bounded data, eval, fallback | AI / gate failure |
| third-party API outage/quota | H/M | adapter/cache/fixture/circuit | platform / health drop |
| harmful/incorrect case | M/H | review/version/report/quarantine | quality / report |
| demo network/device failure | M/H | offline bundle + recording | frontend / rehearsal |
| secret/PII leak | M/H | OIDC, scan, redaction, rotation | affected code owner + Role 4 / alert |
| copyright issue | M/H | license inventory/replacement | content / missing license |
| weak differentiation | M/H | 3-axis/process/calibration/citation demo | all / user cannot restate |
| architecture overbuild | H/M | modular monolith/extraction triggers | platform / infra > slice |
| merge conflicts | H/M | path owners, contract-first, small PR | all / shared edit |
| unsupported impact claim | M/H | claim register/source tiers | research / proposal review |
| accessibility/inclusion gap | M/H | P0 criteria + manual audit | frontend/quality |
| cost shock | M/M | limits/budgets/cache/fallback | platform / alert |
| team illness/time | M/H | bus-factor handoffs, shared demo knowledge | all |

`L/I` = likelihood/impact. Review twice daily in submission week; closed risks retain decision evidence.
