# Evidence Gym design system

## Experience direction

Investigation lab, not surveillance dashboard; playful confidence, not childishness; evidence is visible and tactile. Visual metaphor: trace, connect, inspect, update.

## Principles

- One dominant action/question per screen.
- Show evidence provenance and limitations near the evidence.
- Three axes always use text/icon/shape plus color.
- Celebrate careful reasoning and justified updates, never political agreement.
- Progressive disclosure: mission first, technical provenance on demand.
- Calm error/degraded states; no urgency/shame.

## Token contract

Define Flutter `ThemeExtension`/semantic tokens, not raw colors in features: `surface`, `surfaceRaised`, `textPrimary`, `textMuted`, `action`, `evidencePrimary`, `evidenceSecondary`, `unknown`, `supported`, `contradicted`, `misleading`, `focus`, `danger`. Contrast AA minimum; status survives grayscale.

Typography uses scalable text styles and system fallback supporting Ukrainian. Spacing uses 4/8-point scale; target size at least 44×44 logical pixels; radius/elevation subtle. Motion 150–300 ms with reduced-motion alternatives and no meaning conveyed only by animation.

## Components

Mission card, confidence slider with numeric/text value, evidence-action chip/card, source identity card, evidence graph node/edge, Socratic coach bubble with AI label, three-axis assessment card, uncertainty choice, Evidence Receipt timeline, path node, skill meter, offline/degraded banner, content warning, report action.

## Design-to-code source

Reviewed `DESIGN.md`/tokens and approved screenshots are design source. Stitch-generated HTML is reference only; frontend owner implements reusable Flutter components and semantics, then QA compares intent/accessibility—not raw DOM.
