"""HTTP boundary for authenticated learner content reports."""

from dataclasses import dataclass
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Header, Request, Response, status
from pydantic import BaseModel, ConfigDict, Field

from data_access.db import Database
from evidence_gym_api.identity.dependencies import current_principal
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.value_objects import IdempotencyKey, MissionId
from evidence_gym_api.persistence import ServicesFactory
from evidence_gym_api.problem import ApiProblem
from evidence_gym_api.trust.use_cases import SubmitReport, SubmitReportCommand

router = APIRouter(tags=["trust"])


@dataclass(frozen=True, slots=True)
class ReportServices:
    submit_report: SubmitReport


class ReportBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    missionId: str
    reason: Literal[
        "incorrect",
        "harmful",
        "outdated",
        "copyright",
        "accessibility",
        "other",
    ]
    # Missing means no detail; an explicit JSON null is rejected because the
    # normative schema allows an optional string, not a nullable value.
    detail: str = Field(default=None, max_length=1000)


async def report_services(request: Request):
    services: ReportServices | None = getattr(
        request.app.state, "report_services", None
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
            code="report-service-unavailable",
            title="Service not ready",
            detail="Report services are unavailable.",
        )
    async with database.session() as session:
        yield factory.reports(session)


PrincipalDependency = Annotated[Principal, Depends(current_principal)]
ServicesDependency = Annotated[ReportServices, Depends(report_services)]
IdempotencyHeader = Annotated[
    str,
    Header(alias="Idempotency-Key", min_length=8, max_length=128),
]


@router.post(
    "/reports",
    operation_id="reportContent",
    status_code=status.HTTP_202_ACCEPTED,
    response_class=Response,
    responses={
        202: {
            "description": (
                "Accepted and durably recorded; exposes no moderation state."
            )
        }
    },
)
async def submit_report(
    body: ReportBody,
    idempotency_key: IdempotencyHeader,
    principal: PrincipalDependency,
    services: ServicesDependency,
) -> Response:
    await services.submit_report.execute(
        principal,
        SubmitReportCommand(
            mission_id=MissionId(body.missionId),
            reason=body.reason,
            detail=body.detail,
            idempotency_key=IdempotencyKey(idempotency_key),
        ),
    )
    return Response(status_code=status.HTTP_202_ACCEPTED)
