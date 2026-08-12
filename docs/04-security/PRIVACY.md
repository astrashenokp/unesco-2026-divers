# Privacy and data governance

## Principles

Data minimization, purpose limitation, privacy-friendly defaults, transparency, user access/deletion, short retention, child-aware design, aggregation, and no political-susceptibility profiling.

## Do not collect by default

Exact birth date, legal name, contacts, precise location, advertising ID, political affiliation, biometric templates, browsing history, full device fingerprint, private Drive contents, raw model conversations, or uploads after processing TTL.

Use age band and pseudonymous learner ID where possible. Guest mode should support the demo without identity.

## Purpose matrix

| Data | Purpose | Visibility | Default handling |
|---|---|---|---|
| auth UID | account/session | identity service only | delete with account |
| locale/accessibility prefs | usable UI | learner/service | local/server minimal |
| attempt/skill state | learning continuity | learner; aggregate educator | user export/delete |
| confidence/action data | feedback/research if consented | learner; privacy-safe aggregate | never ideology label |
| temporary URL/upload | requested investigation | sandbox worker | short TTL, no training |
| operational trace | reliability/security | restricted operators | redact, 30-day pilot target |
| research data | explicit study | named research access | separate consent, protocol/TTL |

## Learner rights workflow

Provide clear notice; account/data export; deletion status and deadline; revoke optional research/analytics consent; correct profile; contact/appeal. Deletion propagates through primary stores, caches, analytics identifiers and provider-held data as contractually supported; immutable security logs retain only what law/security requires and are disclosed.

## Minors and education

Children are in scope. The product is intended for younger learners as
well as adults, and the client ships two content modes: the younger mode
runs the same skills, the same three axes and the same scoring, with
missions built on distressing case material left out.

Suitability is decided from per-mission `contentWarnings` against an
**allowlist** of tags a younger learner may meet. This fails closed: a
warning tag the client does not recognise keeps the mission out of the
younger mode, so content from a new pack or a later version is never
shown to a child merely because its tag was unfamiliar. The allowlist is
editorial and belongs to Role 3 — adding a tag to it is a content-review
decision, not a code change.

The mode is a **suitability choice, not an access control**, and the UI
says so in both places it appears. It is a soft setting anyone can
change. Nothing in the product should be described to a school or a
parent as a safeguarding gate, because it is not one.

Still required before a school deployment or any real-world use with
children, none of which the current build provides: jurisdiction
mapping, age assurance proportional to risk, parental/school authority
analysis, child DPIA, no targeted ads, no public profiles or contact
between learners, restricted notifications, facilitator controls,
procurement/DPA and an independent child-safety review of the content
pack itself. Two content modes address what is *shown*; they do not
address consent, authority, or data handling for minors.

## Third parties

Maintain subprocessor register with purpose, fields, region, retention/training, security and deletion. Public/free API discovery lists do not satisfy due diligence. Never send raw private/student content to Stitch MCP.

## Analytics

Use pseudonymous first-party events, coarse buckets, small-cohort suppression and aggregate early. Do not optimize dark patterns. Product, research and essential security processing are distinct purposes/configurations.

Legal bases, exact retention and international-transfer mechanisms require qualified legal review before real deployment; this is an engineering baseline, not legal advice.
