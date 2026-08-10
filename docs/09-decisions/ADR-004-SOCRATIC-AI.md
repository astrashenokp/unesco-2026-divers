# ADR-004: Socratic AI, bounded evidence, deterministic fallback

Status: Accepted — 2026-08-10

## Decision

LLM receives only allowed normalized evidence and returns structured hints. It cannot authorize, score, publish, mutate gold or expose verdict early. Every P0 mission completes with deterministic hints when AI/provider is unavailable.

## Rationale

This is the product differentiator and reduces hallucination, injection, latency, cost and demo dependency.

## Consequences

Requires hint policies/evals/provider gateway/versioning. Open-ended “ask anything” is out of MVP. Socratic effectiveness remains a hypothesis to test.
