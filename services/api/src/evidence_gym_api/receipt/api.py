"""HTTP boundary for immutable Evidence Receipts."""

from dataclasses import dataclass
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, ConfigDict, Field

from data_access.db import Database
from evidence_gym_api.identity.dependencies import current_principal
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.persistence import ServicesFactory
from evidence_gym_api.problem import ApiProblem
from evidence_gym_api.receipt.model import EvidenceReceipt
from evidence_gym_api.receipt.use_cases import GetReceipt

router = APIRouter(tags=["receipts"])


@dataclass(frozen=True, slots=True)
class ReceiptServices:
    get_receipt: GetReceipt


class ReceiptAssessmentResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    label: str
    confidence: int = Field(ge=0, le=100)


class ReceiptResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    attemptId: str
    missionVersion: str
    assessments: list[ReceiptAssessmentResponse] = Field(min_length=3, max_length=3)
    evidenceRefs: list[str]
    createdAt: datetime
    hash: str
    disclaimer: str

    @classmethod
    def from_domain(cls, receipt: EvidenceReceipt) -> "ReceiptResponse":
        return cls(
            id=receipt.id,
            attemptId=receipt.attempt_id,
            missionVersion=receipt.mission_version,
            assessments=[
                ReceiptAssessmentResponse(
                    label=assessment.label,
                    confidence=assessment.confidence.value,
                )
                for assessment in receipt.assessments
            ],
            evidenceRefs=list(receipt.evidence_refs),
            createdAt=receipt.created_at,
            hash=receipt.hash,
            disclaimer=receipt.disclaimer,
        )


async def receipt_services(request: Request) -> ReceiptServices:
    services: ReceiptServices | None = getattr(
        request.app.state, "receipt_services", None
    )
    if services is not None:
        yield services
        return
    factory: ServicesFactory | None = getattr(
        request.app.state, "services_factory", None
    )
    database: Database | None = getattr(request.app.state, "database", None)
    if factory is None or database is None:
        raise ApiProblem(
            status=503,
            code="receipt-service-unavailable",
            title="Service not ready",
            detail="Receipt services are unavailable.",
        )
    async with database.session() as session:
        yield factory.receipt(session)


PrincipalDependency = Annotated[Principal, Depends(current_principal)]
ServicesDependency = Annotated[ReceiptServices, Depends(receipt_services)]


@router.get(
    "/receipts/{receiptId}",
    operation_id="getReceipt",
    response_model=ReceiptResponse,
)
async def get_receipt(
    receiptId: str,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> ReceiptResponse:
    receipt = await services.get_receipt.execute(principal, receiptId)
    return ReceiptResponse.from_domain(receipt)
