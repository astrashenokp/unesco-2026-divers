# UNESCO Youth Hackathon 2026 — MIL Research & Product-Idea Dossier (raw source)

## Research dossier for Claude / Notion

**Project context:** a Flutter mobile + web educational game for Media and Information Literacy (MIL), inspired by Duolingo-style progression, where users learn to investigate social-media posts, news/articles, AI-generated images/video, and AI/chatbot claims. The planned AI assistant should teach verification rather than return a simplistic true/false answer. A Source Checker should be especially useful to students.

**Team context:** four strong programmers from Ukraine.

**Purpose of this file:** research, product thesis, competition strategy, learning science, audience strategy, idea generation, impact measurement, reusable open-source/research references, and exact source/repository paths worth inspecting.

**Explicitly out of scope here:** software architecture, backend architecture, API contracts, database schemas, Flutter structure, deployment, code generation, infrastructure, and implementation details. Claude should derive those later from the selected product thesis.

---

# 0. How Claude should use this dossier later

This is intentionally broader than the final product should be.

Claude should **not** turn every idea below into a feature. Instead:

1. Preserve the core educational philosophy.
2. Select one primary audience.
3. Select one unforgettable learning loop.
4. Select 3–5 high-value differentiators.
5. Select 2–3 polished demo scenarios.
6. Map every selected element to UNESCO’s judging criteria.
7. Keep the pitch understandable in one sentence.
8. Use the remaining ideas as post-hackathon roadmap, sustainability, research, and scale evidence.
9. Treat factual claims tagged as research findings separately from strategic hypotheses.
10. Re-check licenses and current repository paths before copying code, datasets, images, or educational content.

The most important meta-rule:

> **Build a product that teaches a transferable verification process, not a machine that claims to know truth.**

A second meta-rule:

> **The dossier can be huge. The competition entry cannot.**

---

# 1. Executive verdict

The base idea is strong, timely, and highly aligned with the UNESCO Youth Hackathon 2026. However, the generic framing **“Duolingo for fake news + AI fact checker” is not sufficiently original by itself**.

A closely overlapping concept has already won a UNESCO Youth Hackathon:

- **MAHW — 2024 winner, Iraq/UAE/Egypt:** a mobile app combining gamified learning, AI-powered fact-checking, and interactive quizzes.
- Official UNESCO source:
  https://www.unesco.org/en/articles/winners-unescos-youth-hackathon-2024-shape-future-media-and-information-literacy

Therefore, the winning 2026 version should not be:

> “An app that tells users whether content is fake.”

It should be closer to:

> **A verification gym that turns users from passive consumers into evidence investigators. Users train the same verification reflex across social media, news, AI-generated media, and chatbot answers. They earn progress for finding evidence, tracing sources, checking context, and correctly managing uncertainty. The AI is a Socratic investigation coach, not a truth oracle.**

Possible one-line formulations:

- **A flight simulator for the information age.**
- **Train your verification reflex.**
- **From instinct to evidence.**
- **Don’t guess. Investigate.**
- **Proof before share.**
- **AI literacy is not spotting pixels. It is building proof.**
- **Detectors age. Verification habits transfer.**

The strongest differentiators in this dossier are:

1. **Evidence-process scoring instead of answer-only scoring.**
2. **Confidence calibration before and after investigation.**
3. **Three independent axes: authenticity, claim veracity, context integrity.**
4. **A Socratic AI coach that asks for the next verification action instead of revealing a verdict.**
5. **Academic hallucination / citation verification for students.**
6. **Content provenance and Content Credentials literacy, especially timely because EU AI Act Article 50 transparency obligations became applicable on 2 August 2026.**
7. **Prebunking/inoculation + spaced boosters rather than only debunking.**
8. **“Insufficient evidence” as a rewarded correct outcome.**
9. **A reproducible Evidence Receipt showing how a conclusion was reached.**
10. **Ukraine as the lived design origin for crisis-grade information resilience, but with a globally transferable product.**
11. **Measuring skill transfer on unseen examples, not only XP or completion.**
12. **Hybrid community/teacher/NGO scenario packs so the project is bigger than a consumer app without becoming technically massive.**

---

# 2. UNESCO Youth Hackathon 2026: what the competition actually rewards

Official page:
https://www.unesco.org/en/articles/unesco-youth-hackathon-2026

Theme:

**“Play Your Part: Youth Designing the Future of Media and Information Literacy (MIL)”**

The 2026 challenge tracks include:

- AI and MIL
- MIL Education
- Community Impact
- Youth Engagement
- Open Track

Your project naturally fits **AI and MIL + MIL Education**, with optional Community Impact and Youth Engagement layers.

The submission requires:

- Proposal document in English
- PDF or Word
- Maximum 10 MB
- Team members
- Problem statement
- Objectives
- Target audience
- Prototype or concept
- Sustainability
- Creativity
- Feasibility
- Pitch video maximum 3 minutes

Deadline:

**16 August 2026, 23:59 Paris time**

Evaluation is especially important. UNESCO says each project will be reviewed by three experts using:

1. **Consistency with the Theme**
2. **Clarity of Presentation**
3. **Innovation & Creativity**
4. **Feasibility & Sustainability**
5. **Impact & Inclusion**

Four winning teams will be selected.

The 2025 edition attracted more than 1,200 teams from 138 countries. The competition is therefore not “who built the most software.” It is a global concept competition where the product must become legible and memorable very quickly.

## What this means strategically

### Criterion 1 — Consistency with the Theme

The learner should visibly **“play their part.”**

Do not make the user a passive recipient of AI verdicts.

Make the user:

- investigator;
- source tracer;
- context checker;
- evidence judge;
- responsible sharer;
- peer educator;
- community contributor.

The slogan “Play Your Part” is almost perfectly matched by a system in which the user must actively gather evidence before a conclusion.

### Criterion 2 — Clarity of Presentation

A jury member should understand the concept after one sentence and one screen.

Good:

> “A game that trains young people to verify evidence before trusting or sharing content in the AI age.”

Weak:

> “A multimodal AI-powered fact-checking education platform combining LLMs, deepfake detection, RAG, gamification, crowdsourcing, knowledge graphs, blockchain, provenance, APIs, social simulation…”

The dossier can contain all of those research directions. The pitch should not.

### Criterion 3 — Innovation & Creativity

Do not count “LLM integration” as innovation in 2026.

Real innovation can come from the **learning interaction**:

- AI refuses to be the truth oracle.
- XP rewards evidence steps.
- User predicts confidence before investigating.
- User can be rewarded for “I do not know yet.”
- AI-generated does not automatically mean misleading.
- authentic media does not automatically mean truthful.
- provenance and truth are taught as different concepts.
- academic citations become a game mechanic.
- user learns when **not** to amplify uncertain content.
- final assessment tests transfer to unseen generators/topics/formats.

### Criterion 4 — Feasibility & Sustainability

The strongest feasibility argument is not “we can program fast.”

It is:

- use mature open standards;
- reuse existing educational methods;
- use public scholarly metadata;
- use existing fact-check indexes;
- use existing provenance standards;
- avoid training a fragile detector from scratch;
- build a small number of excellent cases;
- allow future scenario packs to expand the content;
- create a product that can survive after a single hackathon.

### Criterion 5 — Impact & Inclusion

You need more than:

- downloads;
- XP;
- streaks;
- time in app.

Better measures:

- ability to identify manipulation on unseen examples;
- primary-source discovery;
- independent corroboration;
- improved confidence calibration;
- fewer unjustified high-confidence conclusions;
- correct use of “insufficient evidence”;
- higher-quality sharing decisions;
- skill retention after a week/month;
- ability to transfer verification strategies to another format.

Inclusion should be visible in the concept:

- low-bandwidth paths;
- captions/transcripts;
- screen-reader-safe materials;
- color-independent status cues;
- printable/community challenge cards;
- multilingual scenario packs;
- scenarios relevant to displaced/crisis-affected populations;
- teacher and youth-organization use;
- age-appropriate versions.

---

# 3. Historical UNESCO Hackathon winner analysis

The best way to understand what UNESCO may reward is not to imitate one winner. It is to identify the pattern across years.

---

## 3.1 2025 winners

Official source:
https://www.unesco.org/en/articles/global-youth-lead-way-media-and-information-literacy-meet-unesco-hackathon-2025-winners

UNESCO reports 1,286 proposals from 138 countries and four winning teams.

### CLICKBAIT — Vietnam

Format:
- detective-style board game;
- real social scenarios;
- debate;
- teamwork;
- critical thinking.

Framework:
- Creator
- Content
- Context
- Bias
- Business

Deep winner story:
https://www.unesco.org/en/articles/local-board-game-global-stage-vietnamese-students-rethink-digital-trust

Important design lesson:

CLICKBAIT did **not** simply tell players what was true or false. The game focused on asking the right questions and understanding systems, motivations, bias, and power.

That is extremely relevant to your LLM Assistant.

Other important points UNESCO highlighted:

- the idea came from lived experiences with scams/harassment;
- the team changed direction multiple times;
- complex mechanics were simplified;
- they grounded the project in UNESCO materials;
- they play-tested it across different universities;
- the meaningful learning moment was realizing users themselves could be misled.

### MIL Point — Indonesia

Combined:

- mobile-box campaigns;
- social-media content;
- gamified app;
- quizzes;
- debate;
- trusted news;
- leaderboards;
- workshops;
- community collaboration.

Lesson:

A digital product can be stronger when it extends into community participation rather than being a closed app.

### Youth Council — Argentina

A formal youth council around Media and AI:

- AI ethics;
- digital rights;
- misinformation;
- deepfakes;
- journalism ethics;
- inclusion.

Lesson:

UNESCO values youth participation and governance, not only consumer technology.

### Mentes Libres — Cameroon

Focused on orphaned youth in conflict-affected settings:

- offline training;
- digital empowerment;
- free AI verification;
- inclusion.

Lesson:

“Impact & Inclusion” can be a major competitive differentiator when the target audience has a real access problem.

---

## 3.2 2024 winners

Official source:
https://www.unesco.org/en/articles/winners-unescos-youth-hackathon-2024-shape-future-media-and-information-literacy

### MAHW — Iraq / UAE / Egypt

This is the most important precedent for your team.

MAHW included:

- a mobile app;
- gamified learning;
- AI-powered fact-checking;
- interactive quizzes;
- reportedly 60% of core features already developed.

**Strategic conclusion:** “gamified mobile MIL + AI fact checking” has already won.

Do not abandon the concept. Move one level deeper.

Your 2026 originality must come from:
- *how* the learner reasons;
- *what* the AI is allowed to do;
- *what* is rewarded;
- *how* uncertainty is represented;
- *how* real/synthetic/context are separated;
- *how* skill transfer is measured.

### ARTiFAKE — Ukraine

Important because you are from Ukraine.

ARTiFAKE used:

- street art;
- digital comics;
- animated cartoons;
- public spaces;
- protagonists;
- community-driven critical thinking.

Lesson:

“Ukraine + misinformation” itself is not a novel winning narrative anymore. Ukraine should provide **design credibility and lived urgency**, not be the only differentiator.

### Idea’s Echo — Madagascar

Used:

- radio/podcast;
- climate/SDG themes;
- local experts;
- Malagasy dialects.

Lesson:

Localization and linguistic access matter.

### MILBoard — Indonesia

Used:

- physical board game;
- mobile app;
- children aged roughly 10–17;
- remote and underserved audiences;
- challenge cards;
- MIL curriculum.

Lesson:

Hybrid physical/digital learning and underserved audiences repeatedly perform well.

---

## 3.3 2023 winners

Official source:
https://www.unesco.org/en/articles/youth-hackathon-winners-celebrated-paris

### MILES — Philippines

Combined:

- app;
- resources;
- games;
- events;
- campaigns.

Lesson:

Winning projects often expand beyond one interaction mode.

### MIL Justice League — Cameroon

Used a superhero narrative game where players solve real-life media problems.

Lesson:

Narrative identity can turn abstract MIL competencies into memorable behavior.

### Wazobia “Disagree in Peace” — Nigeria

Used artists and cultural participation to address hate/disinformation.

Lesson:

MIL is wider than factuality. It includes dialogue, pluralism, hate speech, participation, and responsible expression.

### YMLAP — Jordan

Focused on youth MIL ambassadors and peer education.

Lesson:

A “multiplier” model is attractive to UNESCO because users can become educators/change agents.

---

## 3.4 2022 signals

Official edition page:
https://www.unesco.org/en/media-information-literacy-week/fourth-youth-hackathon

UNESCO reported six winning teams from 77 teams / 312 young people across 25 countries in the 2022 edition.

The evaluation language at the time already emphasized:

- consistency;
- excellence;
- feasibility/sustainability;
- potential impact.

The 2022 edition also explicitly asked for:

- deployment strategies/business model;
- evidence of market validation;
- sustainability.

Lesson:

Even in an educational/social-impact hackathon, **validation and realistic continuation** matter.

---

## 3.5 2021 winners

Official source:
https://www.unesco.org/en/articles/truly-digital-entrepreneurs-six-solutions-win-global-media-and-information-literacy-youth-hackathon

### Smart Pan — China

An immersive LARP game integrating media and information judgment training.

Lesson:

Experiential learning is repeatedly rewarded.

### Rainbow Light — China

A podcast created by visually impaired college students and allies, focused on accessible information and advocacy for better accessibility.

Lesson:

Inclusion can be core product identity, not a checkbox.

### SAM’s Adventures — Germany

Hybrid treasure hunt for children 8–12 with digital and physical tasks; designed to be easy for teachers to implement.

Lesson:

Teacher usability + hybrid interaction + age-specific design is a strong pattern.

### Global Girl Media Greece — Greece / USA

Podcast and Instagram campaign about gender-based violence, with vulnerable communities including refugee camps/shelters.

Lesson:

MIL becomes stronger when connected to real safety/social problems and community voice.

### Afrorama — South Africa

Collaborative digital encyclopedia focused on African knowledge.

Lesson:

Knowledge representation, pluralism, and locally grounded information ecosystems can be MIL.

---

## 3.6 2020 winner pattern

Official source:
https://www.unesco.org/en/articles/winners-global-media-and-information-literacy-youth-hackathon-reveal-inspiring-projects-fight

Examples included:

- disability/community inclusion;
- truthful information and women activists;
- harassment/social-media literacy;
- classroom integration;
- a game about critical thinking and source credibility.

Lesson:

The long-term pattern is remarkably stable.

---

# 4. What past winners actually tell us

Across editions, UNESCO repeatedly rewards projects with some combination of these characteristics:

1. **A specific human problem**, not “misinformation is bad.”
2. **A specific audience**, not “everyone.”
3. **Youth agency**, not passive consumption.
4. **Experiential learning**, not lectures.
5. **Community extension**, not only a screen.
6. **Inclusion/accessibility**, especially underserved groups.
7. **Local lived context + global transferability.**
8. **A memorable metaphor or mechanic.**
9. **Practical feasibility.**
10. **Evidence that real people were consulted or tested it.**
11. **Clear connection to UNESCO MIL values.**
12. **Skills, judgment, dialogue, and civic responsibility**, not just content moderation.
13. **Human agency over automated authority.**
14. **Sustainability through teachers, youth groups, partners, or reusable content.**

### The most important lesson for this team

Do not compete by building the most advanced detector.

Compete by creating the **best learning mechanism** around the modern information problem.

A technically strong team has an unusual advantage: you can make a sophisticated interaction feel simple.

That is more valuable than exposing sophistication.

---

# 5. What is missing from the current base concept

The base idea already has:

- clear categories;
- a game loop;
- gamification;
- LLM assistance;
- student Source Checker;
- mobile/web reach.

But several competitive gaps remain.

## Gap 1 — “True/false” is still too close to the center

Even if the assistant asks questions first, the surrounding concept still risks becoming a truth-classification product.

Better center:

**Investigation quality.**

## Gap 2 — “AI image detection” can become a technological trap

The newest research and challenges emphasize:

- unseen generators;
- cropping;
- resizing;
- compression;
- blur;
- distribution shift.

Reference:
https://github.com/msu-video-group/NTIRE-2026-DeepFake-Detection

If the project claims “we detect AI images,” judges familiar with the field can ask:

- what happens on a new generator?
- what happens after Telegram/WhatsApp compression?
- what happens after a crop?
- what is your false-positive rate?
- does “AI-generated” imply misinformation?

The better answer is:

> “Detection is one clue. We teach users to combine clues with provenance, context, source tracing, and corroboration.”

## Gap 3 — no explicit learning science yet

Duolingo aesthetics do not automatically produce learning.

The product needs a defensible educational mechanism:

- lateral reading;
- prebunking/inoculation;
- retrieval practice;
- spaced boosters;
- confidence calibration;
- metacognition;
- transfer testing.

## Gap 4 — no signature conceptual insight yet

The strongest candidate is:

### Three-axis media judgment

Instead of one “fake/real” label:

**Axis A — Media authenticity**
- authentic;
- synthetic;
- manipulated;
- unknown.

**Axis B — Claim veracity**
- supported;
- contradicted;
- insufficient evidence;
- not a factual claim.

**Axis C — Context integrity**
- accurate context;
- missing context;
- misleading context;
- out of context.

This solves a major modern misunderstanding:

- AI-generated content can be honest and clearly disclosed.
- authentic content can be used deceptively.
- a real photo can have a false caption.
- a real research paper can be misrepresented.
- provenance can be valid while the associated claim is still false.

This is highly teachable and extremely pitchable.

## Gap 5 — no measured “mind change”

A media-literacy product should teach users to update beliefs.

Add:

- initial choice;
- initial confidence;
- investigation;
- final choice;
- final confidence;
- brief reflection: “What evidence changed your mind?”

That turns a quiz into metacognitive training.

## Gap 6 — no explicit uncertainty

“Insufficient evidence” must be a prestigious answer.

Users should earn points for avoiding unjustified certainty.

## Gap 7 — no 2026 European regulatory hook

The EU AI Act’s Article 50 transparency obligations became applicable on **2 August 2026**, days before this hackathon deadline.

Official European Commission:
https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content
https://digital-strategy.ec.europa.eu/en/factpages/quick-facts-transparency-rules-ai-systems
https://digital-strategy.ec.europa.eu/en/news/commission-starts-enforcing-ai-act-rules-and-new-transparency-requirements-2-august

This gives you an extremely current narrative:

> **Europe is building AI transparency labels. We teach people how to reason with them.**

## Gap 8 — no community multiplier yet

Past winners repeatedly include teachers, ambassadors, community packs, workshops, physical elements, or vulnerable audiences.

The digital product can remain the center, but show a path for:

- teachers;
- universities;
- youth organizations;
- libraries;
- fact-checking organizations;
- community workshops.

## Gap 9 — no defensible content-scaling story yet

A demo can use 2–3 cases. Sustainability requires a model for more.

Strong direction:

**Scenario packs** created from verified source bundles and reviewed by educators/fact-checkers.

## Gap 10 — no explicit safety/philosophy boundary for the LLM

The AI must not become the authority that the MIL course teaches users to distrust.

That contradiction must be solved by design.

---

# 6. Recommended product thesis

Working name for the idea in this dossier:

# Evidence Gym

Not necessarily the final brand.

## Thesis

**Evidence Gym trains a repeatable verification reflex across social media, news, synthetic media, and AI answers. Users begin with an intuition, investigate using evidence actions, update confidence, and receive feedback on the quality of the verification process. An AI coach guides the next question without acting as a truth oracle.**

## Why this is stronger than “Duolingo for fake news”

Duolingo is a **progression metaphor**.

Evidence Gym is an **epistemic training philosophy**.

The real product is not:

- lessons;
- quizzes;
- fact checks.

The real product is a trained behavioral loop:

1. Pause.
2. Identify the actual claim.
3. Ask who is behind it.
4. Leave the page and investigate laterally.
5. Trace the claim to primary evidence.
6. Check date/location/context.
7. Check provenance where available.
8. Find independent corroboration.
9. Look for corrections/retractions/limitations.
10. Decide what is supported.
11. Calibrate confidence.
12. Decide whether to share/amplify.
13. State what remains unknown.

This is the habit you are selling.

---

# 7. The philosophical foundation: epistemic agency

UNESCO published a relevant 2025 piece:

https://www.unesco.org/en/articles/deepfakes-and-crisis-knowing

Its core direction is especially compatible with this project: deepfakes create not just a detection problem but a **crisis of knowing**, and education should strengthen **epistemic agency** — a person’s capacity to engage responsibly with knowledge when familiar evidence can no longer be taken for granted.

This is a much more powerful foundation than “we detect fake images.”

## Product interpretation

The system should teach:

- how to know;
- how strongly to believe;
- what evidence is enough;
- what evidence is missing;
- when to search;
- when to stop searching;
- when not to share;
- when uncertainty is rational;
- how to correct oneself.

This means the project is not merely a misinformation detector.

It is an **epistemic agency trainer**.

That phrase may be too academic for the pitch, but it is excellent for the proposal and Claude’s future product rationale.

---

# 8. The signature three-axis model

A single “fake/real” axis teaches the wrong mental model.

Use three conceptually independent dimensions.

## 8.1 Media Authenticity

Question:

**What do we know about how this media was created or modified?**

Possible outcomes:

- Authentic / camera-origin evidence available
- Synthetic
- AI-manipulated
- conventionally edited
- unclear / unknown

Important:

Authenticity is not truth.

## 8.2 Claim Veracity

Question:

**What does the evidence say about the claim being made?**

Possible outcomes:

- Supported
- Contradicted
- Insufficient evidence
- Mixed / partially supported
- Not a checkable factual claim

Important:

A true claim can appear beside synthetic media.

## 8.3 Context Integrity

Question:

**Is the media or evidence being represented in the correct context?**

Possible outcomes:

- Correct context
- Missing context
- Out of context
- Misleading caption
- wrong date
- wrong location
- wrong person/event attribution

Important:

A large fraction of harmful misinformation does not require fake pixels.

## Why this is pitch gold

One demo can explain the entire idea:

> “This video is real. The claim is false. The context is misleading.”

That sentence instantly shows why an AI-image detector cannot solve the information problem.

---

# 9. Evidence Actions: what XP should actually reward

The current concept says users earn XP for correct source checking. Make this much more precise.

Potential Evidence Actions:

1. **Claim Spotter** — isolate the checkable claim.
2. **Source Check** — identify who published it.
3. **Author Check** — identify author/account/organization.
4. **Lateral Read** — leave the content and search about the source.
5. **Primary Source Trace** — locate the original paper/document/video/post.
6. **Date Check** — verify publication/event date.
7. **Location Check** — verify geographic context.
8. **Reverse Search** — look for earlier appearance of an image/frame.
9. **Video Keyframe Search** — search representative frames.
10. **Independent Corroboration** — find genuinely independent reporting/evidence.
11. **Syndication Check** — recognize that five copied articles may equal one source.
12. **Citation Existence Check** — verify that a paper/DOI actually exists.
13. **Citation Entailment Check** — verify the cited paper actually supports the claim.
14. **Retraction/Correction Check** — verify current status.
15. **Source-Type Check** — distinguish blog, press release, paper, preprint, official record, opinion.
16. **Evidence Quality Check** — direct vs indirect evidence.
17. **Conflict/Incentive Check** — identify commercial/political/engagement incentives without treating them as automatic disproof.
18. **Provenance Check** — inspect Content Credentials/C2PA where available.
19. **Manipulation Technique Spot** — identify emotional/manipulative tactics.
20. **Confidence Update** — revise confidence appropriately.
21. **Responsible Share Decision** — decide share / do not share / share with caveat.
22. **Critical Ignore** — decide a source is not worth further attention.
23. **Uncertainty Declaration** — correctly state “not enough evidence.”
24. **Correction Acceptance** — update a prior judgment after stronger evidence appears.
25. **Evidence Receipt Completion** — preserve the reasoning chain.

## Scoring principle

Do not over-reward the initial verdict.

Possible philosophy:

- 20% initial/final classification;
- 50% evidence process;
- 20% calibration;
- 10% reflection.

Exact weights can change later; the principle matters.

A user who guessed “Suspicious” correctly but did no investigation should perform worse than a user who began wrong and responsibly updated after good evidence.

That is a profound educational signal.

---

# 10. Confidence calibration: a major differentiator

Before investigation:

> “How confident are you?”

After investigation:

> “How confident are you now?”

Teach three things:

1. correctness;
2. calibration;
3. willingness to update.

Possible learning moments:

- Correct but unjustifiably 100% confident.
- Wrong but low confidence and rapidly corrects.
- Correctly concludes evidence is insufficient.
- Sees strong evidence but refuses to change due to motivated reasoning.

Possible achievements:

- **Well Calibrated**
- **Changed My Mind**
- **Evidence Over Ego**
- **Know When You Don’t Know**
- **Careful Confidence**

A strong system should celebrate:

> “You changed your mind after finding stronger evidence.”

That is more valuable than “You were right.”

---

# 11. Stanford Civic Online Reasoning as the behavioral backbone

Stanford / Digital Inquiry Group:
https://cor.stanford.edu/

Research:
https://cor.stanford.edu/research/
https://cor.stanford.edu/research/lateral-reading-on-the-open-internet/

The major practice to borrow is **lateral reading**:

Instead of staring at an unfamiliar page and trying to judge its design, wording, or “professional appearance,” users leave the page and investigate what other sources say about it.

Useful learning sequence:

1. Who is behind the information?
2. What is the evidence?
3. What do other sources say?

Useful Stanford resources:
https://cor.stanford.edu/curriculum/lessons/lateral-reading-resources-practice/
https://cor.stanford.edu/curriculum/lessons/lateral-reading-with-fact-checking-organizations/
https://cor.stanford.edu/videos/intro-to-lateral-reading/
https://cor.stanford.edu/videos/lateral-reading-video/

Also teach **click restraint**:
https://cor.stanford.edu/blog/videos-to-improve-judgment-online/

## How to transform this into gameplay

Do not explain lateral reading in a paragraph first.

Make the player experience why it matters.

Bad path:
- user spends 30 seconds inspecting About page;
- receives little useful evidence.

Better path:
- user searches source name;
- finds ownership/history/independent references;
- receives Evidence XP;
- game explains “You read laterally.”

---

# 12. Prebunking / inoculation: teach manipulation before exposure

A purely reactive fact checker is always late.

A stronger learning product teaches manipulation techniques in advance.

Important evidence:

### 2026 cross-European video inoculation study

https://www.nature.com/articles/s44271-025-00379-3

The study tested short inoculation videos across 12 EU nations, with 19,735 participants, targeting techniques such as:

- scapegoating;
- decontextualization;
- discrediting.

The campaign reached more than 120 million YouTube users before the 2024 EU elections.

### Long-term booster research

https://www.nature.com/articles/s41467-025-57205-x

Finding direction:
- text/video inoculation effects can persist;
- game effects can decay;
- memory-focused booster interventions can extend effects.

### Multimodal gamified inoculation

Cat Park:
https://www.nature.com/articles/s41598-023-43885-2

Bad News:
https://www.nature.com/articles/s41599-019-0279-9

Bad Vaxx:
https://www.nature.com/articles/s41598-025-09462-5

Research toolbox:
https://www.nature.com/articles/s41562-024-01881-0

## Product implication

Create “Technique Training” mini-levels where users learn to spot:

- emotional manipulation;
- urgency;
- scapegoating;
- false dichotomy;
- conspiracy framing;
- ad hominem;
- decontextualization;
- impersonation;
- fake expertise;
- cherry-picking;
- social proof;
- manufactured consensus;
- “everyone is hiding this” rhetoric;
- engagement bait;
- context stripping;
- manipulated comparison;
- fake citation;
- authority mimicry.

Then return to those techniques later with small “booster” challenges.

Do not make the user memorize terminology for its own sake.

The goal is:

> “I recognize what is being done to my attention.”

---

# 13. Spaced repetition: modern learning rather than arbitrary streaks

Open Spaced Repetition / FSRS:
https://open-spaced-repetition.github.io/
https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler

Dart implementation relevant to Flutter:
https://github.com/open-spaced-repetition/dart-fsrs

Pub package:
https://pub.dev/packages/fsrs

Important exact repo paths to inspect later:

- `README.md`
- `lib/`
- `example/`
- `test/`

Do not reinvent a memory scheduler if the final product needs adaptive boosters.

## Product idea

The spaced unit should not be “repeat the same question.”

Repeat the **skill** in a new context.

Example:

Day 1:
- learn decontextualization from a social-media image.

Day 3:
- see an old disaster video with a new caption.

Day 7:
- see a true scientific chart clipped to remove a qualifier.

Day 21:
- see an AI summary that removes the paper’s limitations.

The learner is practicing the same reasoning pattern across modalities.

That is transfer.

---

# 14. Core game loop: upgraded version

Original idea:

**Trust / Suspicious / Investigate**

Keep it.

It is simple and memorable.

But make it the beginning, not the end.

## Proposed conceptual loop

### Step 1 — First impression

Content appears.

User chooses:

- Trust
- Suspicious
- Investigate

### Step 2 — Confidence

“How confident are you?”

### Step 3 — Investigation budget

The learner receives limited:

- time;
- evidence actions;
- or “attention tokens.”

This teaches that verification happens under real constraints.

### Step 4 — Evidence choices

Possible actions:
- source;
- author;
- original;
- date;
- reverse search;
- independent source;
- paper;
- retraction;
- provenance;
- context;
- fact-check.

### Step 5 — AI coach

The assistant does not say:

> “This is fake.”

It asks:

> “You found five articles. Are they independent, or are they all repeating the same original source?”

or:

> “The paper exists. Does its abstract actually support the claim in the headline?”

### Step 6 — Conclusion

Choose a nuanced outcome.

### Step 7 — Confidence update

User adjusts confidence.

### Step 8 — Share decision

- Share
- Share with context
- Do not share
- Wait for more evidence

### Step 9 — Debrief

Show:
- evidence path;
- missed clue;
- better next action;
- manipulation technique;
- what remains unknown.

### Step 10 — Skill update

Not merely:
+20 XP.

Instead:
- Primary Source skill +;
- Context skill +;
- Calibration skill +.

---

# 15. Nuanced conclusion labels

Potential final statuses:

- Supported
- Contradicted
- Partially supported
- Insufficient evidence
- Opinion / value judgment
- Satire / parody
- Misleading context
- Outdated context
- Synthetic but disclosed
- Manipulated media
- Authentic media with false claim
- Source exists, citation does not support claim
- Retraction/correction affects claim
- Origin unknown
- Provenance available, claim still unresolved

Do not show all of these on every screen.

They form a conceptual taxonomy for lesson design.

---

# 16. The Evidence Receipt

One of the best distinctive ideas.

After an investigation, the user can see a compact **Evidence Receipt**.

Example conceptual fields:

- Claim checked
- Original source found
- Primary evidence
- Independent corroboration
- Date/context
- Provenance status
- Corrections/retractions
- Evidence gaps
- Conclusion
- Confidence
- “Verified as of” date
- Links

Why this matters:

- teaches transparent reasoning;
- avoids black-box authority;
- can be shown in a pitch;
- useful to students;
- useful to teachers;
- useful for peer discussion;
- creates a standard reusable artifact;
- naturally supports “show your work.”

It should not reveal hidden LLM chain-of-thought.

It should display **observable evidence and concise justifications**.

Possible tagline:

> “Not a truth score. A trail you can inspect.”

---

# 17. Source Graph / Evidence Graph

A powerful visual learning idea:

**Claim → Article → Author → Cited report → Primary study → Correction / retraction → Independent confirmation**

Users often think “there is a link” means “there is evidence.”

The Source Graph teaches information lineage.

Possible lesson:

A viral post links to:
- blog;
- blog links to news article;
- article cites university press release;
- press release cites preprint;
- preprint does not support the viral claim.

The learner discovers a **citation laundering chain**.

This is especially valuable for students.

---

# 18. Student / Academic Source Checker: make this a signature mode

This may be one of the most globally valuable differentiators.

Students now face two separate problems:

1. evaluating ordinary sources;
2. verifying references generated by AI.

A generic LLM “source checker” is not enough.

## What the Student Source Checker should teach conceptually

### A. Does the source exist?

Check:
- title;
- author;
- DOI;
- journal/conference;
- year.

### B. Is it the same source the AI described?

LLMs often mix:
- real author;
- real journal;
- fake title;
- wrong year;
- wrong DOI.

### C. What type of source is it?

- peer-reviewed article;
- preprint;
- conference paper;
- book;
- report;
- thesis;
- blog;
- press release;
- opinion;
- news article;
- dataset.

Do not reduce this to “good/bad.”

### D. Does the source support the claim?

A paper can exist without supporting the sentence.

Teach **citation entailment**.

### E. What is the evidence hierarchy for this question?

Different claims need different evidence.

### F. Has the work been corrected or retracted?

This is a genuinely useful student capability.

### G. Is the article reporting a study accurately?

Check:
- sample size;
- population;
- method;
- correlation vs causation;
- uncertainty;
- limitations;
- preprint vs final version;
- press-release exaggeration.

### H. Are multiple citations independent?

Review articles may all depend on the same foundational study.

---

# 19. Public scholarly sources that save enormous time

Do not build a scholarly index.

Use existing metadata ecosystems later.

## OpenAlex

https://developers.openalex.org/
https://developers.openalex.org/api-reference/introduction
https://openalex.org/

Useful for:
- works;
- authors;
- sources;
- institutions;
- topics;
- relationships.

GitHub documentation:
https://github.com/ourresearch/openalex-help

Useful exact path:
- `content/api/introduction.md`

## Crossref

https://www.crossref.org/documentation/retrieve-metadata/rest-api/

Useful metadata:
- DOI;
- title;
- authors;
- publication information;
- funding;
- license;
- post-publication updates;
- ORCID/ROR;
- abstracts when deposited.

GitHub docs:
https://github.com/CrossRef/rest-api-doc

First files to inspect:
- `README.md`
- API tips / etiquette documentation referenced by the README.

### Retraction Watch via Crossref

https://www.crossref.org/documentation/retrieve-metadata/retraction-watch/

Crossref acquired the Retraction Watch database and makes the data publicly available; it is updated on working days.

This is extremely useful for a student “citation verification” story.

## Semantic Scholar

https://www.semanticscholar.org/product/api
https://api.semanticscholar.org/api-docs/

Useful for:
- paper metadata;
- authors;
- references;
- citations.

Do not convert citation count into “truth.”

## Europe PMC

https://europepmc.org/RestfulWebService

Useful for biomedical research.

## Google Fact Check Tools API

https://developers.google.com/fact-check/tools/api/
https://developers.google.com/fact-check/tools/api/reference/rest/

The claims resource supports searching fact-checked claims, including image-based search.

This is a powerful shortcut:
do not build a global fact-check database from scratch.

## ClaimReview schema

https://schema.org/ClaimReview

Useful for understanding standardized fact-check metadata.

---

# 20. LLM Assistant doctrine: a coach, not an oracle

This should become a product principle and later an AI-behavior contract.

## The AI is allowed to:

- identify checkable claims;
- ask the next best verification question;
- suggest search queries;
- explain why a source type matters;
- explain the difference between primary/secondary evidence;
- summarize retrieved evidence;
- point out contradictory evidence;
- explain uncertainty;
- help users interpret a paper;
- help users understand Content Credentials;
- help identify manipulation techniques;
- generate a short debrief grounded in verified evidence;
- adapt difficulty and hints.

## The AI should not:

- instantly reveal the answer;
- invent a source;
- cite a URL it has not verified;
- present model confidence as factual probability;
- treat source reputation as automatic truth;
- classify political opinions as factual misinformation;
- claim that an AI detector proves authenticity;
- claim that provenance proves a claim;
- hide uncertainty;
- expose private chain-of-thought;
- substitute itself for primary evidence.

## Socratic hint ladder

### Hint 1 — question only

> “Who originally published this?”

### Hint 2 — method

> “Try leaving the post and searching the quoted sentence or the account name.”

### Hint 3 — specific clue

> “The repost is from this week, but look for an earlier occurrence of the same frame.”

### Final debrief

Only after the user finishes.

## The assistant should reward evidence quality

Example:

User:
> “I found five websites saying the same thing.”

Assistant:
> “Before treating that as five confirmations, check whether they all cite the same original report.”

This is pedagogically stronger than any true/false response.

---

# 21. FIRE: modern cost-aware fact checking that matches the educational philosophy

Paper:
https://arxiv.org/abs/2411.00784
https://aclanthology.org/2025.findings-naacl.158/

Repository:
https://github.com/mbzuai-nlp/fire

FIRE = Fact-checking with Iterative Retrieval and Verification.

The key idea:

- fact checking is iterative;
- retrieve evidence when needed;
- decide whether there is enough evidence;
- search again only when uncertainty remains.

The paper reports slightly better performance than compared systems while reducing:
- LLM cost by about **7.6×** on average;
- search cost by about **16.5×**.

This is one of the most relevant “modern methods that saves time/money” for this project.

## Exact files/paths to inspect

Start with:
- `README.md`
- `eval/fire/`
- `evaluator.ipynb`
- `common/`
- `datasets/`

The README currently documents the execution flow. If it references a script such as `run_fire.py`, verify its path at clone time because repository layout can change.

## What to reuse

Reuse the **decision principle**, not necessarily the whole framework:

> Search only until evidence is sufficient for the current learning task.

This is also educational:

Users need to learn that verification is not “search forever.”

It is:
- know what is missing;
- collect enough relevant evidence;
- stop when the remaining uncertainty is explicit.

---

# 22. Claim decomposition

Complex misinformation is often a bundle of claims.

Example:

> “A new study from Oxford proves that AI-generated news is more accurate than journalists and that 80% of students prefer it.”

Possible atomic claims:
1. a study exists;
2. it is from Oxford;
3. it compares AI news and journalists;
4. it finds AI more accurate;
5. it reports 80% student preference.

The LLM can help decompose the statement.

The user then chooses:
- which claims matter;
- which claims are checkable;
- which claims require primary evidence.

Research reference:

ProgramFC:
https://github.com/mbzuai-nlp/ProgramFC
https://arxiv.org/abs/2305.12744

OpenFactCheck:
https://github.com/mbzuai-nlp/openfactcheck
https://arxiv.org/abs/2408.11832

Do not blindly copy automated fact-check decisions.

Borrow:
- decomposition;
- modularity;
- evaluation thinking.

---

# 23. AI-generated media: do not make detector accuracy the core promise

The detector arms race is moving fast.

Useful 2026 references:

## NTIRE 2026 Robust DeepFake Detection Challenge

https://github.com/msu-video-group/NTIRE-2026-DeepFake-Detection

The challenge explicitly focuses on:
- cropped images;
- resized images;
- compressed images;
- blurred images;
- other in-the-wild transformations;
- unseen generators.

This is exactly why the project should teach:
**detector output = clue, not verdict.**

## DeepfakeBench

https://github.com/SCLBD/DeepfakeBench

A broad deepfake-detection benchmark that has continued to add newer detectors/datasets.

Exact paths worth inspecting later:
- `README.md`
- `training/test.py`
- `training/train.py`
- `training/config/`
- `training/detectors/`
- `training/metrics/`
- `preprocessing/`

Use it for:
- benchmark literacy;
- comparative evaluation;
- demo experimentation if time exists.

Do not spend the hackathon training a custom detector unless there is a compelling reason.

## UniGenDet — CVPR 2026

https://github.com/Zhangyr2022/UniGenDet

The research explicitly frames modern detection as a generator–detector co-evolution problem.

Exact paths:
- `README.md`
- `demo.py`
- `eval/`
- `modeling/`
- `pretrained/`
- `scripts/`
- `train/`

Strategic lesson:
the field is already beyond static “train on old fake images and classify forever.”

This supports your pitch:
**verification skills remain useful even as generators change.**

## WaRPAD — NeurIPS 2025

https://github.com/sungikchoi/WaRPAD

Training-free AI-generated image detection via cropping robustness.

Exact files:
- `README.md`
- `final_imgn.py`
- `utils.py`
- `roc_tpr.py`
- `requirements.txt`

If you want one experimental detector clue without a large training project, this is more time-efficient than inventing a model.

Still:
do not make it the truth oracle.

---

# 24. C2PA / Content Credentials: one of the highest-value 2026 additions

C2PA specification:
https://spec.c2pa.org/specifications/specifications/2.4/index.html

Explainer:
https://spec.c2pa.org/specifications/specifications/2.4/explainer/Explainer.html

Technical specification:
https://spec.c2pa.org/specifications/specifications/2.4/specs/C2PA_Specification.html

Core open-source Rust SDK:
https://github.com/contentauth/c2pa-rs

Current JavaScript packages:
https://github.com/contentauth/c2pa-js

Important repository update:
the older standalone `c2patool` and Node repositories have moved/been consolidated. Prefer the active repositories above.

## Exact paths worth inspecting

In `contentauth/c2pa-rs`:
- `cli/README.md`
- `cli/docs/usage.md`
- `cli/sample/`
- `docs/`

In `contentauth/c2pa-js`:
- `README.md`
- `packages/c2pa-web/`
- `packages/c2pa-node/`

The current JS README notes that older C2PA JS packages are deprecated and implementers should use the libraries in the current repository.

## What to teach

A Content Credential can help answer:

- where content came from;
- what transformations are recorded;
- which actor/tool signed claims;
- what provenance history is available.

It does **not** answer:

- whether the depicted event happened;
- whether the caption is truthful;
- whether the publisher is honest;
- whether missing credentials mean “fake.”

This distinction could become one of the best lessons in the entire product.

### Example lesson

Image has valid Content Credentials indicating:
- created with an AI tool;
- edits recorded;
- creator disclosed synthetic origin.

The accompanying claim is accurate.

Correct learner conclusion:
- synthetic media;
- disclosed provenance;
- claim supported;
- context accurate.

Another case:

Authentic camera image with valid provenance.
Caption says it was taken yesterday in Ukraine.
Original provenance/source shows it is a 2022 image from another country.

Correct conclusion:
- authentic media;
- false/misleading claim;
- context integrity broken.

That single contrast teaches more than a deepfake detector.


# 25. Why August 2026 is unusually strong timing for this idea in Europe

This is not generic “AI is changing the world” timing.

There is a concrete regulatory moment.

## EU AI Act Article 50 transparency obligations

European Commission:
https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content

Quick facts:
https://digital-strategy.ec.europa.eu/en/factpages/quick-facts-transparency-rules-ai-systems

Enforcement announcement:
https://digital-strategy.ec.europa.eu/en/news/commission-starts-enforcing-ai-act-rules-and-new-transparency-requirements-2-august

Guidelines:
https://digital-strategy.ec.europa.eu/en/library/guidelines-transparency-obligations-providers-and-deployers-ai-systems

Key fact:

**Article 50 transparency obligations became applicable on 2 August 2026.**

They address:
- informing users when interacting with certain AI systems;
- machine-readable marking/detection of certain AI-generated or manipulated content;
- labeling deepfakes;
- labeling certain AI-generated/manipulated text in public-interest contexts.

## Perfect product narrative

> **Europe is building the transparency layer. People still need the literacy layer.**

A label can tell you:
> “AI-generated.”

It cannot teach you:
- whether the claim is supported;
- whether the AI use is deceptive;
- whether context is accurate;
- whether the media is satire;
- whether a real photo is falsely captioned;
- whether the evidence is sufficient;
- whether to share.

This is exactly where MIL sits.

## Another current EU education signal

European Commission, March 2026:
https://digital-strategy.ec.europa.eu/en/news/commission-publishes-guidelines-support-teachers-key-digital-education-priorities

The updated digital-literacy/disinformation guidance now addresses:
- generative AI;
- disinformation;
- social-media reliance;
- influencers;
- critical thinking;
- responsible use of digital technologies.

This gives a credible future audience:
**teachers and schools**.

## European media-literacy ecosystem

European Commission policy:
https://digital-strategy.ec.europa.eu/en/policies/media-literacy

EDMO media-literacy guideline announcement:
https://digital-strategy.ec.europa.eu/en/news/european-digital-media-observatory-launches-media-literacy-guidelines

EDMO:
https://edmo.eu/

EU funding signal:
https://digital-strategy.ec.europa.eu/en/funding/call-proposals-cross-border-media-literacy

Another 2025/2026 cross-border call:
https://digital-strategy.ec.europa.eu/en/funding/call-proposals-cross-border-media-literacy

The strategic implication is not “promise EU funding.”

It is:
**the problem is institutionally recognized, current, and compatible with European education/resilience priorities.**

---

# 26. Ukraine should be a design advantage, not a marketing prop

UNESCO on current MIL work in Ukraine:
https://www.unesco.org/en/articles/unesco-strengthens-media-and-information-literacy-across-ukraine

UNESCO reports that a large 2024 MIL campaign reached more than 13 million Ukrainians, and that 2025 activities focused particularly on:
- youth;
- media professionals;
- civil servants.

Ukraine therefore has a real media-literacy ecosystem and a strong relevance to UNESCO’s work.

## Learn to Discern: Ukrainian evidence that MIL training can produce measurable effects

IREX fact sheet:
https://www.irex.org/sites/default/files/L2D%20Fact%20Sheet_Final.pdf

IREX reports:
- 15,000 adults trained in Ukraine;
- at 1.5-year follow-up, trained participants scored 13% higher on identifying disinformation;
- 25% higher on checking multiple sources;
- approximately 25% higher on understanding how media/social media affect decisions.

Long-term impact report:
https://www.irex.org/sites/default/files/node/resource/impact-study-media-literacy-ukraine.pdf

Schools pilot:
https://www.irex.org/sites/default/files/node/resource/evaluation-learn-to-discern-in-schools-ukraine.pdf

The school pilot:
- involved 50 schools;
- reached roughly 5,425 grade 8–9 students;
- later expanded toward hundreds of schools.

English curriculum:
https://www.irex.org/sites/default/files/node/resource/learn-to-discern-media-literacy-curriculum-english-2.pdf

L2D philosophy:
https://www.irex.org/sites/default/files/L2D%20Fact%20Sheet%20New%20Version%20PDF%202022%204-5.pdf

A valuable point from IREX:
media resilience is not only technical verification. It also involves:
- emotional control;
- cognitive reflection;
- empathy;
- social incentives;
- critical analysis.

This can inspire a better game than “spot the fake.”

## Ukrainian fact-checking organizations worth learning from

### VoxCheck

https://voxukraine.org/en/voxcheck

Method transparency:
https://rusdisinfo.voxukraine.org/method
https://medfakes.voxukraine.org/en/method

Strong principle:
their methodology aims to provide enough source detail that readers can reproduce verification.

That is exactly the philosophy behind an Evidence Receipt.

### StopFake

https://www.stopfake.org/en/about-us/

StopFake is rooted in the Mohyla School of Journalism / Media Reforms Centre and combines:
- fact checking;
- education;
- media literacy;
- multilingual distribution.

Potential future collaboration target, if actually contacted.

Never call an organization a partner until it agrees.

---

# 27. The strongest Ukraine narrative

Avoid:

> “Ukraine has lots of propaganda, so we made a fake-news detector.”

That is generic and risks turning lived experience into background decoration.

Better:

> **“Coming from Ukraine, we learned that the information problem is rarely just fake versus real. A real video can carry a false caption. An old image can return as breaking news. A convincing screenshot can imitate authority. A fluent AI answer can invent a source. In high-stakes environments, the valuable skill is not guessing whether something ‘looks fake’; it is knowing how to verify.”**

This is globally transferable to:

- natural disasters;
- elections;
- scams;
- health misinformation;
- emergency alerts;
- conflict;
- humanitarian aid;
- financial fraud;
- academic research;
- breaking news.

### Important ethical rule

Do not invent team trauma or personal anecdotes for the pitch.

Use only real experiences the team is comfortable sharing.

You can say:
> “Our design is informed by the Ukrainian information environment.”

Only say:
> “I personally received X fake evacuation message…”

if that actually happened and the person wants it included.

---

# 28. Crisis Verification Mode

This could become a standout Ukrainian contribution.

Most fact-checking education assumes the user has ten minutes.

Real crises often give the user 30 seconds.

## Crisis Verification Sprint

Teach a “minimum safe verification” reflex:

1. Stop.
2. Identify consequence.
3. Check the official/source channel.
4. Verify through a second independent route.
5. Check time/date/location.
6. Do not forward urgent unverified instructions.
7. If impersonation/scam: verify out-of-band.
8. Preserve uncertainty.

Example safe scenarios:

- fake school closure message;
- fake donation page;
- fake weather/emergency alert;
- impersonated university administrator;
- cloned voice asking for money;
- old disaster video reposted as current;
- fake transport disruption notice;
- manipulated humanitarian-aid announcement.

This is globally relevant and avoids needing graphic war imagery.

Potential badge:
**Calm Under Pressure**

---

# 29. Audience strategy: do not target “everyone”

UNESCO asks for a target audience.

A global product can have multiple future audiences, but a competition proposal should have one primary audience.

## Recommended primary audience

**Students and young adults, approximately 16–24 or 18–25.**

Why:
- directly fits Youth Hackathon;
- fits student Source Checker;
- heavy social-media/AI usage;
- high exposure to AI-generated research help;
- easy to pilot through universities;
- natural peer-education multiplier;
- can later adapt down/up by age.

Possible tighter version:

> **University students who use social media and generative AI for learning.**

This is especially strong because it unifies:
- news;
- social media;
- AI media;
- chatbot hallucinations;
- research sources.

---

# 30. Audience map and jobs-to-be-done

## 30.1 University students

Problems:
- AI-generated fake citations;
- weak sources in assignments;
- viral claims;
- confusing preprints vs peer-reviewed papers;
- press releases exaggerated into headlines;
- source overload.

Value:
- verify academic references;
- trace claims;
- understand evidence quality;
- learn reusable research habits.

Killer lesson:
**The AI gave you a convincing citation. Does it exist?**

---

## 30.2 High-school students

Problems:
- social-media manipulation;
- influencer advertising;
- fake giveaways/scams;
- AI images;
- copied homework sources;
- emotional content.

Value:
- foundational MIL habits;
- manipulation recognition;
- safer sharing.

Killer lesson:
**The screenshot looks official. Is it?**

---

## 30.3 Teachers

Problems:
- need current AI/disinformation material;
- examples become stale;
- limited classroom time;
- hard to assess MIL skill rather than memorization.

Value:
- ready scenario packs;
- class challenge;
- pre/post skill checks;
- discussion prompts;
- printable version.

European Commission 2026 teacher-guideline context:
https://digital-strategy.ec.europa.eu/en/news/commission-publishes-guidelines-support-teachers-key-digital-education-priorities

---

## 30.4 Parents / older adults

Problems:
- impersonation;
- AI voice scams;
- WhatsApp/Viber/Telegram forwarding;
- fake medical advice;
- urgency tactics.

Value:
- practical anti-scam verification;
- family challenge.

Interesting model:
**Reverse mentorship** — young person completes a family mission with a parent/grandparent.

This creates community impact from a youth product.

---

## 30.5 Journalists / journalism students

Problems:
- video verification;
- old footage;
- keyframes;
- reverse search;
- provenance;
- source clustering.

Value:
- training simulator;
- workflow practice;
- speed under pressure.

Open-source reference:
https://github.com/AFP-Medialab/verification-plugin

---

## 30.6 Content creators / influencers

Problems:
- accidental spread;
- unclear AI disclosure;
- sourced claims;
- correction practices;
- audience trust.

Value:
- ethical creator mini-course;
- Article 50 literacy;
- “correct transparently” skills.

---

## 30.7 Displaced / crisis-affected communities

Problems:
- urgent information;
- scams;
- local-language access;
- unstable connectivity;
- impersonation;
- fake aid information.

Value:
- low-data mode concept;
- offline/print packs;
- crisis-verification reflex.

This could strengthen Inclusion.

---

## 30.8 Libraries

Problems:
- patrons asking source-quality questions;
- student research;
- AI-assisted research confusion.

Value:
- Source Checker workshops;
- printable investigation packs.

---

## 30.9 Youth organizations / NGOs

Problems:
- need localized MIL activities;
- need ready content;
- limited technical resources.

Value:
- community challenge packs;
- facilitator guide;
- reusable scenarios;
- youth ambassador program.

---

## 30.10 Fact-checkers

They should **not** be positioned as people the app replaces.

Potential role:
- trusted content partners;
- source methodology advisers;
- scenario validators;
- educators.

That framing respects the profession and is more credible.

---

# 31. The “MIL Passport”

Instead of treating XP as the only progress system, create a competency identity.

Possible skills:

- Source
- Evidence
- Context
- Search
- Provenance
- AI
- Manipulation
- Academic Sources
- Statistics
- Crisis Verification
- Share Decisions
- Calibration

A learner could be:

- Level 4 Source Tracer
- Level 2 Provenance Reader
- Level 5 Context Detective
- Level 3 Citation Verifier

This gives richer motivation than one global number.

Potential name:
**MIL Passport**

Possible final showcase:
> “You completed the Intro Investigator Path and demonstrated transfer across 5 unseen cases.”

Do not promise an accredited credential unless an institution validates it.

---

# 32. Gamification ideas that teach instead of distract

Keep:
- XP;
- streak;
- levels;
- achievements;
- daily challenges.

But change what they mean.

## 32.1 XP for process

Reward:
- good evidence actions;
- finding original source;
- corroboration;
- correct uncertainty;
- updating belief.

## 32.2 Skill-specific levels

Do not only say:
> “Level 12.”

Say:
> “Context Detective Level 4.”

## 32.3 Non-punitive streak

Avoid shame.

Use:
- streak freeze;
- weekly consistency;
- recovery challenges.

The educational goal is return, not addiction.

## 32.4 Achievements

Ideas:

- **Source Hunter** — verify 10 primary sources.
- **Context Detective** — catch 10 out-of-context items.
- **Citation Rescuer** — identify 5 fabricated or misrepresented references.
- **Independent Thinker** — find independent corroboration 10 times.
- **Correction Catcher** — find a correction/retraction.
- **Provenance Pro** — interpret 10 Content Credentials.
- **Changed My Mind** — update a conclusion after stronger evidence.
- **Know When You Don’t Know** — correctly select insufficient evidence.
- **Calm Before Share** — avoid sharing 10 unresolved high-stakes claims.
- **No Screenshot Taken for Granted** — trace 10 screenshots to originals.
- **Syndication Spotter** — notice copied reporting.
- **Primary Source First** — reach original document.
- **Manipulation Mechanic** — recognize 20 tactics.
- **Bias Check** — recognize your first impression was influenced by framing.
- **Evidence Over Ego** — reverse a high-confidence first impression.
- **Article Archaeologist** — find the earliest version.
- **Research Rabbit** — trace news → press release → paper.
- **Retraction Ranger** — identify retracted/updated work.
- **Signal in the Noise** — correctly ignore irrelevant evidence.
- **Crisis Calm** — complete a timed emergency-verification case.

## 32.5 Daily challenge as booster

Daily challenge should often be:
- 60–90 seconds;
- one manipulation technique;
- one evidence action.

Weekly challenge:
- deeper investigation.

## 32.6 No political truth leaderboard

Avoid:
> “Top 100 users at identifying misinformation.”

This can reward:
- speed;
- overconfidence;
- ideological competition.

Prefer:
- skill mastery;
- team learning;
- class progress;
- community missions.

---

# 33. “Attention is a resource” mechanic

A non-trivial concept.

Every investigation can have limited **attention tokens**.

The learner cannot inspect everything.

They must decide what evidence is most diagnostic.

Example choices:

- inspect font quality;
- read comments;
- find original source;
- reverse search;
- search author.

The optimal action is often:
**leave the page and find independent information.**

This turns “critical ignoring” into gameplay.

It also reflects real life:
nobody can deeply fact-check every post.

---

# 34. Critical Ignoring

A modern MIL skill is not only evaluating information.

It is knowing when not to give low-quality content more attention.

Possible game outcomes:
- investigate;
- ignore;
- block/report scam;
- do not amplify;
- save for later verification.

Lesson:
engagement itself can reward manipulation.

Potential achievement:
**Attention Guardian**

This is especially useful for:
- ragebait;
- engagement bait;
- trolling;
- obvious low-value claims.

---

# 35. Manipulation Technique Library

Potential techniques to teach:

1. Emotional manipulation
2. Fear
3. Anger
4. Moral outrage
5. Urgency
6. Scarcity
7. False dilemma
8. Scapegoating
9. Ad hominem
10. Straw man
11. Conspiracy framing
12. “They don’t want you to know”
13. Fake expertise
14. Authority mimicry
15. Impersonation
16. Fake consensus
17. Cherry-picking
18. Misleading statistics
19. Decontextualization
20. Cropped context
21. False causality
22. Anecdote as evidence
23. Quote mining
24. Fake quotation
25. Headline exaggeration
26. Source laundering
27. Citation laundering
28. Synthetic amplification
29. Bot-like amplification
30. Engagement bait
31. Sponsored content disguised as organic
32. Influencer conflict of interest
33. Astroturfing
34. False balance
35. Appeal to popularity
36. Appeal to nature
37. “Just asking questions”
38. Moving goalposts
39. Gish gallop / claim flooding
40. AI-generated authority tone
41. Fake academic precision
42. fabricated DOI/reference
43. fake screenshot
44. old media as new
45. wrong-location media
46. manipulated subtitle/translation
47. deepfake impersonation
48. real clip with misleading edit
49. selective omission
50. context collapse.

Do not teach every label immediately.

Use a small beginner taxonomy and reveal advanced labels later.

---

# 36. Prebunk Arena / Safe Adversarial Mode

Research shows active inoculation can work: learners sometimes become the manipulator in a fictional environment to recognize techniques.

Possible safe mode:

The user must create a fictional viral post using:
- urgency;
- emotional language;
- false dilemma.

Then:
- the game identifies each technique;
- explains why it works;
- shows how to resist it.

Important safety constraint:
- fictional people/places;
- no real target;
- no instructions for real harassment or election manipulation;
- debrief every adversarial exercise.

This is about **recognition**, not operational disinformation training.

---

# 37. Feed Lab: learn incentives, not only content

A deeper mode inspired by social-media simulation.

The player sees a fictional feed.

Metrics:
- reach;
- credibility;
- engagement;
- trust.

Possible role:
- content editor;
- creator;
- community moderator;
- journalist.

Choices have tradeoffs.

Example:

Option A:
accurate but boring headline.

Option B:
emotionally loaded headline with more engagement.

The game demonstrates:
- business incentives;
- virality;
- clickbait;
- why false content can spread without a centralized conspiracy.

This aligns with CLICKBAIT’s 3C2B framework, especially **Business**.

---

# 38. Investigator vs Disinformer / Influencer mode

Potential multiplayer or asynchronous concept.

One player:
- constructs a fictional misleading message from permitted tactics.

Another:
- investigates.

Alternative:
one is “Influencer,” one “Journalist.”

Research inspiration:
Breaking the News:
https://recfro.github.io/breaking-the-news/
https://github.com/Woaichichangfen/BreakingTheNews

Exact Unity repository areas to inspect later if studying mechanics:
- `Assets/`
- `Assets/Scripts/`
- `Assets/Scenes/`
- `Packages/`
- `ProjectSettings/`

**Do not port the Unity project.**
Borrow the role tension and adversarial learning idea.

Potential post-hackathon feature, not priority.

---

# 39. Hybrid physical + digital missions

Past UNESCO winners strongly validate hybrid learning.

Easy concept:

Each class/community session gets:
- printed evidence cards;
- QR links;
- source cards;
- claim cards;
- role cards.

Teams race to build an Evidence Receipt.

This demonstrates:
- low-bandwidth support;
- classroom usability;
- community impact;
- accessibility;
- sustainability.

It can exist as a concept/mockup without major engineering.

---

# 40. Family Challenge

One of the easiest community-impact multipliers.

Mission examples:

- verify a suspicious family-group message together;
- teach reverse image search;
- identify urgency in a scam;
- check an AI voice request using another channel;
- inspect a medical claim together.

Young learner becomes peer/family educator.

This echoes the “multiplier” logic of successful MIL programs.

---

# 41. Teacher Mode concepts

Do not build a huge LMS.

Useful future concept:

- classroom code;
- scenario assignment;
- group debate;
- anonymous aggregate skill results;
- pre/post transfer quiz;
- printable version;
- teacher discussion guide;
- “why this case matters” note;
- source packet.

Teachers should see:
- skill difficulty;
- misconception;
- evidence steps students skipped.

Not:
- political profiling;
- ideology labels;
- invasive personal analytics.

---

# 42. Community / NGO scenario packs

A sustainability mechanism.

A “pack” can represent:

- local scams;
- climate misinformation;
- health claims;
- election process literacy;
- humanitarian information;
- academic sources;
- influencer advertising;
- deepfakes;
- local-language media.

Content can be produced by:
- educators;
- libraries;
- youth organizations;
- fact-checkers;
- university researchers.

A review process matters.

Potential metadata:
- audience;
- language;
- topic;
- target skills;
- verified sources;
- review date;
- expiry/review date;
- content warnings;
- accessibility assets.

This is not architecture.
It is a scalable content model.

---

# 43. Content needs versioning because “truth” changes

A lesson about:
> “Is this event happening?”

can become stale.

Every real-world case should conceptually have:

- source packet;
- verification date;
- review date;
- time-sensitive flag;
- correction history.

Potential UX wording:

> “Evidence status verified on 9 August 2026.”

This teaches users that evidence is temporal.

It also protects the project from stale cases.

---

# 44. Living cases and user corrections

Advanced sustainability idea:

A user or partner can say:
> “This source was corrected.”
> “A new primary document appeared.”
> “This paper was retracted.”

Then a reviewed case can evolve.

Educational opportunity:
users learn that responsible information systems correct themselves.

Possible achievement:
**Correction Culture**

---

# 45. Teach that correction is not failure

A common misconception:

> “This newspaper corrected a story, therefore it cannot be trusted.”

Better lesson:
transparent correction can be a positive accountability signal.

Scenario:
- Source A corrects an error visibly.
- Source B silently deletes.
- Source C never updates.

Ask:
> “Which behavior demonstrates stronger accountability?”

This is richer than source blacklists.

---

# 46. Never use one universal source credibility score

Avoid:
> “BBC: 92/100 trustworthy.”
> “Blog: 41/100.”

Why:
- source quality is context-dependent;
- good institutions make errors;
- weak institutions may cite a true primary source;
- users need reasoning, not outsourced authority;
- ideological trust conflicts can dominate.

Better show attributes:

- source type;
- ownership;
- author;
- evidence;
- transparency;
- correction policy;
- primary/secondary;
- corroboration;
- relevant expertise;
- conflicts/incentives.

Let users form a conclusion.

---

# 47. “Blog vs paper” should be nuanced

Your initial Source Checker example says:

> “This is a blog, not a scientific article — check the original research.”

Good.

But do not teach:

> “Blog = bad.”

Better:

> “This is a secondary summary. For the scientific claim, trace it to the original study.”

A blog can:
- accurately explain a paper;
- provide expertise;
- be more current.

A peer-reviewed paper can:
- contain weak evidence;
- be misinterpreted;
- be retracted;
- become outdated.

The skill is **source role**, not source caste.

---

# 48. AI & Chatbot category: this can be much larger than hallucinations

Potential sub-lessons:

1. Fabricated citation
2. Real citation with wrong title
3. Real paper misquoted
4. Confident answer with no evidence
5. Stale knowledge
6. Fake current event
7. AI summarizes search snippet instead of source
8. AI confuses two people
9. AI invents statistics
10. AI gives unsupported legal/medical authority
11. AI collapses uncertainty
12. AI repeats bias from prompt
13. AI cites secondary source as primary
14. AI says “research shows” without identifying research
15. AI gives an answer that is technically true but out of date
16. AI produces a plausible fake journal
17. AI interprets a chart incorrectly
18. AI invents a quote
19. AI claims consensus from one study
20. AI confuses correlation and causation.

Possible level name:
**Hallucination Arena**

---

# 49. The Citation Hunt mini-game

User sees an AI answer:

> “According to Miller et al. (2025), students who use AI tutors improve media literacy by 47%…”

Tasks:
1. search title;
2. search DOI;
3. find author;
4. determine if paper exists;
5. if it exists, inspect abstract;
6. find actual measured outcome;
7. decide whether the citation supports the claim.

This is perfect for university students.

Possible score:
- existence;
- metadata match;
- support;
- current status.

---

# 50. News & Articles category — advanced lesson bank

Possible missions:

1. Headline stronger than article.
2. Article stronger than source.
3. Press release stronger than paper.
4. Study is a preprint.
5. Tiny sample generalized to population.
6. Correlation presented as causation.
7. Relative risk without absolute risk.
8. “Scientists say” with no names.
9. Named expert outside expertise.
10. Old study described as new.
11. Retraction ignored.
12. Study is real but does not support conclusion.
13. Multiple articles all copy one wire source.
14. Anonymous “officials say.”
15. Opinion article presented as reporting.
16. Sponsored/native content.
17. Chart uses truncated axis.
18. Data range cherry-picked.
19. Survey framing hides sample.
20. Percent vs percentage-point confusion.
21. Screenshot of headline with no link.
22. Article changed after screenshot.
23. Archived page reveals original wording.
24. Translation removes qualifier.
25. Quote taken from a longer answer.
26. Breaking-news uncertainty evolves.
27. Correction updates story.
28. Rumor spreads before official confirmation.
29. “Experts divided” false balance.
30. Article cites another media report rather than source.

---

# 51. Social Media category — advanced lesson bank

1. Fake verified-looking account.
2. Username differs by one character.
3. Screenshot with no original.
4. Old photo recirculated.
5. Meme converts claim into joke.
6. Influencer undisclosed advertising.
7. Affiliate incentive.
8. Viral giveaway scam.
9. Urgent fundraiser impersonation.
10. Engagement bait.
11. Bot-like reply consensus.
12. Hashtag manipulation.
13. Cropped quote.
14. Deleted context.
15. Community Note/fact-check is present but misunderstood.
16. Comment count used as truth.
17. “Everyone is talking about this” false consensus.
18. Source link is shortened/redirected.
19. Fake news-site visual clone.
20. Handle history/change.
21. Synthetic profile photo but legitimate satirical account.
22. Real person clip with misleading subtitle.
23. Reel cuts before qualification.
24. TikTok explanation cites no source.
25. “Doctor” credential cannot be verified.
26. Screenshot metadata claim is impossible to confirm.
27. Genuine account was compromised.
28. AI-written spam network.
29. Scam uses a celebrity image.
30. Real image used in fake event promotion.

---

# 52. AI Images & Video category — advanced lesson bank

Do not ask only:
> “Is this AI?”

Ask:
> “What do we know, what can we verify, and does authenticity matter to this claim?”

Scenario types:

1. Obvious generation artifacts.
2. Photorealistic synthetic image.
3. AI-generated but clearly labeled ad.
4. AI illustration used ethically.
5. Real image falsely accused of being AI.
6. Real image with wrong caption.
7. AI image claiming to document a real event.
8. Composite image.
9. Face swap.
10. Lip-sync manipulation.
11. Edited subtitle.
12. Voice clone.
13. Real video selectively clipped.
14. Old video as current.
15. C2PA credentials present.
16. C2PA credentials absent.
17. Valid provenance but misleading caption.
18. Screenshot strips provenance.
19. Platform compression breaks detector confidence.
20. Cropped image changes detector output.
21. Multiple detectors disagree.
22. Source account discloses generation.
23. Reverse search finds original synthetic artist post.
24. Visual anomalies suggest but do not prove synthesis.
25. Satirical deepfake.
26. Artistic remix.
27. Synthetic witness evidence.
28. AI avatar in customer support.
29. AI politician parody clearly labeled.
30. manipulated disaster imagery.

---

# 53. Context is often more important than generation

This can be your best recurring “aha” moment.

Teach these four cases:

| Media | Claim | Context | Lesson |
|---|---|---|---|
| Real | True | Correct | ordinary trustworthy use |
| Real | False | Wrong | authenticity does not guarantee truth |
| Synthetic | True | Disclosed | synthetic does not equal misinformation |
| Synthetic | False | Deceptive | authenticity + claim both matter |

Add:
- Unknown authenticity + strong independent evidence.
- Known authenticity + weak claim evidence.

This is conceptually advanced but easy to demonstrate.

---

# 54. Audio / voice cloning module

Current fraud risk makes this useful.

Do not turn it into voice biometric identification.

Teach:
- urgency;
- impersonation;
- unusual payment request;
- caller-ID spoofing;
- out-of-band verification.

Core anti-scam behavior:

> “End the call. Contact the person using a known number or another trusted channel.”

Potential family challenge.

Potential crisis use.

---

# 55. Search literacy should be a visible skill

Users increasingly use search and AI summaries without understanding how to search well.

Teach:
- exact quote search;
- source name + claim;
- reverse image search;
- date filters;
- alternate wording;
- original uploader;
- domain-restricted search;
- paper title;
- DOI;
- author name;
- correction/retraction;
- earliest occurrence.

Also teach:
- search snippet ≠ source;
- top result ≠ best result;
- SEO rank ≠ evidence;
- multiple copied results ≠ independent confirmation.

Possible achievement:
**Query Crafter**

---

# 56. The “First Occurrence” challenge

A viral post says:
> “Breaking.”

User must find:
- earliest upload;
- original source;
- original date.

This is highly practical and satisfying.

Potential scenario:
a 2023 flood video shared as a 2026 event.

The educational point:
**repetition can erase provenance.**

---

# 57. Screenshot ≠ source

A signature beginner lesson.

Show a plausible screenshot.

Ask:
- Who posted this?
- Where is the original?
- Is the screenshot current?
- Can the wording be found?
- Was it edited?
- Does the account exist?

The screenshot may be:
- authentic;
- outdated;
- edited;
- fabricated;
- missing context.

Teach:
> “A screenshot is evidence of what someone wants you to see, not automatically evidence of the original publication.”

---

# 58. “Five articles” ≠ five independent sources

A fantastic intermediate lesson.

Show:
- five websites;
- all cite Reuters / one press release / one anonymous Telegram post.

User initially thinks:
> “Five confirmations.”

Investigation reveals:
> “One source copied five times.”

Skill:
**Source Independence**

Possible achievement:
**Echo Chamber Mapper**

---

# 59. Statistics literacy mini-levels

MIL increasingly requires basic quantitative literacy.

Possible lessons:

- 50% increase from 2 to 3 vs “half again as likely”;
- relative vs absolute risk;
- percent vs percentage points;
- mean vs median;
- misleading axis;
- cherry-picked dates;
- sample size;
- selection bias;
- survey wording;
- confidence interval;
- “statistically significant” ≠ important;
- anecdote ≠ rate;
- base-rate neglect.

Avoid turning the app into a statistics course.

Use tiny high-impact examples.

---

# 60. Chart / graph manipulation

Possible game:

User sees two charts with same data:
- honest scale;
- truncated scale.

Ask:
> “Which visual creates a stronger impression?”

Then:
> “What changed: the data or the framing?”

This teaches manipulation without any political content.

---

# 61. “What would change your mind?”

Before the final reveal, ask:

> “What evidence would change your conclusion?”

This is a strong metacognitive tool.

It helps users notice:
- unfalsifiable beliefs;
- motivated reasoning;
- moving goalposts.

Use occasionally, not every lesson.

---

# 62. Emotional state as part of MIL

IREX’s Learn to Discern explicitly includes emotional control and cognitive reflection.

A useful game mechanic:

Before investigation:
> “What did this post make you feel?”

Optional:
- angry;
- afraid;
- excited;
- validated;
- amused;
- urgent;
- neutral.

Then:
> “Would you have shared it immediately?”

After verification:
> “Did emotion affect your first confidence?”

Do not psychoanalyze the user.

The lesson is:
**strong emotion can be a cue to slow down.**

---

# 63. “Pause trigger” training

Teach a tiny mnemonic:

**PAUSE**
- **P** — Pin down the claim
- **A** — Ask who is behind it
- **U** — Uncover original evidence
- **S** — Seek independent context
- **E** — Estimate uncertainty

Or create another acronym later.

The exact acronym matters less than memorability.

A portable heuristic helps the skill leave the app.

---

# 64. Share decision is not the same as truth decision

A claim can be:
- probably true;
- not important;
- private;
- harmful to amplify;
- uncertain;
- needing context.

Possible final action:

- Share
- Share with context
- Save / verify later
- Do not share

This teaches responsibility rather than censorship.

---

# 65. “Insufficient evidence” as a first-class answer

One of the most important ideas in the dossier.

The internet rewards certainty.

The game should reward justified uncertainty.

Examples:
- breaking news;
- anonymous source;
- provenance missing;
- contradictory evidence;
- claim not yet independently confirmed.

Possible high-value feedback:

> “Correct. The best conclusion right now is not ‘true’ or ‘false’; it is ‘not enough evidence yet.’”

That is real MIL.

---

# 66. Responsible correction / update mechanic

Later in a lesson, new evidence appears.

User gets a notification:

> “New evidence is available. Reopen your conclusion?”

The goal is not to punish prior uncertainty.

It teaches:
- beliefs can change;
- responsible people update;
- breaking news evolves.

Potential achievement:
**Good Faith Update**

---

# 67. Scenario difficulty should depend on reasoning, not ideology

Avoid creating “easy = obvious fake, hard = controversial politics.”

Difficulty can be:

### Easy
- direct primary source;
- obvious date mismatch.

### Medium
- multiple copied sources;
- misleading crop;
- real paper misquoted.

### Hard
- mixed evidence;
- real media + wrong context;
- sources disagree;
- provenance available but claim separate;
- partially supported headline.

This reduces partisan conflict and improves transfer.

---

# 68. Cross-category capstone

A brilliant final lesson can combine everything:

A viral social post says:
> “New university study proves X.”

It contains:
- AI-generated chart;
- screenshot of news article;
- article quotes press release;
- press release links paper;
- paper is a preprint;
- claim exaggerates result;
- chart is synthetic but disclosed in original;
- social-media repost removed disclosure;
- five sites copy one press release.

The player must:
- trace source;
- verify paper;
- understand source type;
- check context;
- separate authenticity from claim truth;
- make share decision.

This demonstrates the whole product in one case.

---

# 69. Source Checker output: recommended conceptual structure

Avoid:
> “Credibility score: 72%.”

Better structured output:

## Identity
- publisher;
- author;
- organization;
- source type.

## Time
- publication date;
- update date;
- event date if relevant.

## Evidence
- primary sources;
- cited research;
- direct vs indirect evidence;
- data availability.

## Academic status
- DOI;
- peer-reviewed/preprint;
- correction/retraction status.

## Corroboration
- independent sources;
- source dependency.

## Language / framing
- emotionally loaded language;
- unsupported certainty;
- manipulation techniques.

## Provenance
- Content Credentials where available;
- origin information;
- limitations.

## Uncertainty
- missing evidence;
- contradictory evidence;
- unresolved questions.

## Next best action
One or two concrete verification actions.

That is far more useful to students than a verdict.


# 70. Time-saving reference projects: what already exists and exactly what to inspect

This section directly answers:

> “If a similar project or method already exists, what repository and what exact file should we take/inspect first?”

Important rule:

**Inspect/reuse according to each project’s license. Do not blindly copy code, datasets, or media.**

For the hackathon, the biggest time savings come from reusing:
- educational frameworks;
- content schemas;
- standards;
- public APIs;
- pretrained research tools;
- evaluation ideas.

Not from merging giant codebases.

---

# 71. The Misinformation Game — highest-value content-authoring reference

Repository:
https://github.com/TheMisinformationGame/MisinformationGame

Documentation:
https://misinfogame.com/

Research:
https://link.springer.com/article/10.3758/s13428-023-02153-x

This is a configurable social-media simulator designed for misinformation research.

Useful capabilities include:
- configurable feeds;
- fake posts;
- comments/reactions;
- study intro/debrief;
- interaction logging;
- participant privacy features;
- dynamic follower/credibility mechanics;
- spreadsheet-driven configuration.

## Exact files to inspect first

From the documentation/repository ecosystem:

- `docs/StudyConfiguration.md`
- `docs/StudyTemplate-V1.xlsx`
- `docs/StudyTemplate-V2.xlsx`
- `docs/ExampleStudy-V2-Feed.xlsx`
- `docs/Simulation.md`
- `docs/Results.md`
- `docs/HowToPlay.md`
- `docs/TechnicalOverview.md`

Direct template:
https://misinfogame.com/StudyTemplate-V2.xlsx

Study configuration:
https://misinfogame.com/StudyConfiguration

## Highest-value thing to take conceptually

**The spreadsheet-driven scenario definition approach.**

Why:
- content authors do not need to touch application logic;
- researchers/teachers can define posts and rules;
- it separates “content pack” from “game code”;
- it is ideal inspiration for fast scenario production.

For your project, do **not** clone their React experience and turn it into your app.

Instead inspect:
- which fields a study/post/scenario needs;
- how debrief content is represented;
- how interaction data can support research.

This can save days of inventing a content format.

---

# 72. AFP Medialab InVID-WeVerify-vera.ai Verification Plugin — highest-value verification workflow reference

Active repository:
https://github.com/AFP-Medialab/verification-plugin

README:
https://github.com/AFP-Medialab/verification-plugin/blob/master/README.md

AFP:
https://www.afp.com/en/medialab
https://www.afp.com/en/invid

This plugin is described as a verification “Swiss army knife” for journalists/fact-checkers.

It evolved through:
- InVID;
- WeVerify;
- vera.ai.

The current toolkit includes workflows around:
- contextual information;
- reverse-image search;
- video keyframes;
- magnification;
- metadata;
- forensic analysis;
- social content verification.

## Exact paths to inspect

Start with:
- `README.md`
- `src/`
- `tests/`
- `tests-assets/`
- `CLAUDE.md`

Do not start by copying code.

First extract a **verification workflow taxonomy** from the README:

1. URL/context
2. original source
3. keyframes
4. reverse search
5. metadata
6. image forensics
7. triangulation

## Why this saves time

You do not need to invent “what professional verification steps exist.”

Journalist-grade tooling has already organized the space.

Your value is:
**turning those steps into learning behavior for non-experts.**

---

# 73. C2PA / Content Authenticity Initiative — do not invent provenance

Active Rust SDK:
https://github.com/contentauth/c2pa-rs

Active JS monorepo:
https://github.com/contentauth/c2pa-js

Specification:
https://spec.c2pa.org/specifications/specifications/2.4/index.html

## Exact files

`c2pa-rs`:
- `cli/README.md`
- `cli/docs/usage.md`
- `cli/sample/`
- `README.md`

`c2pa-js`:
- `README.md`
- `packages/c2pa-web/`
- `packages/c2pa-node/`

Important historical note:
https://github.com/contentauth/c2patool

The standalone `c2patool` repository is archived/moved; the current work lives in `c2pa-rs`.

Likewise, older Node repositories point to the active `c2pa-js` monorepo.

## What to take

- terminology;
- user-facing provenance concepts;
- sample media/manifest structure if licensing permits;
- current validation semantics.

Do not create your own “blockchain truth standard.”

---

# 74. FIRE — highest-value fact-checking process/cost shortcut

Repository:
https://github.com/mbzuai-nlp/fire

Paper:
https://arxiv.org/abs/2411.00784
https://aclanthology.org/2025.findings-naacl.158/

## Exact paths

- `README.md`
- `eval/fire/`
- `evaluator.ipynb`
- `common/`
- `datasets/`

## What to take

The algorithmic decision principle:

> **Only retrieve more evidence when the current evidence is insufficient.**

This can influence:
- LLM cost;
- search cost;
- user experience;
- educational behavior.

The reported cost reductions make this especially attractive for a hackathon prototype that might otherwise burn search/LLM calls unnecessarily.

---

# 75. OpenFactCheck — evaluate factuality modules rather than inventing evaluation

Repository:
https://github.com/mbzuai-nlp/openfactcheck

Paper:
https://arxiv.org/abs/2408.11832

The framework separates:
- response factuality evaluation;
- LLM evaluation;
- fact-checker evaluation.

## Inspect first

- `README.md`
- package/module documentation linked by README
- evaluation examples

## What to take

Not the user-facing answer.

Take the **evaluation decomposition**:
- claim;
- evidence;
- checker;
- metrics.

Useful for later testing your AI coach.

---

# 76. ProgramFC — complex claim decomposition reference

Repository:
https://github.com/mbzuai-nlp/ProgramFC

Paper:
https://arxiv.org/abs/2305.12744

## Inspect first

- `README.md`
- task/program examples
- datasets/evaluation directories documented by repo

## What to take

The idea that a complex real-world claim can be decomposed into smaller verifiable subproblems.

For your product:
LLM decomposition should support the learner, not hide the reasoning process behind an automated verdict.

---

# 77. FSRS — do not invent the spaced repetition algorithm

Main research/community:
https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler
https://open-spaced-repetition.github.io/

Dart:
https://github.com/open-spaced-repetition/dart-fsrs

## Exact Dart paths

- `README.md`
- `lib/`
- `example/`
- `test/`
- `pubspec.yaml`

## What to take

Modern scheduling semantics:
- difficulty;
- stability;
- retrievability;
- adaptive review timing.

Product adaptation:
review **skills in new contexts**, not duplicate questions.

---

# 78. DeepfakeBench — benchmark, not a feature list

Repository:
https://github.com/SCLBD/DeepfakeBench

## Exact paths

- `README.md`
- `training/test.py`
- `training/train.py`
- `training/config/`
- `training/detectors/`
- `training/metrics/`
- `preprocessing/`

## What to take

- benchmark methodology;
- detector taxonomy;
- testing mindset;
- pretrained baselines if license/requirements fit.

Do not:
- make your proposal depend on training;
- use in-distribution accuracy as proof of universal detection.

---

# 79. NTIRE 2026 DeepFake Detection — current robustness reality check

Repository:
https://github.com/msu-video-group/NTIRE-2026-DeepFake-Detection

First file:
- `README.md`

Why it matters:

The challenge explicitly tests real vs AI-generated images under:
- crops;
- resizing;
- compression;
- blur;
- in-the-wild transformations;
- unseen generators.

What to take:

**Your detector-evaluation philosophy.**

Any detector demonstration should be framed with:
- uncertainty;
- robustness limitations;
- generalization limitations.

---

# 80. WaRPAD — possible training-free experimental clue

Repository:
https://github.com/sungikchoi/WaRPAD

Exact:
- `README.md`
- `final_imgn.py`
- `utils.py`
- `roc_tpr.py`
- `requirements.txt`

What to take:
- fast experimental reference;
- robustness/cropping concept.

Priority:
optional.

---

# 81. UniGenDet — frontier reference, probably not hackathon dependency

Repository:
https://github.com/Zhangyr2022/UniGenDet

Exact:
- `README.md`
- `demo.py`
- `eval/`
- `modeling/`
- `pretrained/`
- `scripts/`
- `train/`

What to take:
- state-of-the-art framing;
- generator/detector co-evolution insight.

Why not core:
heavy multimodal research pipeline and pretrained components are unnecessary for the educational thesis.

---

# 82. GenImage — AI-generated image benchmark/data reference

Repository:
https://github.com/GenImage-Dataset/GenImage

Useful paths:
- `Readme.md`
- `detector_codes/`
- `generator_codes/`
- `Examples/`

Use:
- benchmark examples;
- compare generator families;
- demonstrate that “AI images” are not one distribution.

Do not:
- import massive data without checking license/storage/time.

---

# 83. UniversalFakeDetect — baseline reference

Repository:
https://github.com/WisconsinAIVision/UniversalFakeDetect

Useful files from the public repository:
- `validate.py`
- `dataset_paths.py`
- `networks/`
- pretrained weights documented by repo

Use:
- baseline/evaluation reference only if detector experimentation becomes necessary.

---

# 84. More current detection reading

Useful research/repositories:

### IAPL — CVPR 2026
https://github.com/liyih/IAPL

### GenD — WACV 2026
https://github.com/yermandy/GenD

### PRADA — CVPR Findings 2026
https://github.com/jonasricker/prada

Useful first file:
- `predict.py`

### Curated AIGC image detection list
https://github.com/yjtlab/awesome-aigc-image-detection

### Broader AIGC image/video list
https://github.com/ant-research/Awesome-AIGC-Image-Video-Detection

### AI-generated video detection reading
https://github.com/chenhaoxing/Awesome-AI-Generated-Video-Detection

These should be used for **research discovery**, not to add 20 detectors to the MVP.

---

# 85. S-HARM — important conceptual dataset: synthetic ≠ malicious

Repository:
https://github.com/Qedrigord/SHARM

Use:
- inspect `README.md`;
- inspect dataset annotation structure and licensing.

The dataset/research direction distinguishes synthetic image-text content by intent categories such as:
- humor;
- satire;
- art;
- misinformation.

This is strategically important because your product can teach:

> **Synthetic origin and harmful intent are different variables.**

That is a rare, modern, intellectually strong message.

---

# 86. TrueFake — real-world social-media robustness reference

Repository:
https://github.com/MMLab-unitn/TrueFake-IJCNN25

Use:
- inspect README;
- inspect dataset description/samples;
- check license before using media.

Value:
real-world/compressed social-media AI imagery is more relevant than pristine benchmark images.

---

# 87. The Misinformation Game vs your project

Do not become:
> “another simulated social feed.”

Borrow:
- configurable content;
- behavioral logging;
- debrief structure;
- authoring schema.

Your unique layer:
- evidence actions;
- Source Checker;
- AI coach;
- 3-axis judgment;
- provenance;
- academic sources;
- confidence calibration.

---

# 88. Breaking the News vs your project

Project:
https://recfro.github.io/breaking-the-news/

GitHub:
https://github.com/Woaichichangfen/BreakingTheNews

Borrow:
- adversarial role;
- influencer vs journalist tension;
- dynamic narrative.

Do not copy:
- Unity implementation;
- public-opinion LLM complexity for MVP.

Potential post-hackathon:
peer challenge mode.

---

# 89. OASIS / agentic social simulation: future research, not MVP

Repository:
https://github.com/camel-ai/oasis

Another social-agent benchmark:
https://github.com/LivXue/SoMe

Curated list:
https://github.com/tamlhp/awesome-sns

Possible research direction:
simulate how a claim spreads under:
- emotional framing;
- source authority;
- correction;
- disclosure.

Useful for future research/education.

Not required to impress the 2026 jury.

---

# 90. PapersWithCode: how to use the site the user provided

Discovery:
https://paperswithcode.co/

Older indexed task pages may also exist at:
https://paperswithcode.com/task/deepfake-detection/latest

Use PapersWithCode as:
- paper discovery;
- benchmark discovery;
- repository discovery.

Do **not** treat a leaderboard as proof that a detector will work in your product.

For every interesting result:

1. Open the original paper.
2. Open the author’s official repository.
3. Check publication date.
4. Check dataset.
5. Check whether the test includes unseen generators.
6. Check post-processing robustness.
7. Check license.
8. Check compute.
9. Check whether the repository still runs.
10. Check whether the task actually matches your content.

In 2026, deepfake/AIGC detection moves too quickly to rely on a single static leaderboard.

---

# 91. Time-saving priority ranking

If the team has limited time, use external work in this order.

## Tier 1 — absolutely worth borrowing

### Stanford COR
Borrow:
- lateral reading;
- question structure.

https://cor.stanford.edu/

### The Misinformation Game
Borrow:
- scenario-authoring concepts.

https://github.com/TheMisinformationGame/MisinformationGame

### OpenAlex / Crossref / Semantic Scholar
Borrow:
- scholarly metadata.

https://developers.openalex.org/
https://www.crossref.org/documentation/retrieve-metadata/rest-api/
https://api.semanticscholar.org/api-docs/

### Google Fact Check Tools API
Borrow:
- existing fact-check index.

https://developers.google.com/fact-check/tools/api/

### C2PA
Borrow:
- provenance standard.

https://github.com/contentauth/c2pa-rs
https://github.com/contentauth/c2pa-js

### FIRE
Borrow:
- iterative, cost-aware search principle.

https://github.com/mbzuai-nlp/fire

### FSRS
Borrow:
- spaced review scheduling.

https://github.com/open-spaced-repetition/dart-fsrs

---

## Tier 2 — excellent if it strengthens the demo

### AFP Verification Plugin
Borrow:
- professional media-verification workflow.

https://github.com/AFP-Medialab/verification-plugin

### Crossref Retraction Watch
Borrow:
- retraction status.

https://www.crossref.org/documentation/retrieve-metadata/retraction-watch/

### DeepfakeBench / NTIRE
Borrow:
- detector limitations and evaluation.

https://github.com/SCLBD/DeepfakeBench
https://github.com/msu-video-group/NTIRE-2026-DeepFake-Detection

---

## Tier 3 — research / optional

- WaRPAD
- UniGenDet
- GenD
- IAPL
- PRADA
- OASIS
- social-agent simulations
- complex multimodal detector ensembles

These are interesting, but they should not steal time from the learning loop.

---

# 92. What absolutely should NOT be built from scratch

To save time:

Do not build:
- a web search engine;
- a scholarly metadata database;
- a fact-check database;
- a provenance standard;
- a spaced repetition algorithm;
- a reverse-image search engine;
- a custom deepfake foundation model;
- a global source reputation index;
- a giant LLM agent framework;
- a social network simulator for the MVP;
- a blockchain truth ledger.

The team should spend its unique effort on:

**the learner experience, verified scenarios, explanation quality, evaluation, and pitch.**

---

# 93. A “Case Factory” to save content-authoring time

Conceptual content workflow:

Start with one **verified source packet**.

Example source packet:
- original article;
- primary study;
- fact check;
- original image;
- date/context;
- correction status.

From it, create multiple learning variants:

1. Accurate summary.
2. Exaggerated headline.
3. Wrong date.
4. Wrong location.
5. Cropped screenshot.
6. Fake quote.
7. Synthetic illustration.
8. AI summary with fake citation.
9. One-source-multiple-sites illusion.
10. Correctly disclosed AI media.

LLM can draft variants, but a human reviews them against the source packet.

This can multiply lesson content without multiplying research effort.

Important:
do not let the LLM invent the “ground truth.”

---

# 94. Ground-truth discipline for lessons

Every lesson should conceptually have:

- claim;
- expected skill;
- source packet;
- primary evidence;
- secondary corroboration;
- verified date;
- explanation;
- known uncertainty;
- reviewer;
- expiry/review date.

This is how the product avoids teaching hallucinations through an AI literacy app.

---

# 95. Research-driven lesson construction

Each lesson should have a learning objective, not only content.

Examples:

> “Learner can identify that five articles are not independent when all cite one source.”

> “Learner can distinguish media authenticity from claim truth.”

> “Learner can verify whether an AI-generated citation exists.”

> “Learner can correctly select insufficient evidence in breaking news.”

This makes impact measurable.

---

# 96. Impact: what should be measured

Do not use only:
- downloads;
- daily active users;
- lesson completion;
- XP.

Those measure engagement, not MIL.

## Better metrics

### Discernment
Can user distinguish supported vs unsupported claims?

### Transfer
Can user succeed on examples unlike the training set?

### Source tracing
Can user find primary evidence?

### Corroboration
Can user find independent support?

### Context detection
Can user identify wrong date/location/context?

### Calibration
Does confidence match correctness?

### Updating
Does user change confidence/conclusion after stronger evidence?

### Uncertainty
Can user correctly use “insufficient evidence”?

### Share decision
Does user avoid amplifying unresolved harmful claims?

### Retention
Does skill remain after 7/30 days?

### Efficiency
Can the learner reach a good conclusion with fewer irrelevant actions?

---

# 97. Evidence Process Rubric

Simple 0–4 rubric.

## 0 — Instinct only
Verdict based on appearance/emotion.

## 1 — Source inspected
User checks who is behind the content.

## 2 — Primary evidence
User traces the claim toward original evidence.

## 3 — Corroborated context
User checks independent evidence and relevant context.

## 4 — Calibrated conclusion
User states:
- what is supported;
- uncertainty;
- what remains unknown;
- responsible share decision.

This can be more meaningful than “93% score.”

---

# 98. Fast pilot design before submission

Past winner stories highlight real play-testing.

You do not need a huge study.

If possible, test with:
- university students;
- friends outside the team;
- one teacher;
- one journalism/media-literacy person.

Even a small honest pilot is better than fictional metrics.

Possible minimal pilot:

1. 5 unseen pre-test items.
2. 10–15 minute experience.
3. 5 matched post-test/transfer items.
4. confidence before each answer.
5. short interview:
   - What did you learn?
   - What did you do differently?
   - What confused you?
   - Would you use it?
   - What was the most memorable moment?

Track:
- primary source behavior;
- confidence;
- accuracy;
- evidence actions.

Do not overclaim statistical significance from a tiny sample.

Say:
> “In an early usability test with N participants, we observed…”

only if it really happened.

---

# 99. A/B research idea for later

Question:

Does a **Socratic coach** produce better transfer than a **direct-answer AI**?

Group A:
AI gives verdict/explanation.

Group B:
AI asks guided verification questions.

Measure:
- performance on unseen cases without AI.

This can become a research-paper direction after the hackathon.

It is not necessary for the submission.

---

# 100. Privacy-by-design ideas

A MIL product should model ethical information behavior.

Principles:

- minimize personal data;
- do not require political ideology;
- do not require biometric identity;
- do not permanently retain uploaded sensitive media by default;
- provide deletion controls;
- avoid profiling “misinformation susceptibility” in a stigmatizing way;
- keep classroom analytics aggregate where possible;
- explain what AI sees;
- separate research consent from normal use.

For minors:
stronger protections and teacher/guardian context may be needed depending on deployment.

---

# 101. Safety principles for user-submitted content

Potential user uploads may contain:
- violence;
- hate;
- private people;
- medical claims;
- political content;
- scams.

Product principles:
- warn before graphic material;
- avoid unnecessary re-display;
- avoid amplifying harmful URLs;
- avoid generating stronger disinformation variants against real people;
- protect personal data;
- use fictional/sanitized scenarios for adversarial training where possible.

---

# 102. Freedom of expression and neutrality

UNESCO explicitly values freedom of expression and diversity.

The product should not feel like:
> “Here is a list of approved opinions.”

Teach:
- factual verification;
- source evaluation;
- evidence quality;
- context;
- uncertainty;
- manipulation.

Separate:
- factual claims;
- opinions;
- satire;
- values;
- predictions.

A political opinion is not “false” merely because the model disagrees.

This is crucial for trust and European relevance.

---

# 103. Inclusion should be designed, not claimed

Possible concrete inclusion features/concepts:

- captions;
- transcripts;
- screen-reader labels;
- no color-only correctness indicators;
- keyboard navigation on web;
- dyslexia-friendly text options;
- plain-language mode;
- low-data mode;
- downloadable lesson pack;
- printable QR cards;
- image descriptions;
- reduced-motion option;
- multiple languages;
- locally adaptable examples;
- avoid culturally specific knowledge where not needed;
- optional audio;
- text alternative to video;
- safe content alternatives for traumatic examples.

A jury can understand concrete inclusion.

“Accessible to everyone” is not concrete.

---

# 104. Language strategy

For the hackathon:

Primary content:
- English.

Strong secondary:
- Ukrainian.

Future pack architecture can support:
- local language;
- dialect;
- cultural context.

Why this matters:
past UNESCO winners used local languages/dialects and underserved communities.

Do not promise 30 languages in one week.

Show:
> “The lesson format is designed to be localizable.”

---

# 105. Localization is not translation

A translated American fake-news example may fail in Ukraine, Madagascar, Indonesia, etc.

A local pack should adapt:
- platforms;
- slang;
- institutions;
- scams;
- source types;
- cultural cues;
- information channels.

This creates a credible global model:

**global skills, local scenarios.**

That phrase is useful.

---

# 106. Potential future content partners — only call them “potential”

Ukraine:
- VoxCheck
- StopFake
- Detector Media
- universities
- libraries
- youth organizations
- UNESCO Chairs
- IREX ecosystem

Europe:
- EDMO hubs
- fact-checking organizations
- journalism schools
- libraries
- teacher networks

Do not write:
> “Our partner VoxCheck…”

unless there is an agreement.

Write:
> “Potential content-validation partners include…”

---

# 107. Sustainability concepts

Possible sustainability model:

## Open educational core
Core learner lessons remain free.

## Reviewed scenario packs
Organizations create/adapt modules.

## Education use
Schools/universities use class packs and learning analytics.

## NGO / resilience deployment
Community organizations use local packs.

## Research partnerships
Universities evaluate learning outcomes.

## Institutional support
Potential grants/partnerships around media literacy, digital education, youth resilience.

## Annual content refresh
New AI/provenance/regulatory lessons.

Do not overcomplicate with a monetization pitch unless required.

UNESCO sustainability means:
**can this continue and grow?**

---

# 108. Product sustainability through an open lesson format

A very strong future-facing idea:

Create a documented **MIL Scenario Pack format**.

Not necessarily open-source everything.

The format could enable:
- universities;
- youth groups;
- fact-checkers;
- researchers

to contribute reviewed lessons.

This creates:
- localization;
- scale;
- community ownership;
- long-term relevance.

It also matches UNESCO’s co-creation ethos.

---

# 109. “Youth as MIL multipliers”

Past UNESCO work explicitly emphasizes youth as:
- co-creators;
- co-leaders;
- peer educators.

Your project can include a future path:

1. Learn.
2. Investigate.
3. Create a verified challenge.
4. Teach someone else.
5. Become a MIL Ambassador.

This is much more aligned with “Play Your Part” than a private streak.

---

# 110. Possible product modes

Keep MVP small, but long-term concept can be:

## Learn
Curated game path.

## Investigate
Guided Source Checker for real content.

## Challenge
Peer/community scenarios.

## Teach
Class/youth-organization pack.

Do not put all four modes in the hackathon demo if they clutter it.

---

# 111. The best 3-minute demo

A judge should see one “aha” case, not ten features.

## Demo case 1 — authentic media, false context

0:00–0:20
Show a believable viral post with a dramatic image/video.

User taps:
**Trust — 82% confidence.**

0:20–0:40
The app does not say wrong.

AI coach:
> “Who originally published this?”

0:40–1:00
Player traces a repost to an older source.

1:00–1:20
The original media is authentic, but from another year/location.

1:20–1:35
Result:
- Media Authenticity: Authentic
- Claim: Contradicted
- Context: Misleading

1:35–1:45
User lowers/changes confidence and earns XP for evidence actions.

Key line:
> **“Real media can still mislead.”**

## Demo case 2 — AI hallucinated academic citation

1:45–2:20
Paste an AI-generated academic answer.

It cites a plausible paper.

Student Source Checker:
- checks title/DOI/author;
- finds mismatch or nonexistent citation.

AI coach:
> “The citation sounds academic. Can you verify that the paper exists?”

Key line:
> **“Fluency is not evidence.”**

## Demo end

2:20–2:45
Show learner progress:
- Context
- Sources
- Citations
- Calibration

2:45–3:00
Final thesis:

> **“Detectors age. Verification habits transfer. We are building a flight simulator for the information age.”**

This one demo connects:
- social;
- news;
- AI media;
- chatbots;
- student sources;
- gamification;
- MIL;
- AI coach.

---

# 112. Alternative killer demo: Content Credentials

Case:

- image is synthetic;
- Content Credentials disclose the generation;
- caption is accurate;
- user initially chooses “Suspicious” only because it is AI.

Lesson:
> “AI-generated does not mean false.”

Then:

- authentic real image;
- wrong date/location.

Lesson:
> “Real does not mean truthful.”

This is intellectually strong and aligned with August 2026 EU policy.

---

# 113. Submission-week prioritization

The dossier contains far more than the team should implement.

For a strong submission, prioritize product proof.

## P0 — must be excellent

1. One unforgettable investigation loop.
2. Trust / Suspicious / Investigate.
3. Confidence before/after.
4. Evidence actions.
5. Socratic AI assistant.
6. Nuanced final conclusion.
7. Evidence Receipt.
8. Two polished scenarios:
   - real media / wrong context;
   - AI fake citation.
9. Clear learning-progression screen.
10. Proposal mapped to judging criteria.
11. 3-minute narrative.

## P1 — high-value if clean

1. C2PA / Content Credentials lesson.
2. Academic metadata lookup concept.
3. existing fact-check search.
4. daily booster.
5. Ukrainian + English localization demo.
6. teacher/community pack mock.

## P2 — post-submission / only if trivial

- deepfake detector ensemble;
- multiplayer;
- giant content library;
- social simulation;
- audio deepfake detector;
- advanced dashboard;
- 10 languages;
- custom model training;
- crowdsourced open marketplace.

---

# 114. What four strong programmers should optimize for

The team’s technical strength should buy:

- polish;
- speed;
- reliability;
- one surprising interactive flow;
- evidence grounding;
- convincing demo;
- fast iteration after user tests.

It should **not** buy feature sprawl.

A simpler product with:
- one original learning mechanism;
- strong evidence;
- beautiful demo;
- a small pilot

can be more competitive than a platform with 30 unfinished capabilities.

---

# 115. Judge-by-judge mental checklist

A judge may silently ask:

### “Why does this need to exist?”
Answer:
AI makes content authenticity harder to infer, and current tools often outsource judgment instead of teaching transferable verification.

### “Isn’t this just another fact checker?”
Answer:
No. The product scores and teaches the investigation process and belief updating.

### “Isn’t this just another Duolingo clone?”
Answer:
The progression is familiar, but the core mechanic is evidence investigation, not multiple choice.

### “Isn’t this just another deepfake detector?”
Answer:
No. Detection is one clue; the learner separates authenticity, claim truth, and context.

### “Why AI?”
Answer:
AI provides adaptive Socratic coaching, claim decomposition, evidence explanation, and personalized practice — without becoming the authority.

### “Why now?”
Answer:
Generative AI adoption + current EU transparency rules + growing education guidance.

### “Why you?”
Answer:
Ukrainian lived context, strong engineering capacity, youth perspective, and existing national MIL experience.

### “How do you know it works?”
Answer:
learning-science basis + pilot + transfer/calibration metrics.

### “Can it scale?”
Answer:
scenario packs, public standards/data, localization, teacher/youth organization model.

### “Who is it for?”
Answer:
name one specific primary audience.

---

# 116. Map the project to UNESCO judging criteria

## Consistency with Theme

Evidence:
- youth active role;
- investigation;
- peer/community multiplier;
- AI literacy;
- responsible participation.

Suggested phrase:
> “The learner does not consume a verdict; they play the role of investigator.”

## Clarity

Evidence:
- one loop;
- one visual model;
- one sentence.

Suggested phrase:
> “Pause → investigate → prove → update → share responsibly.”

## Innovation & Creativity

Pick only 3–4:
- three-axis model;
- process XP;
- Socratic AI;
- academic citation verification;
- provenance literacy.

## Feasibility & Sustainability

Evidence:
- public metadata;
- open standards;
- no custom foundation model dependency;
- curated gold scenarios;
- partner-generated packs;
- multilingual concept.

## Impact & Inclusion

Evidence:
- measurable transfer/calibration;
- low-bandwidth/print;
- accessibility;
- crisis-affected audiences;
- teacher/community use.

---

# 117. The strongest innovation bundle

If Claude must choose only five:

1. **Evidence Actions XP**
2. **Confidence Calibration**
3. **Authenticity / Claim / Context three-axis result**
4. **Socratic AI Coach**
5. **Academic Citation + Provenance Literacy**

Everything else supports those.

---

# 118. The strongest social-impact bundle

1. youth primary audience;
2. Ukraine-origin crisis resilience;
3. family/community challenges;
4. low-bandwidth/print packs;
5. teacher/youth organization packs;
6. measurable skill transfer.

---

# 119. The strongest Europe bundle

1. Article 50 / AI transparency literacy;
2. C2PA/Content Credentials education;
3. teacher digital-literacy alignment;
4. multilingual/local scenario packs;
5. freedom-of-expression / non-ideological evidence framing;
6. cross-border transfer.

---

# 120. The strongest research bundle

1. lateral reading;
2. inoculation/prebunking;
3. spaced boosters;
4. confidence calibration;
5. transfer testing;
6. iterative retrieval;
7. epistemic agency.

This is an unusually strong evidence base for a hackathon product.


# 121. Big idea backlog — 100 additional product/learning directions

These are deliberately broader than the MVP. Claude should use them to generate later roadmap/options, not as a feature checklist.

## Evidence and reasoning ideas

1. **Evidence Budget** — every mission gives limited investigation actions, teaching prioritization.
2. **Evidence Quality Cards** — Primary/Secondary, Direct/Indirect, Independent/Dependent, Current/Stale.
3. **Source Dependency Map** — visually collapse copied articles into one origin.
4. **Earliest Known Source** — reward finding first occurrence.
5. **Evidence Gap Card** — explicitly show what is still unknown.
6. **Counterevidence Mission** — after user forms a view, require searching for strongest credible contrary evidence.
7. **Best Alternative Explanation** — ask what else could explain the evidence.
8. **Claim Scope Check** — identify when evidence supports a narrower claim than the headline.
9. **Qualifier Rescue** — find words such as “may,” “associated,” “preliminary,” removed from reposts.
10. **Source Chain Length** — show how far a claim traveled from primary evidence.
11. **Citation Telephone** — each retelling changes the claim; user finds where distortion entered.
12. **Evidence Freshness** — compare old vs current sources.
13. **Correction Trail** — track how an article changed.
14. **Archive Detective** — use archived/older versions conceptually to learn revisions.
15. **Original Language Check** — compare translated claim against original.
16. **Quote Context Window** — reveal preceding/following sentences.
17. **Source Motive Without Dismissal** — identify incentives, then still evaluate evidence.
18. **Authority Scope** — expert is real but outside relevant expertise.
19. **Independent Replication** — one paper vs repeated findings.
20. **Consensus vs Popularity** — distinguish scientific synthesis from social likes.
21. **Prediction vs Observation** — article reports model forecast as fact.
22. **Data vs Interpretation** — same numbers, different claim.
23. **Missing Denominator** — “200% increase” with no baseline.
24. **Absolute Number Trap** — large number without population context.
25. **Base Rate Challenge** — intuitive alarm vs actual prevalence.
26. **Sampling Challenge** — viral poll is not representative.
27. **Publication Status** — working paper/preprint/final article.
28. **Retraction Timeline** — paper valid at publication, later retracted.
29. **Version Match** — chatbot cites old version while new version changed conclusion.
30. **Original Dataset Check** — paper’s claim vs source dataset.

## AI literacy ideas

31. **Hallucination Bingo** — title mismatch, author mismatch, DOI mismatch, fake quote, invented statistic.
32. **Fluency Trap** — two answers, more eloquent one is less sourced.
33. **Ask for Evidence** — compare AI response before/after requiring sources.
34. **Source Reconstruction Challenge** — AI paraphrase must be traced to original source.
35. **AI Confidence Illusion** — identical tone for known and uncertain claims.
36. **Citation Frankenstein** — real pieces combined into impossible reference.
37. **Currentness Check** — AI answers a question requiring current information without live evidence.
38. **Search vs Memory** — teach when external retrieval is necessary.
39. **Model Disagreement** — two AI systems disagree; user must resolve with evidence.
40. **Prompt Bias** — leading question causes skewed answer; user rewrites neutral prompt.
41. **AI Summary Loss** — summary drops caveat.
42. **Synthetic Consensus** — many AI-generated posts make a fringe claim look popular.
43. **AI Translation Drift** — generated translation changes certainty.
44. **AI Image Caption Hallucination** — visual model invents context not visible in image.
45. **AI Legal/Medical Authority Warning** — high-stakes claim requires authoritative current source.
46. **Generated Chart Audit** — chart labels/data do not match claimed source.
47. **AI Attribution Check** — quote assigned to wrong person.
48. **AI Source Type Check** — model presents news article as study.
49. **Retrieval Receipt** — show which evidence AI actually used.
50. **Unanswerable Question Reward** — AI correctly says evidence is unavailable and learner validates why.

## Social-media literacy ideas

51. **Handle Doppelgänger** — one character changed.
52. **Blue Check Fallacy** — verified identity does not verify every claim.
53. **Account Takeover** — genuine account posts scam after compromise.
54. **Follower Count Fallacy** — popularity vs evidence.
55. **Comment Consensus Illusion** — coordinated or non-independent replies.
56. **Like Count Manipulation** — engagement cannot establish truth.
57. **Sponsored Influence** — disclosure/affiliate incentives.
58. **Viral Loop Simulator** — emotional wording increases shares but decreases trust later.
59. **Context Collapse Story** — short clip removes prior question/answer.
60. **Repost Chain** — original disclaimer disappears after successive reposts.
61. **Hashtag Hijack** — unrelated content exploits trend.
62. **Community Rumor** — local rumor where official source is findable.
63. **Fake Giveaway** — urgency + impersonation + credential phishing cues.
64. **Donation Scam** — verify organization through known official channel.
65. **Celebrity Scam** — synthetic endorsement.
66. **Influencer Expertise** — charismatic creator outside evidence base.
67. **Native Ad** — editorial-looking paid content.
68. **Social Proof Ad** — fake reviews/“10,000 sold today.”
69. **Screenshot Chain Message** — no author/date.
70. **Algorithm Awareness** — why seeing something repeatedly does not mean broad consensus.

## News and journalism literacy ideas

71. **Breaking News Ladder** — evidence improves over time; user updates conclusion.
72. **Wire Copy Cluster** — five outlets, one wire source.
73. **Anonymous Source Weight** — understand legitimate use and limitations.
74. **Headline vs Body** — strongest claim appears only in headline.
75. **Opinion Label** — distinguish commentary from reporting.
76. **Corrections Page** — identify transparent editorial practice.
77. **Source Diversity** — compare state, local, specialist, primary data.
78. **Photo Caption Audit** — photo is real, caption wrong.
79. **News Image Crop** — crop changes impression.
80. **Archive Reuse** — old footage in current package.
81. **Data Journalism Audit** — trace chart to original dataset.
82. **Expert Quote Audit** — quote is real but cherry-picked.
83. **Press Release Pipeline** — press release → article → viral post.
84. **Embargo/Preliminary Result** — reported before full evidence.
85. **Correction Propagation** — original corrected, reposts remain wrong.

## Provenance and synthetic-media ideas

86. **Credentials Present** — teach reading C2PA.
87. **Credentials Absent** — teach that absence is inconclusive.
88. **Credentials Stripped** — screenshot/re-encode removes provenance.
89. **Synthetic and Ethical** — disclosed illustration.
90. **Real and Deceptive** — authentic image, false caption.
91. **Edit History** — benign crop/color adjustment vs semantic manipulation.
92. **Detector Disagreement** — compare clues without oracle.
93. **Compression Challenge** — detector confidence changes after platform transformations.
94. **Generator Shift** — old detector meets new model.
95. **Liar’s Dividend** — real media dismissed as “AI fake.”
96. **Voice Clone Verification** — out-of-band channel.
97. **Synthetic Witness** — AI avatar used to impersonate testimony.
98. **Parody Deepfake** — intention/disclosure/context matter.
99. **Historical Reconstruction** — synthetic media can be educational when labeled.
100. **Provenance vs Meaning** — technically authentic file may still be used to make false inference.

---

# 122. Another 50 “jury-wow” ideas

These are presentation-friendly concepts.

1. **Confidence Delta** — visible “82% → 31% after evidence.”
2. **Mind-Change Celebration** — animation rewards rational updating.
3. **Evidence Receipt** — shareable proof trail.
4. **“Why not 100%?” prompt** — forces uncertainty awareness.
5. **Three-axis result card** — Authentic / False claim / Wrong context.
6. **“Same image, two captions” challenge.**
7. **“Same paper, three headlines” challenge.**
8. **“Same data, two charts” challenge.**
9. **“Same source, five copied articles” challenge.**
10. **“One real citation, one fabricated citation” challenge.**
11. **First Impression vs Evidence replay.**
12. **Investigation heatmap** — which actions user used.
13. **Skill radar** — Source / Context / AI / Evidence.
14. **“I don’t know yet” button with positive reward.**
15. **Truth is not binary visual.**
16. **AI refuses to reveal answer early.**
17. **AI says “show me your evidence.”**
18. **AI asks user to challenge its own suggestion.**
19. **Provenance badge with explainer, not green trust check.**
20. **EU Article 50 mini-lesson.**
21. **“Label does not equal false” case.**
22. **Critical-ignore button.**
23. **Timed crisis mode.**
24. **Family reverse-mentorship mission.**
25. **Teacher printable challenge pack.**
26. **Local scenario pack in Ukrainian.**
27. **Universal global skill path in English.**
28. **Student citation mode.**
29. **Retraction alert lesson.**
30. **Source chain graph.**
31. **Syndication collapse visualization.**
32. **Primary-source trophy.**
33. **Correction culture badge.**
34. **Uncertainty meter with reasons.**
35. **Evidence strength, not source prestige.**
36. **Manipulation-tactic cards.**
37. **Prebunk micro-games.**
38. **Spaced transfer challenges.**
39. **Unseen-case final exam.**
40. **Offline QR challenge.**
41. **Youth ambassador pathway.**
42. **Community pack contribution concept.**
43. **“Verified as of [date]” on real cases.**
44. **Source update history.**
45. **Content warning / safe alternative.**
46. **Accessible captions/transcript.**
47. **Low-bandwidth lesson.**
48. **Real-world verification workflow inspired by AFP tools.**
49. **Academic source ecosystem powered by open metadata.**
50. **Final pitch ending: “Detectors age. Verification habits transfer.”**

---

# 123. What the world is still missing — strategic gaps this project can address

This section is an inference from the research landscape, not a claim that no other product has attempted any component.

## Gap A — Tools often verify for the user instead of teaching the user

Fact-checkers and detectors are necessary.

But a learner can become dependent on:
- a rating;
- a model;
- a badge.

Your product should increase independence over time.

## Gap B — Authenticity and truth are conflated

Many experiences ask:
> “AI or real?”

But real media can mislead and synthetic media can be harmless.

Your three-axis model directly addresses this.

## Gap C — Academic AI hallucinations are not integrated into mainstream MIL games

Students increasingly need to verify:
- papers;
- DOIs;
- author claims;
- research interpretation.

This can make your product relevant to universities, not only social media.

## Gap D — Provenance standards are growing faster than public literacy

C2PA and AI disclosure regimes create new signals.

Users need to know:
- what they mean;
- what they do not mean.

## Gap E — MIL products often measure knowledge immediately, not transfer

Your project can explicitly test:
- unseen topic;
- unseen format;
- delayed booster.

## Gap F — The most important correct answer can be “not enough evidence”

Most quizzes dislike ambiguity.

Real information environments require it.

## Gap G — Users need to know when to stop searching

FIRE’s iterative retrieval logic inspires a human lesson:
search until the critical evidence gap is resolved or explicitly unresolved.

## Gap H — Crisis verification needs a fast mode

People need a 30-second safety reflex before a 10-minute investigation.

Ukraine gives the team a credible design lens here.

## Gap I — Young people can become community multipliers

A private app does not automatically create social resilience.

Family, teacher, and youth-group missions can.

---

# 124. Anti-patterns — things that could actively weaken the submission

1. Calling the product simply **“Duolingo for fake news.”**
2. Claiming universal fake detection.
3. Giving a giant “truth percentage.”
4. Treating LLM output as authority.
5. Treating AI-generated as automatically false.
6. Treating real media as automatically truthful.
7. Treating C2PA as proof of truth.
8. Treating missing C2PA as proof of falsity.
9. Building a blockchain for truth.
10. Making a political source blacklist.
11. Scoring ideology.
12. Calling blogs bad and journals good.
13. Using citation count as truth score.
14. Treating peer review as infallible.
15. Ignoring corrections/retractions.
16. Claiming partnerships that do not exist.
17. Inventing pilot results.
18. Presenting a 10-person test as statistically generalizable.
19. Using copyrighted viral media without checking rights.
20. Using traumatic war imagery only for emotional effect.
21. Requiring face recognition.
22. Retaining sensitive uploads indefinitely.
23. Rewarding certainty more than evidence.
24. Punishing “I don’t know.”
25. Leaderboards based on speed alone.
26. Shame-based streaks.
27. A primary audience of “everyone on the internet.”
28. 12 categories with two shallow questions each.
29. Building a deepfake model instead of the learning experience.
30. Depending on one proprietary API for the entire value proposition.
31. Letting the LLM fabricate lesson explanations.
32. Allowing automatically generated ground truth.
33. Overusing AI because “AI” is a judging trend.
34. Saying “we use RAG” as if that is product innovation.
35. Showing architecture diagrams in place of user impact.
36. Pitching 30 future features in three minutes.
37. Claiming “Europe needs us” without policy connection.
38. Using Ukraine only as a dramatic origin story.
39. Treating disinformation as only politics.
40. Ignoring advertising/scams/health/academic contexts.
41. Ignoring accessibility.
42. Ignoring low bandwidth.
43. Ignoring source dependency.
44. Ignoring uncertainty.
45. Ignoring time/versioning.
46. Showing detector confidence without limitations.
47. Conflating chain-of-thought with explainability.
48. Exposing hidden model reasoning rather than evidence.
49. Overengineering community features.
50. Failing to test with someone outside the team.

---

# 125. What not to say in the pitch

Weak:
> “Our AI analyzes whether a post is true or fake.”

Stronger:
> “Our AI teaches the user what evidence to check next.”

Weak:
> “We detect deepfakes.”

Stronger:
> “We teach users to combine provenance, source, context, and forensic clues — because detectors can fail on new or transformed media.”

Weak:
> “We target everyone.”

Stronger:
> “We start with students and young adults who already use social media and AI for learning.”

Weak:
> “We fight propaganda.”

Stronger:
> “We train transferable verification habits that work across scams, news, research, synthetic media, and crisis information.”

Weak:
> “We calculate source credibility.”

Stronger:
> “We make source quality inspectable: author, source type, evidence, corrections, independence, and uncertainty.”

---

# 126. Suggested naming directions

Do not overinvest in naming before the thesis is locked.

## Evidence / proof direction

- Evidence Gym
- ProofQuest
- Evidence Quest
- ProofPath
- ProofLab
- ProofMode
- Proof Before Share
- Evidence Run
- Evidence Trail
- Evidence Passport
- ProofTrail
- ProofCheck

## Investigation direction

- VeriQuest
- VerifyLab
- VerifyPath
- Source Hunt
- SourceQuest
- Trace
- TraceIt
- TraceLab
- Context Hunt
- Signal Hunt
- Investigate

## Resilience direction

- InfoShield
- Signal
- ClearSignal
- MindShield
- InfoReflex
- Verify Reflex
- SignalSense
- SourceSense
- Evidence Sense

## MIL explicit

- MIL Quest
- MIL Lab
- MIL Passport
- MIL Gym
- MIL Play
- MIL Navigator

## Strongest conceptual names

**Evidence Gym** — strongest metaphor for training rather than checking.

**Trace** — clean, scalable, source-oriented.

**VeriQuest** — game-like.

**ProofQuest** — clear and memorable.

---

# 127. Tagline bank

- Train your verification reflex.
- Don’t guess. Investigate.
- From instinct to evidence.
- Proof before share.
- Learn to know what you know.
- Check the claim. Trace the proof.
- Think beyond true or false.
- Build proof, not confidence.
- Follow the evidence.
- Trust is earned by evidence.
- Learn the skill detectors cannot replace.
- Real is not always true.
- Synthetic is not always false.
- Context changes everything.
- Fluency is not evidence.
- A source is a starting point, not a verdict.
- Think critically. Trace independently.
- Pause. Investigate. Decide.
- Train for the information age.
- A flight simulator for digital trust.
- Detectors age. Verification habits transfer.
- Europe is building labels. Learn to read them.
- Learn before you share.
- Evidence over instinct.
- Confidence should follow evidence.

---

# 128. Possible pitch hook bank

### Hook A — real media / false context

> “Which is more dangerous: a fake image, or a real image with a false story?”

### Hook B — student AI

> “An AI gives a student a perfect-looking citation. The paper does not exist. How many students know what to do next?”

### Hook C — Ukraine

> “In Ukraine, we learned that information can be urgent long before it is verified.”

### Hook D — Europe 2026

> “This month, Europe’s new AI transparency rules started applying. Labels are coming. Literacy must catch up.”

### Hook E — detector problem

> “Today’s detector can become tomorrow’s outdated detector. A verification habit is harder to obsolete.”

### Hook F — epistemic agency

> “The biggest AI-age skill is not spotting fakes. It is knowing how to know.”

---

# 129. Suggested problem statement

A possible direction for Claude to refine:

> Generative AI has made digital content easier to create, imitate, and scale, but the deeper problem is not simply that more content can be fake. People increasingly face a mixed environment where synthetic content can be legitimate, authentic content can be misleading, real research can be misrepresented, and fluent AI answers can fabricate evidence. Existing detectors and fact-checkers are valuable but often deliver conclusions for users rather than training transferable verification habits. Young people need practical, repeatable skills for tracing sources, checking context, evaluating evidence, understanding provenance, and managing uncertainty before they trust or share information.

---

# 130. Suggested solution statement

> We are creating a gamified verification gym for students and young adults. Every challenge begins with an intuition — Trust, Suspicious, or Investigate — but the user earns progress by taking evidence actions: identifying the claim, tracing the original source, finding primary evidence, checking context and provenance, comparing independent sources, and verifying academic citations. An AI coach guides the investigation with questions instead of revealing a verdict. At the end, the user updates their confidence and distinguishes media authenticity, claim veracity, and context integrity. The goal is not to make users dependent on another detector. It is to train a verification reflex they can carry anywhere.

---

# 131. Suggested “why Ukraine” statement

> Our perspective is shaped by Ukraine, where information resilience has been developed under unusually high stakes and where media-literacy programs have already demonstrated measurable long-term effects. We want to translate that culture of verification into a tool that is useful far beyond Ukraine — for students checking AI citations, families facing impersonation scams, communities assessing emergency information, and anyone navigating synthetic media.

Only use this if it accurately represents the team.

---

# 132. Suggested “why Europe / why now” statement

> On 2 August 2026, new EU AI Act transparency obligations for AI-generated and manipulated content became applicable. This is an important step, but transparency signals only work when people understand how to use them. A label can say that content was generated by AI; it cannot tell a learner whether the claim is supported, whether the context is misleading, or whether the evidence is sufficient. Our project turns this regulatory moment into practical literacy.

Official source:
https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content

---

# 133. Suggested “why AI” statement

> AI should not become the new authority in a course about questioning authority. We use AI as a Socratic coach: to decompose claims, ask the next verification question, explain evidence, and personalize practice. The learner still makes the judgment and can inspect the sources behind it.

---

# 134. Suggested “why gamification” statement

> Verification is a skill, not a lecture topic. The game rewards the behaviors we want users to carry into real life: leaving a suspicious page to investigate its source, tracing a claim to primary evidence, comparing independent sources, updating confidence, and refusing to amplify claims when evidence is insufficient.

---

# 135. Suggested “what makes us different” statement

> Most tools ask “Is this fake?” We teach three different questions: Was the media manipulated or generated? Is the claim supported by evidence? Is the context accurate? That distinction lets learners understand why an AI-generated image can be honest and a real image can still be used to deceive.

---

# 136. Suggested “impact” statement

> We will not measure success only by XP or downloads. We will test whether users perform better on new examples they have never seen: whether they find primary sources, recognize misleading context, verify citations, calibrate confidence, and correctly choose “insufficient evidence.” Our goal is skill transfer, not quiz memorization.

---

# 137. Suggested sustainability statement

> The core learning method is reusable across topics. New local scenario packs can be built from reviewed source packets by educators, youth organizations, universities, and fact-checkers. This lets the same global verification skills be taught through local languages, platforms, risks, and cultural contexts.

---

# 138. Questions Claude should answer before producing architecture later

1. What is the one-sentence product thesis?
2. Who is the primary audience?
3. Which 3–5 differentiators survive prioritization?
4. What are the two demo cases?
5. What exactly earns XP?
6. What is the final judgment taxonomy?
7. What can the AI reveal before the learner finishes?
8. What is the minimum Evidence Receipt?
9. Which data sources are essential vs optional?
10. Which real-world content is licensed/safe to demo?
11. Which metrics can be collected in an honest pilot?
12. What accessibility features are mandatory?
13. What language(s) are demoed?
14. What is the post-hackathon sustainability story?
15. What features are explicitly deferred?

Architecture should come **after** those decisions.

---

# 139. Source reliability hierarchy for Claude

When using this dossier:

## Tier A — strongest
- UNESCO official pages/publications
- European Commission official pages
- C2PA official spec
- official university/research pages
- peer-reviewed papers
- official APIs/documentation
- author-maintained GitHub repositories

## Tier B — useful
- established NGOs/fact-checkers
- project websites
- preprints with author repositories
- public research datasets

## Tier C — discovery only
- PapersWithCode
- Awesome lists
- Reddit/community discussions
- blog summaries
- unofficial benchmark reproductions

For any important proposal claim:
prefer Tier A/B.

---

# 140. Primary source library — UNESCO

2026 Hackathon:
https://www.unesco.org/en/articles/unesco-youth-hackathon-2026

Youth Hackathon overview:
https://www.unesco.org/en/media-information-literacy/youth-hackathon

2025 winners:
https://www.unesco.org/en/articles/global-youth-lead-way-media-and-information-literacy-meet-unesco-hackathon-2025-winners

CLICKBAIT winner story:
https://www.unesco.org/en/articles/local-board-game-global-stage-vietnamese-students-rethink-digital-trust

2024 winners:
https://www.unesco.org/en/articles/winners-unescos-youth-hackathon-2024-shape-future-media-and-information-literacy

2023 winners:
https://www.unesco.org/en/articles/youth-hackathon-winners-celebrated-paris

2022 Hackathon:
https://www.unesco.org/en/media-information-literacy-week/fourth-youth-hackathon

2021 winners:
https://www.unesco.org/en/articles/truly-digital-entrepreneurs-six-solutions-win-global-media-and-information-literacy-youth-hackathon

2020 winners:
https://www.unesco.org/en/articles/winners-global-media-and-information-literacy-youth-hackathon-reveal-inspiring-projects-fight

UNESCO MIL:
https://www.unesco.org/en/media-information-literacy

Deepfakes and epistemic agency:
https://www.unesco.org/en/articles/deepfakes-and-crisis-knowing

UNESCO MIL in Ukraine:
https://www.unesco.org/en/articles/unesco-strengthens-media-and-information-literacy-across-ukraine

---

# 141. Primary source library — Europe / EU

Media literacy:
https://digital-strategy.ec.europa.eu/en/policies/media-literacy

AI-generated content transparency code:
https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content

Article 50 quick facts:
https://digital-strategy.ec.europa.eu/en/factpages/quick-facts-transparency-rules-ai-systems

Article 50 guidance:
https://digital-strategy.ec.europa.eu/en/library/guidelines-transparency-obligations-providers-and-deployers-ai-systems

Enforcement / 2 August 2026:
https://digital-strategy.ec.europa.eu/en/news/commission-starts-enforcing-ai-act-rules-and-new-transparency-requirements-2-august

2026 teacher digital-education guidelines:
https://digital-strategy.ec.europa.eu/en/news/commission-publishes-guidelines-support-teachers-key-digital-education-priorities

EDMO:
https://edmo.eu/

---

# 142. Primary source library — learning science

Stanford Civic Online Reasoning:
https://cor.stanford.edu/

COR research:
https://cor.stanford.edu/research/

Lateral reading:
https://cor.stanford.edu/research/lateral-reading-on-the-open-internet/

Lateral-reading practice:
https://cor.stanford.edu/curriculum/lessons/lateral-reading-resources-practice/

EU prebunking/inoculation 2026:
https://www.nature.com/articles/s44271-025-00379-3

Booster shots:
https://www.nature.com/articles/s41467-025-57205-x

Cat Park:
https://www.nature.com/articles/s41598-023-43885-2

Bad Vaxx:
https://www.nature.com/articles/s41598-025-09462-5

Bad News evidence:
https://www.nature.com/articles/s41599-019-0279-9

Misinformation intervention toolbox:
https://www.nature.com/articles/s41562-024-01881-0

---

# 143. Primary source library — Ukraine / MIL

IREX L2D fact sheet:
https://www.irex.org/sites/default/files/L2D%20Fact%20Sheet_Final.pdf

IREX long-term impact:
https://www.irex.org/sites/default/files/node/resource/impact-study-media-literacy-ukraine.pdf

IREX schools evaluation:
https://www.irex.org/sites/default/files/node/resource/evaluation-learn-to-discern-in-schools-ukraine.pdf

IREX English curriculum:
https://www.irex.org/sites/default/files/node/resource/learn-to-discern-media-literacy-curriculum-english-2.pdf

IREX L2D modern framing:
https://www.irex.org/sites/default/files/L2D%20Fact%20Sheet%20New%20Version%20PDF%202022%204-5.pdf

VoxCheck:
https://voxukraine.org/en/voxcheck

VoxCheck reproducible methodology:
https://rusdisinfo.voxukraine.org/method
https://medfakes.voxukraine.org/en/method

StopFake:
https://www.stopfake.org/en/about-us/

---

# 144. Primary source library — open standards/APIs

C2PA:
https://spec.c2pa.org/specifications/specifications/2.4/index.html

C2PA Rust:
https://github.com/contentauth/c2pa-rs

C2PA JavaScript:
https://github.com/contentauth/c2pa-js

OpenAlex:
https://developers.openalex.org/

Crossref:
https://www.crossref.org/documentation/retrieve-metadata/rest-api/

Crossref Retraction Watch:
https://www.crossref.org/documentation/retrieve-metadata/retraction-watch/

Semantic Scholar:
https://api.semanticscholar.org/api-docs/

Google Fact Check Tools:
https://developers.google.com/fact-check/tools/api/

ClaimReview:
https://schema.org/ClaimReview

---

# 145. Primary source library — GitHub/research shortcuts

The Misinformation Game:
https://github.com/TheMisinformationGame/MisinformationGame

AFP Verification Plugin:
https://github.com/AFP-Medialab/verification-plugin

FIRE:
https://github.com/mbzuai-nlp/fire

OpenFactCheck:
https://github.com/mbzuai-nlp/openfactcheck

ProgramFC:
https://github.com/mbzuai-nlp/ProgramFC

FSRS:
https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler

Dart FSRS:
https://github.com/open-spaced-repetition/dart-fsrs

DeepfakeBench:
https://github.com/SCLBD/DeepfakeBench

NTIRE 2026:
https://github.com/msu-video-group/NTIRE-2026-DeepFake-Detection

WaRPAD:
https://github.com/sungikchoi/WaRPAD

UniGenDet:
https://github.com/Zhangyr2022/UniGenDet

GenImage:
https://github.com/GenImage-Dataset/GenImage

UniversalFakeDetect:
https://github.com/WisconsinAIVision/UniversalFakeDetect

IAPL:
https://github.com/liyih/IAPL

GenD:
https://github.com/yermandy/GenD

PRADA:
https://github.com/jonasricker/prada

S-HARM:
https://github.com/Qedrigord/SHARM

TrueFake:
https://github.com/MMLab-unitn/TrueFake-IJCNN25

Breaking the News:
https://github.com/Woaichichangfen/BreakingTheNews

OASIS:
https://github.com/camel-ai/oasis

SoMe:
https://github.com/LivXue/SoMe

Awesome AIGC image detection:
https://github.com/yjtlab/awesome-aigc-image-detection

AIGC image/video detection:
https://github.com/ant-research/Awesome-AIGC-Image-Video-Detection

AI-generated video detection:
https://github.com/chenhaoxing/Awesome-AI-Generated-Video-Detection

PapersWithCode discovery:
https://paperswithcode.co/

---

# 146. If the team can read only ten sources tonight

Read in this order:

1. UNESCO Youth Hackathon 2026  
   https://www.unesco.org/en/articles/unesco-youth-hackathon-2026

2. 2025 winners  
   https://www.unesco.org/en/articles/global-youth-lead-way-media-and-information-literacy-meet-unesco-hackathon-2025-winners

3. CLICKBAIT story  
   https://www.unesco.org/en/articles/local-board-game-global-stage-vietnamese-students-rethink-digital-trust

4. 2024 winners — especially MAHW  
   https://www.unesco.org/en/articles/winners-unescos-youth-hackathon-2024-shape-future-media-and-information-literacy

5. UNESCO deepfakes / epistemic agency  
   https://www.unesco.org/en/articles/deepfakes-and-crisis-knowing

6. Stanford lateral reading  
   https://cor.stanford.edu/research/lateral-reading-on-the-open-internet/

7. 2026 EU inoculation study  
   https://www.nature.com/articles/s44271-025-00379-3

8. EU AI transparency rules  
   https://digital-strategy.ec.europa.eu/en/policies/code-practice-ai-generated-content

9. FIRE  
   https://github.com/mbzuai-nlp/fire

10. C2PA explainer  
    https://spec.c2pa.org/specifications/specifications/2.4/explainer/Explainer.html

If there is time, next:
- IREX L2D;
- The Misinformation Game;
- AFP verification plugin;
- Crossref/OpenAlex;
- NTIRE 2026.

---

# 147. If Claude can use only one page of this dossier

Give Claude these constraints:

**Core thesis**  
A game that trains verification behavior rather than delivering truth verdicts.

**Primary audience**  
Students / young adults.

**Core loop**  
Trust/Suspicious/Investigate → confidence → evidence actions → Socratic AI → nuanced conclusion → confidence update → share decision → evidence receipt.

**Signature model**  
Media Authenticity × Claim Veracity × Context Integrity.

**Signature modes**  
Social context case + AI fake citation case.

**Learning science**  
Lateral reading + prebunking + spaced boosters + metacognition/calibration.

**2026 hook**  
EU AI transparency rules apply from 2 August 2026; teach users how to interpret provenance/labels.

**Ukraine angle**  
Crisis-informed verification habits, globally transferable.

**Impact**  
Measure transfer, source tracing, calibration, uncertainty — not only XP.

**Sustainability**  
Reviewed local scenario packs for teachers/youth organizations.

**Do not build the identity around a deepfake detector.**

---

# 148. Final strategic recommendation

The project should aim to own this category:

> **Verification literacy for the AI age.**

Not:
- fact checking as a service;
- deepfake detection;
- news rating;
- source scoring;
- another AI assistant.

The learning promise is:

> **After using the product, a student should be harder to fool even when the app is closed.**

That is the single best test of whether the concept is genuinely MIL.

And the competition promise is:

> **The jury should leave the pitch remembering one insight they did not have before: a piece of media can be real while the story around it is false, and the skill that survives changing AI models is the ability to trace evidence.**

That is both:
- simple enough for three minutes;
- deep enough for UNESCO;
- modern enough for 2026;
- grounded in European policy;
- grounded in research;
- connected to Ukrainian experience;
- technically feasible for a strong four-person team;
- expandable into a serious global educational product.

---

# 149. Final “do this / not that” summary

## Do this

- Teach verification.
- Reward evidence.
- Reward uncertainty.
- Reward mind changes.
- Separate authenticity from truth.
- Teach context.
- Teach provenance.
- Teach AI citation verification.
- Use an AI coach.
- Use open standards/data.
- Test transfer.
- Tell a Ukrainian-origin, globally relevant story.
- Show inclusion concretely.
- Demonstrate one unforgettable case.
- Keep the proposal extremely clear.

## Not that

- Build a detector and call it literacy.
- Build a truth score.
- Build a blacklist.
- Build a huge platform.
- Show twenty technologies.
- Overclaim AI accuracy.
- Overclaim pilot results.
- Pretend all synthetic content is misinformation.
- Make users dependent on an AI oracle.
- Target everyone.
- Hide uncertainty.
- forget the source trail.

---

# 150. Closing thesis for Claude

**The winning version is not “Duolingo + fact checking.”**

It is:

> **Evidence Gym — a game that trains young people to investigate before they trust. Across social media, news, synthetic media, and AI answers, users practice a repeatable verification reflex: trace the source, inspect the evidence, check the context, understand provenance, compare independent sources, calibrate confidence, and know when the evidence is insufficient. The AI guides the investigation but never replaces the learner’s judgment.**

The most defensible competitive line is:

> **Detectors age. Verification habits transfer.**
