# The Evidence Gym API, for Northflank or any container host.
#
# Built from the repository root, not from `services/api`, because the
# API depends on two sibling packages by path — `packages/gameplay` and
# `packages/data_access`. A build context narrowed to the service would
# resolve neither.
#
#   docker build -f deploy/api.Dockerfile -t evidence-gym-api .
#
# Content is copied in as well: the catalog is read from
# `content/p0-demo-pack` at runtime, so an image without it starts and
# then answers 404 to every mission.

FROM python:3.13-slim AS base

# Bytecode written at build time rather than on each cold start, and no
# stdout buffering so logs appear when they happen rather than when a
# buffer fills — which matters when the only view of a failing container
# is its log stream.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Dependency manifests first, so a change to source does not invalidate
# the layer that installs them.
COPY packages/gameplay/pyproject.toml packages/gameplay/
COPY packages/data_access/pyproject.toml packages/data_access/
COPY services/api/pyproject.toml services/api/

COPY packages/gameplay/ packages/gameplay/
COPY packages/data_access/ packages/data_access/
COPY services/api/ services/api/

# The reviewed content pack and the schemas it is validated against.
COPY content/ content/
COPY contracts/ contracts/

# The API is installed editable, and that is load-bearing rather than a
# convenience.
#
# `main.py` locates the content pack with
# `Path(__file__).resolve().parents[4]`, so the root it finds depends on
# where the package physically sits. A normal install copies it into
# site-packages, four levels above which is `/usr/local/lib` — and the
# container then starts, fails to read the schemas, and dies with
# `cannot read valid JSON from ...`.
#
# Editable leaves it at /app/services/api/src/evidence_gym_api/, whose
# fourth parent is /app — exactly where content/ and contracts/ are
# copied above.
#
# The alternative is an environment variable for the content root, which
# would be the better design and is a change to Role 2's module rather
# than to this file.
RUN pip install ./packages/gameplay ./packages/data_access
RUN pip install -e ./services/api

# Not root. A web-facing container running as root turns any code
# execution bug into a container takeover.
#
# After the install, not before: an editable install writes an egg-link
# and build metadata into the source tree, and doing it as a user who
# cannot write there fails.
RUN useradd --create-home --uid 10001 evidencegym
RUN chown -R evidencegym:evidencegym /app
USER evidencegym

# Northflank injects PORT; 8080 is the fallback for a plain `docker run`.
ENV PORT=8080
EXPOSE 8080

# Bound to 0.0.0.0 because a container listening on localhost is
# unreachable from outside itself — the most common reason a deployment
# builds, starts, and never answers.
#
# Shell form so ${PORT} expands. `exec` keeps uvicorn as PID 1 so it
# receives SIGTERM and shuts down cleanly instead of being killed after
# the grace period.
CMD exec uvicorn evidence_gym_api.main:app --host 0.0.0.0 --port ${PORT}
