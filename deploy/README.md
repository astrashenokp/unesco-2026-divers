# Deploying Evidence Gym

Two containers, built from this repository root. Written for
[Northflank](https://northflank.com/) but nothing here is specific to
it — any host that builds a Dockerfile will do.

Build context is the **repository root** for both, not the service
directory. The API depends on two sibling packages by path and reads the
content pack at runtime; the web build needs the design-system package.
A context narrowed to one directory resolves none of them.

---

## 1. The API

| | |
|---|---|
| Dockerfile | `deploy/api.Dockerfile` |
| Build context | `/` (repository root) |
| Port | `8080` — Northflank injects `PORT`, and the container reads it |
| Health check | `GET /health` |

### Environment

| Variable | Value | Why |
|---|---|---|
| `EVIDENCE_GYM_CORS_ORIGINS` | the web service's public URL | Without it the browser blocks every request before it reaches a route. **No trailing slash.** |
| `EVIDENCE_GYM_PATH_PREFIX` | `/v1` (default) | The contract declares `servers: …/v1`; a client asking for `/v1/...` gets 404 from an app mounted at the root. |
| `DATABASE_URL` | a Postgres connection string | Optional. Without it the API keeps everything in memory, which means **every attempt, receipt and report is lost on restart** — including the container restarting itself after a deploy. With it, `POST /reports` can stop answering 503. |

Northflank can attach a Postgres addon and inject `DATABASE_URL`. That
is the single change that turns this from a demonstration into
something that remembers what people did.

**Sign-in is not configured, deliberately.** The development identity
verifier refuses to start unless `EVIDENCE_GYM_ENV=development`, and it
should stay that way: those credentials are printed on the sign-in
screen. A deployment that enabled them would be publishing a working
login to everyone who read the page.

Until Firebase is configured (ADR-008), a deployed API serves the public
catalog and refuses everything that needs an account. That is the honest
state rather than a broken one — see below.

---

## 2. The web app

| | |
|---|---|
| Dockerfile | `deploy/web.Dockerfile` |
| Build context | `/` (repository root) |
| Port | `8080` |

### Build argument

| Argument | Value |
|---|---|
| `API_BASE_URL` | the API service's public URL, **with a trailing slash** |

Baked in at build time, because Flutter web resolves
`String.fromEnvironment` during compilation. Pointing a deployment at a
different API is a rebuild, not a restart.

**Leave it empty and the app still works.** With no API configured it
opens on the reviewed pack bundled into the build — the same missions,
rubric and scoring, read from the build instead of fetched — and the
banner says nothing is being sent anywhere. That is a real capability,
not a placeholder, and it is what makes a link worth sending before the
backend is up.

---

## Order

The two point at each other, so one of them is configured twice:

1. Deploy the **API** with `EVIDENCE_GYM_CORS_ORIGINS` left empty.
2. Deploy the **web app** with `API_BASE_URL` set to the API's URL.
3. Set `EVIDENCE_GYM_CORS_ORIGINS` on the API to the web app's URL and
   restart it.

Step 3 is the one that gets forgotten, and its symptom is misleading:
the site loads, looks fine, and every request fails silently in the
browser console. The app will report itself offline and fall back to the
bundled pack, which looks like a working product until someone tries to
sign in.

---

## Checking it worked

```
python contracts/conformance_probe.py https://your-api-host
```

Reports which of the ten contract operations are served, whether CORS
accepts the web origin, and whether an identity verifier is present. It
reads the operation list out of `contracts/openapi.yaml`, so it cannot
drift from the contract, and it checks the two things that are invisible
from the server side — CORS and the verifier — where `curl` succeeds and
only a browser fails.

## What a deployed copy does not do

- **Sign in.** No Firebase, and the development credentials must not be
  enabled on a public host.
- **Store reports.** `POST /reports` answers `503` by design: the
  contract forbids returning `202` before a report is durably stored,
  and no store is configured. See issue #33.
- **Show the scoring ladder or a streak live.** Neither
  `Mission.rubric` nor a streak is in the contract yet; the client
  parses both defensively and will show them the moment the API sends
  them.
