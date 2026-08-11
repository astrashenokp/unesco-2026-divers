# Mascot, color, motion and reference language

This extends `DESIGN_SYSTEM.md` (still the source of truth for tokens, components and the AA/grayscale rule). It exists because Role 1 asked for one place that writes down the mascot, the full color rationale, the motion language and what each animation/inspiration site actually contributes, so implementation choices are traceable instead of ad hoc.

## Why not green/red

`CONCEPT.md` and `DOMAIN_MODEL.md` are explicit: `insufficient_evidence` is not false, synthetic is not automatically false, authentic is not automatically true. A green-check/red-cross status system would silently reintroduce the binary truth oracle the whole product argues against — a learner would read "red" as "verdict: false" within one session regardless of what the label says. So green/red are reserved for nothing in this product. This is a product-integrity rule, not a taste preference.

## Mascots

### Lupa (лупа — magnifying glass) — primary companion

Lupa is the visual form of the Socratic coach: a round creature whose whole face is a magnifying-glass lens. It never states a verdict; it only asks the next useful question, exactly like the AI coach it represents ("What do you notice?", "Who else says this?"). Lupa's presence is the UI's constant reminder that the tool does not decide for the learner.

- Body: soft rounded indigo body (`action` token) with a short handle-tail; the "face" is the lens itself, rimmed in amber (`evidenceSecondary`).
- Idle: 2.4s gentle vertical bob (±4dp) + occasional blink (lens iris contracts for 120ms). Continuous, low-amplitude, never distracting.
- Thinking (waiting for a hint/provider call): lens tilts 8°, three small orbiting dots — communicates "working," not "loading spinner anxiety."
- Encouraging (after a well-reasoned investigation, regardless of the final label): a single small hop + neutral-colored (not green) confetti of trace/dot shapes. Rewards *process*, matching `GAME_AND_LEARNING_DESIGN.md`'s process-XP rubric — never rewards "you were right."
- Asking (delivering a bounded hint): a small spark above the lens rim while the hint bubble opens; always paired with the existing "AI label" component from `DESIGN_SYSTEM.md` — Lupa is never mistaken for a human or an authority.
- Reduced motion: idle/thinking/asking collapse to a single crossfade of the relevant static frame; no meaning is carried by motion alone (already required by `DESIGN_SYSTEM.md`).

Implemented now as a self-contained `CustomPainter` widget (`packages/design_system/lib/src/mascot/lupa.dart`) — no external art asset, so it renders without a missing-asset risk before an illustrator pass exists.

### Slid (слід — trace/footprint) — provenance companion

A small footprint/trail glyph, not a full character with a face. Slid appears briefly next to evidence items to animate the "follow the trail" metaphor (source → date → corroboration). Planned for the evidence-action and Evidence Receipt screens; specified here so the motif exists, not yet implemented in code this round — flagged as a follow-up, not claimed as done.

## Color system

Grounded in the same UX color-psychology consensus behind Material Design's own rationale and WCAG 2.2's "don't convey meaning by color alone" requirement (already in `DESIGN_SYSTEM.md`): blue/indigo reads as trustworthy and calm; teal reads as analytical/clear; amber reads as "pay attention" without alarm; magenta/plum reads as "different from what you expected" without borrowing red's danger coding; a single reserved red-orange is kept *only* for real safety actions, never for a learning-content status. This gives a Google-logo-like plurality of hues (nothing screams "the app's color"), while keeping one unambiguous alarm color for the one place this product genuinely needs one: harmful-content reporting.

| Token (from `DESIGN_SYSTEM.md`) | Hex | Psychology rationale |
|---|---|---|
| `action` (primary/brand) | `#4A47A3` indigo-violet | trust + curiosity, distinct from any "correct answer" green |
| `evidencePrimary` | `#1F8A85` teal | analytical, calm, reads as "tool," not "verdict" |
| `evidenceSecondary` | `#D9A441` amber-gold | discovery/reward without success-green coding |
| `supported` | `#2E7D6B` deep teal | "current sources agree" — still not green |
| `contradicted` | `#8E4585` plum | "current sources disagree" — not red; paired with an icon (✕-in-diamond), never color alone |
| `misleading` | `#C97A2B` burnt orange | "technically true, wrong impression" — paired with a context/frame icon |
| `unknown` | `#6B7280` slate | explicitly neutral; `insufficient evidence` is a first-class outcome, styled with the least visual weight, not the most |
| `focus` | `#2D9CDB` cyan-blue | visible keyboard/a11y focus ring, AA against both surfaces |
| `danger` | `#D64545` red-orange | reserved exclusively for report/safety/harm flows (`report action`, safeguarding banners) — never for a learning conclusion |
| `surface` | `#FAFAF7` warm off-white | reduces glare vs pure white, softer for long reading sessions |
| `surfaceRaised` | `#FFFFFF` | card/sheet elevation |
| `textPrimary` | `#1E1B2E` | near-black with a warm indigo tint, AA on `surface`/`surfaceRaised` |
| `textMuted` | `#615C78` | AA-checked secondary text |

Every status token above ships with a fixed icon + shape in the three-axis and evidence components (already required by `DESIGN_SYSTEM.md` line "Three axes always use text/icon/shape plus color" and "status survives grayscale") — the table above is the color *half* of that rule, not a replacement for it.

## Typography and the "line" motif

`DESIGN_SYSTEM.md` already commits to system-fallback type (Ukrainian coverage without a custom-font network fetch or a missing-font-asset risk) — this doc does not reopen that. The vau.agency reference is honored through layout, not a bespoke typeface: large, heavily tracked-out display headings (bold system font, +2% letter spacing) sit directly above a signature 1px `evidenceSecondary` rule that underlines the current section title — the same "big type + a confident line" read, achieved with zero font-loading risk. The rule doubles as a progress indicator on the path screen (see Motion).

## Motion language

Base timing (150–300ms, reduced-motion alternative required) is unchanged from `DESIGN_SYSTEM.md`. Concrete patterns added here:

- **Scroll reveal** on the skill path: each path node fades + scales from 0.92→1.0 as it crosses ~70% of the viewport, staggered 40ms per node, spring curve (`Curves.easeOutBack`, small overshoot) — the "Duolingo path" feel the brief asked for, implemented with a plain `ScrollController` listener driving per-node `AnimatedScale`/`AnimatedOpacity`, no extra animation package.
- **Buttons/chips**: 120ms scale-down on press (0.97), spring back on release — tactile without a haptic dependency.
- **Screen transitions**: shared-axis slide+fade (200ms) between onboarding slides and between path → mission screens, via Flutter's built-in `PageTransitionsTheme`.
- **Confidence slider**: value label crossfades, track fill animates 180ms — never snaps, since the product explicitly rewards *updating* confidence.
- Every pattern above has a `MediaQuery.disableAnimations` / reduced-motion fallback that keeps the end state identical, per the existing accessibility rule.

## Pre-auth sequence

Interpreting "екран типу як в bybites" as the familiar pre-auth pattern used by Duolingo/most consumer apps — since no such literal site was in the reference list, this is a named assumption, not a guess buried in the code: a 3-slide value-proposition carousel (`Investigate, don't guess.` / `The AI asks questions, it never decides for you.` / `Practice on real cases, safely.`) with Lupa animating on each slide, ending in a single screen offering **Continue as guest** (Firebase Anonymous Auth, per ADR-008) or **Enter demo key**. This matches the already-specified `SCREEN_INVENTORY.md` "language/guest onboarding" and "Demo route" entries — nothing here contradicts them, it fills in the sequencing and motion.

Demo key for judges/testers: **`EVIDENCE-GYM-DEMO`** (case-insensitive, checked entirely client-side, no network call — matches the "demo mode independent of live third-party APIs" P0 requirement). Entering it seeds a local fixture pack and skips real auth, exactly as `SCREEN_INVENTORY.md`'s demo-route entry specifies.

## Accessibility commitments (concrete, not aspirational)

- WCAG 2.2 AA contrast on every token pair above (verified by hex, re-verify after any token edit).
- All tap targets ≥44×44dp; mascot and decorative motion are never the only way to trigger an action.
- Every status is icon + shape + text, not color alone (see table above).
- Full `Semantics` labels in Ukrainian and English on every interactive widget; screen-reader order matches visual order.
- Text scales to 200% without clipping or horizontal scroll (`SCREEN_INVENTORY.md` requirement carried into code, not just policy).
- No auto-advancing carousels, no flashing >3Hz, reduced-motion respected everywhere in "Motion language" above.
- Reading level: short sentences, one question per screen, iconography that repeats across screens (a 9-year-old and a first-time smartphone user should recognize the same trust/suspicious/investigate icons every time).

## Responsive targets

Two breakpoints, matching `SCREEN_INVENTORY.md`'s "mobile is primary, tablet/web may split panes": `<600dp` single-pane mobile with a bottom action region; `≥600dp` (tablet/laptop/web) introduces a secondary pane for evidence/provenance detail beside the mission content, same reading order, same components — no separate "web app," one codebase per ADR-002.

## Reference sites: what we actually borrow

Verified by browsing where practical; several of these are visually dense catalog sites best used as ongoing manual references rather than sources of specific claims here, so this table states *purpose*, not pixel measurements.

| Site | What we borrow | Caution |
|---|---|---|
| [flutter/samples](https://github.com/flutter/samples) | Reference implementations for `PageView` carousels, adaptive/responsive layout (`Scaffold`+breakpoints), and animation idioms (`AnimatedList`, implicit animations) used in the scaffold below | BSD-3-Clause-style Flutter org license (verify `LICENSE` in-repo before copying substantial code); adapt idioms, don't vendor whole samples |
| [uk.duolingo.com](https://uk.duolingo.com/) | Winding skill-path map, mascot-led encouragement, non-punitive streak | not a source for color (their green=correct is exactly what we reject) or for ad/monetization patterns |
| [bytebytego.com](https://bytebytego.com/) | Clear large-diagram explainer layout — informs the evidence-graph/provenance visualization style | technical-diagram audience, not a UI-chrome reference |
| [mobbin.com](https://mobbin.com/) | Pattern library for real mobile onboarding/auth/empty-state flows | proprietary screenshot library — reference for pattern only, never copy assets |
| [refero.design](https://refero.design/) | Component-level micro-interaction reference (chips, sliders, cards) | same — pattern only |
| [saasframe.io](https://www.saasframe.io/) | Landing/pre-auth section pacing | commercial SaaS marketing tone; tone down for a learning product |
| [flowstep.design](https://flowstep.design/) | Full onboarding-flow sequencing reference for the pre-auth carousel | flow structure only |
| [awwwards.com/elements](https://www.awwwards.com/elements/) | Award-tier micro-interaction inspiration (button/hover states) | experimental-web-first, not all patterns translate to mobile/a11y — filter through the accessibility commitments above |
| [pageflows.com](https://pageflows.com/) | Recorded real-product flows — used to sanity-check our onboarding→first-mission flow length | video reference, not a code source |
| [boostedusa.com](https://boostedusa.com/) | Bold CTA/hero pacing for the pre-auth carousel | commercial/retail tone, borrow structure only |
| [coursera.org](https://www.coursera.org/) | Progress/skill-tree and "continue where you left off" pattern for `me/progress` | course-marketplace chrome not relevant |
| [vau.agency](https://vau.agency/) | The line-under-heading typographic motif described above | agency portfolio motion is heavier than a learning app should be; borrow the type/line idea only |
| [fedoriv.com/ua](https://fedoriv.com/) | Bold, confident Ukrainian-language display type pairing, validates system-font-at-scale approach | brand-agency tone; keep our copy Socratic/warm, not punchy/ad-like |

## Google Stitch

Stitch was not used for the screens below. `ADR-006` already fixes Stitch output as reference-only — Role 1 implements the real Flutter widgets and semantics either way — so going straight to Flutter code loses nothing but a throwaway visual mockup. If a teammate wants Stitch mockups before further screens, `docs/06-design/STITCH_WORKFLOW.md` and `docs/07-agents/MCP_STITCH_SETUP.md` describe how to wire it up.
