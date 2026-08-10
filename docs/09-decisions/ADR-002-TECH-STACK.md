# ADR-002: Flutter + FastAPI on Google Cloud

Status: Accepted — 2026-08-10

## Decision

Flutter/Dart learner client for mobile/web; Python FastAPI/Pydantic API; Cloud Run; Firebase Auth/App Check; Cloud SQL PostgreSQL; Storage/PubSub/Secret Manager/Cloud Observability.

## Rationale

Matches original product, maximizes client reuse, enables schema-first AI/provider integration, and minimizes operations with managed services.

## Rejected

Node + Python + Java simultaneously; separate React web product for Stitch output; Kubernetes for appearance of scale.

## Consequences

Stitch HTML needs Flutter translation. Provider/model remains behind an interface. Team must manage Cloud SQL connections and Flutter web accessibility/performance explicitly.
