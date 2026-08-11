# Security control baseline

## Identity and authorization

- Firebase ID token verified server-side: issuer, audience, signature, expiry, revocation policy.
- Authorization is deny-by-default and resource-scoped; never trust client role/user ID.
- Guest uses Firebase Anonymous Auth (`signInAnonymously()`); the resulting token is verified through the same path as any other principal — no separate demo-only auth code path (ADR-008). Guest has isolated pseudonymous state and no administrative/content mutation.
- Admin/editor roles use MFA, least privilege, short sessions and step-up authorization.
- Service-to-service uses per-service IAM/workload identity, not shared keys.

## Input/output

- Validate JSON shape, type, length, enum and content type; bounded request bodies.
- Encode output by context; no raw HTML/Markdown execution from users/providers.
- Parameterized SQL/ORM; prohibit dynamic query fragments from untrusted input.
- URLs allow `https` only, normalize IDNs, block credentials/fragments when irrelevant, resolve/recheck IP, deny loopback/link-local/private/metadata ranges and redirect hops to them.
- Files: quarantine, extension + MIME + magic-byte agreement, size/page/duration/decompression limits, AV scan, sandbox parser, random object names.

## Web/mobile/API

- TLS/HSTS, secure cookies if used, CSRF protection for cookie flows, strict CORS allowlist.
- CSP for Flutter web host; frame ancestors denied; referrer/permissions policy minimized.
- No sensitive tokens in localStorage; platform secure storage for refresh-sensitive data.
- App Check is an abuse signal, never sole authentication.
- Rate limits by route/risk/subject/IP with safe error and retry hints.
- Idempotency and object-level authorization on every mutation/read.

## Cloud/data

- Separate projects/environments; protected prod; no broad primitive roles.
- Cloud Run behind load balancer/Armor; prevent direct URL bypass.
- Cloud SQL private/restricted path, PITR/backups, encryption, least-privilege DB roles.
- Storage buckets private, uniform access, signed URLs short-lived, retention/lifecycle.
- Secret Manager with access logs and rotation; no secrets in images/env dumps/remote config.
- Organization policies where available: restrict key creation, public buckets, allowed regions.

## Supply chain and CI

- Lock dependencies; automated updates reviewed; license/vulnerability policy.
- Pin GitHub Actions by full SHA and container images by digest for prod.
- Secret, SAST, SCA, IaC, container and SBOM scans.
- OIDC short-lived cloud credentials; PR workflows from forks get no secrets.
- Protected branches/environments, CODEOWNERS and signed/provenance-aware releases.
- Review external agent hooks/binaries; never auto-update RTK/gstack/pxpipe in prod workflows.

## Logging/detection

- Structured events with actor category/action/object/result/trace ID, no content/secrets.
- Alert: authz denials spike, WAF/rate anomalies, admin role/publish, secret access, cost/quota, error/SLO burn, malware/prompt-injection flags.
- Clock sync, restricted logs, retention, export for audit; test alert routing.

## Control ownership

Security ownership follows the code boundary: Role 1 owns frontend controls, Role 2 API/domain/application-integration controls, Role 3 AI/retrieval/content-safety controls, and Role 4 platform/data/infrastructure/pipeline controls plus the shared gate implementation. Evidence Guardian independently audits evidence; it does not own remediation. A checklist without passing negative tests is not a control.
