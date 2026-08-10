# Duolingo patterns adapted responsibly

Public Duolingo materials describe individual systems at particular dates, not a complete current production architecture. We borrow patterns, not proprietary topology or branding.

| Public pattern | Evidence Gym adaptation | Guardrail |
|---|---|---|
| bite-sized interactive lessons | 3–5 minute evidence missions | learning outcome before session count |
| linear path with spaced practice | skill-tag path + due boosters | explain why an item returns |
| Session Generator | deterministic next-activity selector receives pack + learner state | no network dependency for demo |
| offline-preprocessed shared course data | versioned scenario bundles in Cloud Storage/client cache | signed manifest, explicit version |
| adaptive ability/item difficulty | simple explainable mastery first; model later | cold-start and deterministic fallback |
| streak/XP/celebration | compassionate streak and process XP | opt-out, freeze, no shame/dark patterns |
| experimentation platform | flags, exposure event, primary/guardrail metrics | ethics/privacy review; not engagement-only |
| bounded server-driven UI | allowlisted card templates/pack schema | no remote executable code/security UI |
| frontend prediction | immediate progress animation, reconcile with server ledger | server authoritative, rollback UI safely |
| tracing across services | OpenTelemetry correlation from day one | modular monolith first |

Primary reading:

- [Session Generator rewrite](https://blog.duolingo.com/rewriting-duolingos-engine-in-scala/)
- [Learning path and spaced repetition](https://blog.duolingo.com/new-duolingo-home-screen-design/)
- [Duolingo Method](https://blog.duolingo.com/duolingo-teaching-method/)
- [Frontend prediction](https://blog.duolingo.com/frontend-prediction/)
- [Server-driven UI](https://blog.duolingo.com/server-driven-ui/)
- [Experimentation](https://blog.duolingo.com/improving-duolingo-one-experiment-at-a-time/)

## What we deliberately do not copy

- hearts that block learning after mistakes;
- public leaderboards for politically sensitive judgments;
- manipulative notifications or mascot pressure;
- service decomposition justified by another company's scale;
- opaque adaptation before enough quality data exists.
