"""Public catalog boundary backed by reviewed mission fixture projections."""

from typing import Annotated, Any, Protocol

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, ConfigDict, Field

from evidence_gym_api.learning.value_objects import MissionId
from evidence_gym_api.problem import ApiProblem

router = APIRouter(tags=["catalog"])


class PublicCatalogReader(Protocol):
    async def get_learning_path(self) -> dict[str, Any]: ...

    async def get_public_mission(
        self, mission_id: MissionId
    ) -> dict[str, Any] | None: ...


class LearningPathNodeResponse(BaseModel):
    missionId: str
    title: str
    state: str


class LearningPathResponse(BaseModel):
    version: str
    locale: str
    nodes: list[LearningPathNodeResponse]


class MediaResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    type: str
    url: str | None = None
    altText: str
    transcript: str | None = None


class AccessibilityResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    plainLanguageSummary: str = Field(min_length=1)
    mediaAlternatives: list[str] = Field(min_length=1)
    interactionNotes: list[str] = Field(min_length=1)


class EvidenceActionResponse(BaseModel):
    id: str
    type: str
    label: str


class MissionResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    version: str
    title: str
    claim: str
    media: MediaResponse
    accessibility: AccessibilityResponse
    reactions: list[str]
    evidenceActions: list[EvidenceActionResponse]
    skillTags: list[str]
    testsCriticalIgnoring: bool = False


def catalog_reader(request: Request) -> PublicCatalogReader:
    reader: PublicCatalogReader | None = getattr(
        request.app.state, "catalog_reader", None
    )
    if reader is None:
        raise ApiProblem(
            status=503,
            code="catalog-service-unavailable",
            title="Service not ready",
            detail="Catalog services are unavailable.",
        )
    return reader


CatalogReaderDependency = Annotated[PublicCatalogReader, Depends(catalog_reader)]


@router.get(
    "/catalog/path",
    operation_id="getLearningPath",
    response_model=LearningPathResponse,
)
async def get_learning_path(reader: CatalogReaderDependency) -> dict[str, Any]:
    return await reader.get_learning_path()


@router.get(
    "/missions/{missionId}",
    operation_id="getMission",
    response_model=MissionResponse,
    response_model_exclude_none=True,
)
async def get_mission(
    missionId: str, reader: CatalogReaderDependency
) -> dict[str, Any]:
    mission = await reader.get_public_mission(MissionId(missionId))
    if mission is None:
        raise ApiProblem(
            status=404,
            code="mission-not-found",
            title="Mission not found",
            detail="The mission was not found.",
        )
    return mission
