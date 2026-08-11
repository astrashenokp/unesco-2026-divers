"""Dependency-free operational endpoints."""

from typing import Protocol

from fastapi import APIRouter, Request

from evidence_gym_api.problem import ApiProblem

router = APIRouter(include_in_schema=False)


class ReadinessProbe(Protocol):
    """Runtime dependency readiness boundary supplied by Role 4 integrations."""

    async def is_ready(self) -> bool: ...


class StaticReadinessProbe:
    """Ready-by-default probe for the dependency-free scaffold."""

    async def is_ready(self) -> bool:
        return True


@router.get("/health")
async def health() -> dict[str, str]:
    """Report process liveness without checking external dependencies."""

    return {"status": "alive"}


@router.get("/ready")
async def ready(request: Request) -> dict[str, str]:
    """Report whether required runtime dependencies can serve traffic."""

    probe: ReadinessProbe = request.app.state.readiness_probe
    if not await probe.is_ready():
        raise ApiProblem(
            status=503,
            code="service_not_ready",
            title="Service not ready",
            detail="Required runtime dependencies are unavailable.",
        )
    return {"status": "ready"}

