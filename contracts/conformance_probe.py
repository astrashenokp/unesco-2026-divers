#!/usr/bin/env python3
"""Compare a running API against the contract it promises to implement.

Run it against any deployment and it answers one question: can the
learner client talk to this server yet, and if not, what is missing?

    python contracts/conformance_probe.py http://localhost:8000

Standard library only, so it runs anywhere without a virtualenv.

It checks three things, because two of them are invisible from the
server side. Endpoint coverage shows up in any test suite. CORS and a
missing identity verifier do not: `curl` succeeds, the server's own
tests pass, and only a browser fails. The Flutter client ships as a web
build, so a browser is the thing that has to work.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

CONTRACT = Path(__file__).with_name("openapi.yaml")

# The origin a `flutter run -d chrome --web-port=8080` client sends.
WEB_ORIGIN = "http://localhost:8080"

OK, MISSING, WARN = "PASS", "FAIL", "WARN"


def contract_paths() -> dict[str, list[str]]:
    """Read `paths:` out of the contract without a YAML dependency.

    The contract is the source of truth for what the client may call, so
    the probe reads it rather than carrying its own copy of the list —
    a hardcoded list would silently drift the moment the contract grows.
    """
    operations: dict[str, list[str]] = {}
    current: str | None = None
    in_paths = False
    for line in CONTRACT.read_text(encoding="utf-8").splitlines():
        if re.match(r"^paths:", line):
            in_paths = True
            continue
        if in_paths and re.match(r"^\S", line):
            break  # a new top-level key ends the paths section
        if not in_paths:
            continue
        if path := re.match(r"^  (/\S*):", line):
            current = path.group(1)
            operations[current] = []
        elif current and (verb := re.match(r"^    (get|post|put|patch|delete):", line)):
            operations[current].append(verb.group(1).upper())
    return operations


def request(url: str, method: str = "GET", headers: dict[str, str] | None = None):
    req = urllib.request.Request(url, method=method, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.status, dict(response.headers), response.read()
    except urllib.error.HTTPError as exc:
        return exc.code, dict(exc.headers), exc.read()
    except OSError as exc:
        return None, {}, str(exc).encode()


def main(base: str) -> int:
    base = base.rstrip("/")
    findings: list[tuple[str, str]] = []

    status, _, body = request(f"{base}/openapi.json")
    if status != 200:
        print(f"{MISSING}  no server at {base} ({status or 'unreachable'})")
        return 1

    served = json.loads(body).get("paths", {})
    promised = contract_paths()

    print(f"Contract promises {sum(len(v) for v in promised.values())} operations "
          f"across {len(promised)} paths.\n")

    live = 0
    for path, verbs in promised.items():
        # FastAPI and OpenAPI agree on `{param}` syntax, so paths compare
        # directly without normalising.
        actual = served.get(path)
        for verb in verbs:
            if actual and verb.lower() in actual:
                print(f"  {OK}  {verb:6} {path}")
                live += 1
            else:
                print(f"  {MISSING}  {verb:6} {path}")
                findings.append(("endpoint", f"{verb} {path} is not served"))

    total = sum(len(v) for v in promised.values())
    print(f"\n{live} of {total} operations implemented.\n")

    # A browser sends a preflight before any request carrying an
    # Authorization header. No CORS middleware means every single call
    # from the web build fails before it reaches a route — including the
    # routes that do exist.
    status, headers, _ = request(
        f"{base}/attempts",
        method="OPTIONS",
        headers={
            "Origin": WEB_ORIGIN,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type,idempotency-key",
        },
    )
    allowed = headers.get("access-control-allow-origin") or headers.get(
        "Access-Control-Allow-Origin"
    )
    if allowed in ("*", WEB_ORIGIN):
        print(f"  {OK}  CORS preflight accepted from {WEB_ORIGIN}")
    else:
        print(f"  {MISSING}  CORS preflight rejected ({status}); the web client "
              f"cannot call this server from {WEB_ORIGIN}")
        findings.append(("cors", "no Access-Control-Allow-Origin on preflight"))

    # An unconfigured identity verifier answers 503 to every authenticated
    # route, so the endpoints that exist are still unreachable. Told apart
    # from a genuine rejection by the code, not the status.
    status, _, body = request(
        f"{base}/attempts",
        method="POST",
        headers={"Authorization": "Bearer probe", "Idempotency-Key": "probe-key-1234"},
    )
    code = ""
    try:
        code = json.loads(body).get("code", "")
    except (ValueError, AttributeError):
        pass
    if code == "identity-verifier-unavailable":
        print(f"  {MISSING}  no identity verifier configured; every authenticated "
              f"route answers 503")
        findings.append(("auth", "identity verifier not wired into create_app()"))
    elif status in (400, 401, 422):
        print(f"  {OK}  authentication is enforced and a verifier is present")
    else:
        print(f"  {WARN}  unexpected auth probe result: {status} {code}")

    if not findings:
        print("\nThe client can be pointed at this server.")
        return 0

    print(f"\n{len(findings)} blocker(s) between the client and this server.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"))
