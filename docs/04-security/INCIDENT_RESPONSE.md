# Incident response

## Severity

- SEV-0: imminent human safety/CSAM or confirmed broad credential/control-plane compromise.
- SEV-1: sensitive data exposure, auth bypass, malicious publication, production takeover/outage.
- SEV-2: limited exposure, persistent major degradation, exploitable high-risk weakness.
- SEV-3: minor issue/no current exploitation.

## First 30 minutes

1. Name incident commander and secure communication channel.
2. Confirm facts, scope, affected environment/data/users; start timestamped log.
3. Contain reversibly: disable feature/provider/MCP, revoke token, quarantine pack, block indicator, roll traffic back.
4. Preserve minimal forensic evidence; do not paste secrets/PII into chat/tickets.
5. Notify security-quality and affected service owner; contact legal/safety specialist where needed.

## Response lifecycle

Detect → triage → contain → eradicate → recover → monitor → notify as required → blameless review → tracked remediation/retest.

## Playbooks

### Leaked secret

Revoke/rotate first, identify access/use, replace through Secret Manager/OIDC, invalidate derived sessions, scan history/logs/builds, document scope. Do not rely on deleting the Git file.

### Prompt injection/provider compromise

Disable affected tool/adapter via kill switch, switch deterministic mode, inspect scoped audit metadata, rotate any possibly exposed token, add regression eval, re-enable under narrowed tools.

### Harmful/incorrect mission

Quarantine version, preserve audit, assess reach/harm, publish corrected new version, notify affected learners where helpful, never silently mutate old receipts.

### Data loss/bad deploy

Stop writes if needed, roll back compatible image, validate backup, restore to isolated environment, verify integrity, then controlled cutover.

## Post-incident

Within 72 hours of stabilization: timeline, root/systemic causes, what worked/failed, user impact, detection gap, actions with owners/dates. Test each fix; update threat model/runbook. No blame or unsupported speculation.
