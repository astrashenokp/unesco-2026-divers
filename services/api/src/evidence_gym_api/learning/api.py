"""Thin HTTP boundary for learning use cases."""

from dataclasses import dataclass
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request, status
from pydantic import BaseModel, ConfigDict, Field

from evidence_gym_api.identity.dependencies import current_principal
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Confidence,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.learning.use_cases import (
    StartAttempt,
    StartAttemptCommand,
    SubmitPrediction,
    SubmitPredictionCommand,
    UseEvidenceAction,
    UseEvidenceActionCommand,
    RequestHint,
    RequestHintCommand,
    CompleteAttempt,
    CompleteAttemptCommand,
)
from evidence_gym_api.learning.ports import CompletionResult, EvidenceActionResult
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
    use_evidence_action: UseEvidenceAction | None = None
    request_hint: RequestHint | None = None
    complete_attempt: CompleteAttempt | None = None


class StartAttemptBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    missionId: str = Field(min_length=1)
    missionVersion: str = Field(min_length=1)


class PredictionBody(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    reaction: Reaction
    confidence: int = Field(ge=0, le=100)
    version: int = Field(ge=1)


class EvidenceActionBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    actionId: str = Field(min_length=1)
    input: dict[str, object] = Field(default_factory=dict, max_length=10)
    version: int = Field(ge=1)


class EvidenceItemResponse(BaseModel):
    evidenceId: str
    type: str
    title: str
    sourceUrl: str | None = None
    retrievedAt: datetime
    verificationStatus: str


class EvidenceResultResponse(BaseModel):
    actionId: str
    status: str
    items: list[EvidenceItemResponse]
    limitations: list[str]
    attemptVersion: int = Field(ge=1)

    @classmethod
    def from_domain(cls, result: EvidenceActionResult) -> "EvidenceResultResponse":
        evidence = result.evidence
        return cls(
            actionId=evidence.action_id,
            status=evidence.status.value,
            items=[
                EvidenceItemResponse(
                    evidenceId=item.evidence_id,
                    type=item.type,
                    title=item.title,
                    sourceUrl=item.source_url,
                    retrievedAt=item.retrieved_at,
                    verificationStatus=item.verification_status.value,
                )
                for item in evidence.items
            ],
            limitations=list(evidence.limitations),
            attemptVersion=result.attempt_version,
        )


class HintResponse(BaseModel):
    text: str = Field(min_length=1, max_length=600)
    level: int = Field(ge=1, le=4)
    suggestedActionId: str | None = None
    evidenceRefs: list[str]
    uncertainty: str
    safetyFlags: list[str]
    fallback: bool


class AxisAssessmentBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    label: str = Field(min_length=1)
    confidence: int = Field(ge=0, le=100)

    def to_domain(self) -> AxisAssessment:
        return AxisAssessment(self.label, Confidence.known(self.confidence))


class ConclusionBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    authenticity: AxisAssessmentBody
    claimVeracity: AxisAssessmentBody
    contextIntegrity: AxisAssessmentBody
    postConfidence: int = Field(ge=0, le=100)
    shareDecision: ShareDecision
    version: int = Field(ge=1)


class SkillProgressResponse(BaseModel):
    skill: str
    mastery: float = Field(ge=0, le=1)
    dueAt: datetime | None = None


class ProgressResponse(BaseModel):
    totalXp: int = Field(ge=0)
    skills: list[SkillProgressResponse]


class CompletionResponse(BaseModel):
    receiptId: str
    xpAwarded: int = Field(ge=0)
    progress: ProgressResponse

    @classmethod
    def from_domain(cls, result: CompletionResult) -> "CompletionResponse":
        return cls(
            receiptId=result.receipt_id,
            xpAwarded=result.xp_awarded,
            progress=ProgressResponse(
                totalXp=result.progress.total_xp,
                skills=[
                    SkillProgressResponse(
                        skill=item.skill,
                        mastery=item.mastery,
                        dueAt=item.due_at,
                    )
                    for item in result.progress.skills
                ],
            ),
        )


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


@router.post(
    "/attempts/{attemptId}/evidence-actions",
    operation_id="useEvidenceAction",
    response_model=EvidenceResultResponse,
)
async def use_evidence_action(
    attemptId: str,
    body: EvidenceActionBody,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> EvidenceResultResponse:
    if services.use_evidence_action is None:
        raise ApiProblem(
            status=503,
            code="evidence-service-unavailable",
            title="Service not ready",
            detail="Evidence services are unavailable.",
        )
    result = await services.use_evidence_action.execute(
        principal,
        UseEvidenceActionCommand(
            attempt_id=AttemptId(attemptId),
            action_id=body.actionId,
            input=body.input,
            version=body.version,
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return EvidenceResultResponse.from_domain(result)


@router.post(
    "/attempts/{attemptId}/hints",
    operation_id="requestHint",
    response_model=HintResponse,
)
async def request_hint(
    attemptId: str,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> HintResponse:
    if services.request_hint is None:
        raise ApiProblem(
            status=503,
            code="coach-service-unavailable",
            title="Service not ready",
            detail="Coaching services are unavailable.",
        )
    hint = await services.request_hint.execute(
        principal,
        RequestHintCommand(
            attempt_id=AttemptId(attemptId),
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return HintResponse(
        text=hint.text,
        level=hint.level,
        suggestedActionId=hint.suggested_action_id,
        evidenceRefs=list(hint.evidence_refs),
        uncertainty=hint.uncertainty.value,
        safetyFlags=list(hint.safety_flags),
        fallback=hint.fallback,
    )


@router.post(
    "/attempts/{attemptId}/conclusion",
    operation_id="completeAttempt",
    response_model=CompletionResponse,
)
async def complete_attempt(
    attemptId: str,
    body: ConclusionBody,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> CompletionResponse:
    if services.complete_attempt is None:
        raise ApiProblem(
            status=503,
            code="completion-service-unavailable",
            title="Service not ready",
            detail="Completion services are unavailable.",
        )
    result = await services.complete_attempt.execute(
        principal,
        CompleteAttemptCommand(
            attempt_id=AttemptId(attemptId),
            authenticity=body.authenticity.to_domain(),
            claim_veracity=body.claimVeracity.to_domain(),
            context_integrity=body.contextIntegrity.to_domain(),
            post_confidence=Confidence.known(body.postConfidence),
            share_decision=body.shareDecision,
            version=body.version,
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return CompletionResponse.from_domain(result)
