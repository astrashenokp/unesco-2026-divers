# Security test plan

## Every pull request

Secret scan; lint/SAST; dependency/license scan; tests for changed authorization/input handling; IaC validation; contract schema checks; no production secrets for forked PRs.

## Main/nightly

Full SCA/container scan, API negative tests, dependency lock integrity, DAST against ephemeral environment, AI injection/leakage suite, fuzz/property tests for scenario parser and mission state/idempotency.

## Pre-release manual checks

- BOLA/BFLA across attempts, receipts, reports and admin routes.
- token expiry/revocation/audience; admin MFA/step-up.
- rate/cost/concurrency abuse and graceful limits.
- SSRF variants: redirects, DNS rebinding defense, IPv4/IPv6 encodings, metadata IP.
- file/polyglot/decompression/parser sandbox if upload enabled.
- CSP/CORS/deep links/storage/log redaction.
- DB restore and rollback; WAF bypass/direct Cloud Run URL.
- prompt injection through user text, evidence, metadata, filename, MCP/tool output and retrieved page.
- forged evidence IDs/citations, malformed structured output, gold leakage.
- mobile MASVS: storage/network/auth/platform/privacy and release build config.

## Release blocking

Block on known exploitable critical/high, authz bypass, secret/PII exposure, unsafe parser/SSRF, AI tool misuse/gold leakage, untested destructive migration, absent rollback or critical accessibility failure.

Document risk acceptance with owner, evidence, compensating control and expiry; “hackathon” is not permanent acceptance.

## External review

Before public pilot with UGC/minors/open URL: independent penetration test plus privacy/child-safety/content review. Use coordinated disclosure and retest fixes.
