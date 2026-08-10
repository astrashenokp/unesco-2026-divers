# ADR-001: Modular monolith first

Status: Accepted — 2026-08-10

## Context

Four programmers and a six-day submission window need one vertical slice, while the long-term concept contains many domains.

## Decision

One FastAPI deployable with strict domain modules, Postgres transactions, outbox and separate async worker. No Kubernetes/microservices now.

## Consequences

Fast integration, simpler debugging and atomic attempt/XP/receipt. Teams must enforce module boundaries. Extract only at measured security/scale/ownership triggers in the scaling roadmap.
