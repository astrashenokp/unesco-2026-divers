# Observability and SLOs

## Signals

| Journey | Metric | Alert/diagnostic |
|---|---|---|
| start mission | success/latency | catalog/cache/auth failures |
| evidence action | success by adapter, timeout, cache hit | provider circuit/egress/quota |
| coach hint | latency, fallback, policy rejection, cost | model/provider/prompt version |
| completion | success, conflict, duplicate prevented | DB lock/migration/idempotency |
| pack publish | validation/review/hash | audit and cache propagation |

## Structured context

`trace_id`, service/module, route/action, status/error code, duration, environment, build digest, pack/mission version, provider/model/policy version and pseudonymous subject only when required. Never raw prompt/evidence/upload/token/email.

## SLO practice

Define indicator, target and window; alert on burn rate, not every isolated error. Initial targets are in non-functional requirements and become claims only after representative measurement.

## Dashboards

Demo health; API/DB; provider/LLM; learning funnel; AI safety/eval; security/abuse; cost/quota; content freshness/expiry.

## Trace propagation

W3C trace context from edge/client request through API, outbox event and worker/provider call. Correlation ID is exposed in safe errors for support.
