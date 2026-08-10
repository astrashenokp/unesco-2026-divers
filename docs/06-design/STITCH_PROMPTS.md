# Google Stitch frontend prompt pack

Use prompts sequentially. Attach only synthetic/approved assets. Replace bracketed values; do not expose student data or secrets.

## 0 — persistent design brief

```text
Design Evidence Gym, a mobile-first media and information literacy learning game for students and young adults 16–24. It is an investigation gym, not a fake detector. The learner traces sources and evidence; the AI asks Socratic questions and never acts as a truth oracle.

Emotional target: curious, capable, calm, trustworthy, playful but not childish. Avoid cyberpunk, police/surveillance imagery, red-vs-green truth verdicts, dense admin dashboards, generic purple AI gradients, owl/mascot imitation, and Duolingo brand resemblance.

Core loop: Pause → Predict Trust/Suspicious/Investigate → set confidence → gather evidence → assess Media Authenticity, Claim Veracity, Context Integrity independently → update confidence → choose sharing action → view Evidence Receipt.

Accessibility is mandatory: WCAG 2.2 AA contrast, 44px targets, visible focus, keyboard/screen-reader order, 200% text, status encoded by text + icon + shape + color, reduced motion, captions/transcripts/alt text. English and Ukrainian strings can expand by 35%.

Create semantic design tokens and reusable components. Mobile 390×844 first; also show 1440×1024 responsive web where useful. Use authentic educational content placeholders, not lorem ipsum.
```

## 1 — explore directions

```text
Using the persistent brief, produce three clearly different visual directions for the learning-path home and one mission card. Direction A: warm editorial evidence notebook. Direction B: modern civic investigation lab. Direction C: optimistic map/constellation of sources. For each, keep identical information architecture, label the direction, explain in one short note how it supports trust and youth agency, and avoid brand mimicry. Show light theme first and a compact token swatch.
```

## 2 — learning path/home

```text
Create the selected-direction mobile learning path for a returning learner named Mira. Header: greeting, optional 4-day compassionate streak, 640 process XP. Path units: Source Trail, Context Check, Citation Hunt, Provenance. Current mission: “The photo is real. Is the caption?” Add a 3-minute daily booster and offline-pack badge. Locked states must explain prerequisites; completed states show skill, not only checkmarks. Bottom navigation: Learn, Investigate, Progress. Provide empty, offline, loading and 200%-text variants. No leaderboard.
```

## 3 — mission and prediction

```text
Design a mobile mission brief for an authentic flood photo reposted with a false 2026 location caption. Do not reveal that twist. Include media with accessible alt-text control, source-as-presented, claim, content warning/report affordance, and one primary CTA. Next screen asks Trust / Suspicious / Investigate as an initial reaction and confidence 0–100 with accessible numeric entry plus slider. Explain that changing your mind after evidence is rewarded. Show keyboard focus and validation state.
```

## 4 — investigation workspace

```text
Design the central investigation workspace. Show the claim pinned compactly, remaining evidence-action budget as learning guidance rather than scarcity pressure, and actions: Who published this first? Check date/place. Find independent coverage. Inspect provenance. Ask coach. Display two evidence cards with publisher, source type, retrieval time, short finding, verification status and limitations. The Socratic AI says “Who originally published this?” and is visibly labeled AI Coach. Include loading, not-found, conflicting-evidence, provider-unavailable and offline deterministic states. Mobile one-pane; web split-pane with identical reading order.
```

## 5 — three-axis conclusion

```text
Design a conclusion screen that prevents binary truth thinking. Three independent cards: Media Authenticity [Authentic / Synthetic / Altered / Unknown], Claim Veracity [Supported / Contradicted / Mixed / Insufficient evidence], Context Integrity [Accurate / Misleading / Missing / Unknown]. Each asks confidence. Include “I need more evidence” and a responsible sharing decision: Do not share, Share with context, Continue investigating. Use distinct icons/shapes and calm colors; never make green mean fully true. Provide incomplete-form and high-text-scale states.
```

## 6 — Evidence Receipt

```text
Create a celebratory but rigorous Evidence Receipt. Headline insight: “Real media can still mislead.” Show before 82% Trust → after 91% Contradicted/Misleading without shaming. Timeline the actions and source trail; show three-axis result, process rubric, +XP by evidence behavior, limitations, exact mission/source version and “learning record, not a certificate of truth” disclaimer. Actions: Review sources, Practice weak skill, Report correction. Share export must omit identity and avoid a truth seal.
```

## 7 — citation hunt

```text
Create the second demo mission, Citation Hunt. Present a short AI-generated academic paragraph with a plausible paper citation. Let the learner extract title/authors/year/DOI, then show registry checks with nuanced states: exact match, metadata mismatch, not found in queried registries, provider unavailable, paper exists but claim support cannot be determined. Never label not-found as fabricated automatically. End with “Fluency is not evidence.” Include accessible table/card alternatives.
```

## 8 — design system sheet

```text
From the approved screens, create a design-system sheet with semantic color/typography/spacing/radius/motion tokens and all reusable components/states. Include grayscale/status test, dark theme only if AA passes, 200% text, Ukrainian expansion examples, focus/hover/pressed/disabled/loading/error/offline states, and a mapping table suitable for Flutter ThemeData + ThemeExtension. Do not use raw visual names as semantic token names.
```

## 9 — QA critique

```text
Act as a rigorous product designer and accessibility reviewer. Critique the approved Evidence Gym flow against: one primary action, no binary truth cue, evidence provenance visible, uncertainty respected, Socratic AI label, mobile/web parity, keyboard/screen-reader order, AA contrast, 44px targets, 200% text, reduced motion, Ukrainian expansion, offline/error states, and no dark patterns. Return P0/P1/P2 issues with exact screen/component and an acceptance test. Do not redesign until the team selects issues.
```
