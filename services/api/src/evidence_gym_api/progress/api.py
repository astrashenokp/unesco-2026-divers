"""HTTP boundary for the authenticated learner progress projection."""

from dataclasses import dataclass
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, ConfigDict, Field

from evidence_gym_api.identity.dependencies import current_principal
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.ports import ProgressResult
from evidence_gym_api.problem import ApiProblem
from evidence_gym_api.progress.use_cases import GetMyProgress

router = APIRouter(tags=["progress"])


@dataclass(frozen=True, slots=True)
class ProgressServices:
    get_my_progress: GetMyProgress


class SkillProgressResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    skill: str
    mastery: float = Field(ge=0, le=1)
    dueAt: datetime | None = None


class ProgressResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    totalXp: int = Field(ge=0)
    skills: list[SkillProgressResponse]

    @classmethod
    def from_domain(cls, progress: ProgressResult) -> "ProgressResponse":
        return cls(
            totalXp=progress.total_xp,
            skills=[
                SkillProgressResponse(
                    skill=item.skill,
                    mastery=item.mastery,
                    dueAt=item.due_at,
                )
                for item in progress.skills
            ],
        )


def progress_services(request: Request) -> ProgressServices:
    services: ProgressServices | None = getattr(
        request.app.state, "progress_services", None
    )
    if services is None:
        raise ApiProblem(
            status=503,
            code="progress-service-unavailable",
            title="Service not ready",
            detail="Progress services are unavailable.",
        )
    return services


PrincipalDependency = Annotated[Principal, Depends(current_principal)]
ServicesDependency = Annotated[ProgressServices, Depends(progress_services)]


@router.get(
    "/me/progress",
    operation_id="getMyProgress",
    response_model=ProgressResponse,
)
async def get_my_progress(
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> ProgressResponse:
    progress = await services.get_my_progress.execute(principal)
    return ProgressResponse.from_domain(progress)
