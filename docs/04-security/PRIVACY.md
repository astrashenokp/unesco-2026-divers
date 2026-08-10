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

MVP defaults to 16+. Before younger or school deployment: jurisdiction mapping, age assurance proportional to risk, parental/school authority analysis, child DPIA, no targeted ads, no public profiles/contact, restricted notifications, facilitator controls, procurement/DPA and child-safety review.

## Third parties

Maintain subprocessor register with purpose, fields, region, retention/training, security and deletion. Public/free API discovery lists do not satisfy due diligence. Never send raw private/student content to Stitch MCP.

## Analytics

Use pseudonymous first-party events, coarse buckets, small-cohort suppression and aggregate early. Do not optimize dark patterns. Product, research and essential security processing are distinct purposes/configurations.

Legal bases, exact retention and international-transfer mechanisms require qualified legal review before real deployment; this is an engineering baseline, not legal advice.
