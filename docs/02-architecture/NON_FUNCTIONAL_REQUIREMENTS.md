# Non-functional requirements

| Area | MVP SLO/constraint | Verification |
|---|---|---|
| Availability | 99.5% API monthly; deterministic demo offline | synthetic check + demo rehearsal |
| Latency | p95 core API <500 ms; hint <4 s or progressive fallback | trace dashboard/load test |
| Correctness | no duplicate completion/XP under retries | idempotency/property tests |
| Durability | RPO ≤24 h MVP, RTO ≤4 h; tighter after pilot | restore drill |
| Security | no open critical/high release findings | SAST/SCA/DAST/manual gates |
| Privacy | data minimization and purpose-bound events | data inventory review |
| Accessibility | WCAG 2.2 AA target, keyboard/screen reader/captions | automated + manual checks |
| Localization | English/Ukrainian; no P0 hard-coded strings | l10n lint/pseudo-locale |
| Scalability | stateless API; load test 100 concurrent demo users | staged load test |
| Observability | trace ID on API, worker, provider calls; SLO alerts | runbook drill |
| Cost | hard LLM/Cloud caps and budget alerts | daily dashboard/alerts |
| Portability | provider adapters; scenario packs are open documented schema | contract tests |

SLOs are initial targets, not achieved claims, until dashboards contain representative measurements.
