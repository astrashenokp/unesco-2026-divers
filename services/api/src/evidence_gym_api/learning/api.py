"""Thin HTTP boundary for learning use cases."""

from dataclasses import dataclass
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request, status
from pydantic import BaseModel, ConfigDict, Field

from evidence_gym_api.identity.dependencies import current_principal
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.attempt import Attempt, Confidence, Reaction
from evidence_gym_api.learning.use_cases import (
    StartAttempt,
    StartAttemptCommand,
    SubmitPrediction,
    SubmitPredictionCommand,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    MissionId,
    MissionVersion,
)
from evidence_gym_api.problem import ApiProblem

router = APIRouter(tags=["learning"])


@dataclass(frozen=True, slots=True)
class LearningServices:
    start_attempt: StartAttempt
    submit_prediction: SubmitPrediction


class StartAttemptBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    missionId: str = Field(min_length=1)
    missionVersion: str = Field(min_length=1)


class PredictionBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    reaction: Reaction
    confidence: int = Field(ge=0, le=100)
    version: int = Field(ge=1)


class AttemptResponse(BaseModel):
    id: str
    missionId: str
    missionVersion: str
    state: str
    version: int

    @classmethod
    def from_domain(cls, attempt: Attempt) -> "AttemptResponse":
        return cls(
            id=attempt.id.value,
            missionId=attempt.mission_id.value,
            missionVersion=attempt.mission_version.value,
            state=attempt.state.value,
            version=attempt.version,
        )


def learning_services(request: Request) -> LearningServices:
    services: LearningServices | None = getattr(
        request.app.state, "learning_services", None
    )
    if services is None:
        raise ApiProblem(
            status=503,
            code="learning-service-unavailable",
            title="Service not ready",
            detail="Learning services are unavailable.",
        )
    return services


PrincipalDependency = Annotated[Principal, Depends(current_principal)]
ServicesDependency = Annotated[LearningServices, Depends(learning_services)]
IdempotencyHeader = Annotated[
    str,
    Header(alias="Idempotency-Key", min_length=8, max_length=128),
]


@router.post(
    "/attempts",
    operation_id="startAttempt",
    response_model=AttemptResponse,
    response_model_by_alias=True,
    status_code=status.HTTP_201_CREATED,
)
async def start_attempt(
    body: StartAttemptBody,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> AttemptResponse:
    attempt = await services.start_attempt.execute(
        principal,
        StartAttemptCommand(
            mission_id=MissionId(body.missionId),
            mission_version=MissionVersion(body.missionVersion),
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return AttemptResponse.from_domain(attempt)


@router.post(
    "/attempts/{attemptId}/prediction",
    operation_id="submitPrediction",
    response_model=AttemptResponse,
    response_model_by_alias=True,
)
async def submit_prediction(
    attemptId: str,
    body: PredictionBody,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> AttemptResponse:
    attempt = await services.submit_prediction.execute(
        principal,
        SubmitPredictionCommand(
            attempt_id=AttemptId(attemptId),
            reaction=body.reaction,
            confidence=Confidence.known(body.confidence),
            version=body.version,
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return AttemptResponse.from_domain(attempt)
