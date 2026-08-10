# Google technology stack

## Selected stack

| Layer | Technology | Why |
|---|---|---|
| Client | Flutter/Dart for Android, iOS-ready, and web | one four-person codebase; original concept fit |
| State/navigation | Riverpod + typed routing | testable feature boundaries |
| Identity | Firebase Authentication | fast guest/federated auth; server verifies tokens |
| Client attestation | Firebase App Check | abuse signal, not an authorization substitute |
| API | Python FastAPI + Pydantic | schema-first contracts and AI/data ecosystem |
| Runtime | Cloud Run | managed autoscaling, per-service identity, fast deploy |
| Relational data | Cloud SQL PostgreSQL | transactions, versioning, audit, rich relations |
| Media/packs | Cloud Storage + CDN | immutable objects and offline bundles |
| Async | Pub/Sub + Cloud Run worker/jobs | outbox delivery, retries, isolation |
| Secrets | Secret Manager + Workload Identity | no long-lived keys in code/images |
| Edge | External HTTPS LB + Cloud Armor | WAF/rate limiting; block direct Cloud Run URL |
| Observability | Cloud Logging/Monitoring/Trace + OpenTelemetry | end-to-end correlation |
| Config/flags | Firebase Remote Config initially | kill switches and bounded experiments |
| AI | provider-agnostic gateway; Vertex AI/Gemini is an option | avoid hard lock-in and preserve fallback |
| Design | Google Stitch + reviewed DESIGN.md/tokens | rapid visual exploration; not runtime dependency |

## Environments and IAM

Use separate GCP projects. Each Cloud Run service has one least-privilege service account. Developers authenticate personally; production changes go through CI workload identity. No owner/editor primitive roles, shared service-account keys, or secrets in Firebase/Remote Config.

## Network/security baseline

- Cloud Run ingress `internal-and-cloud-load-balancing`; disable default URL where supported.
- Cloud Armor WAF, rate limits and bot rules; API still validates/authenticates every request.
- Private IP/connector path to Cloud SQL; TLS and IAM database authentication where viable.
- Egress allowlist/proxy for verification providers; defend URL fetch from SSRF.
- CMEK only if risk/legal needs justify operational cost; default Google-managed encryption is acceptable for MVP.

## Cost controls

Budgets/alerts per environment; max instances; query and LLM cost caps; lifecycle/delete temporary uploads; sampled non-error traces; cache provider metadata; label resources by service/environment/owner.

## Stitch boundary

Stitch MCP/SDK is a design-time tool. It never receives learner PII or production secrets, and product availability does not depend on it. Approved design tokens and screenshots are committed; generated HTML is a reference because production UI is Flutter.
