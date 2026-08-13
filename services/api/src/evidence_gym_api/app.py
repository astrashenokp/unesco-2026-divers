"""FastAPI application factory."""

from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from evidence_gym_api.catalog.api import PublicCatalogReader, router as catalog_router
from evidence_gym_api.operational import ReadinessProbe, StaticReadinessProbe, router
from evidence_gym_api.identity.ports import IdentityVerifier
from evidence_gym_api.learning.api import LearningServices, router as learning_router
from evidence_gym_api.learning.attempt import DomainError, IllegalAttemptTransition
from evidence_gym_api.learning.errors import (
    AttemptAccessDenied,
    AttemptNotFound,
    IdempotencyConflict,
    MissionNotFound,
    RepositoryConflict,
    StaleAttemptVersion,
)
from evidence_gym_api.problem import ApiProblem, problem_response
from evidence_gym_api.evidence.errors import (
    EvidenceActionNotFound,
    EvidenceMissionNotFound,
)
from evidence_gym_api.coach.errors import CoachProviderError
from evidence_gym_api.trace import TRACE_ID_HEADER, get_trace_id, normalize_trace_id
from evidence_gym_api.receipt.api import ReceiptServices, router as receipt_router
from evidence_gym_api.receipt.use_cases import ReceiptNotFound
from evidence_gym_api.progress.api import ProgressServices, router as progress_router


class TraceIdMiddleware(BaseHTTPMiddleware):
    """Propagate a safe correlation identifier without logging request content."""

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[JSONResponse]],
    ):
        trace_id = normalize_trace_id(request.headers.get(TRACE_ID_HEADER))
        request.state.trace_id = trace_id
        response = await call_next(request)
        response.headers[TRACE_ID_HEADER] = trace_id
        return response


def create_app(
    readiness_probe: ReadinessProbe | None = None,
    *,
    identity_verifier: IdentityVerifier | None = None,
    learning_services: LearningServices | None = None,
    catalog_reader: PublicCatalogReader | None = None,
    cors_allowed_origins: tuple[str, ...] = (),
    path_prefix: str = "",
    receipt_services: ReceiptServices | None = None,
    progress_services: ProgressServices | None = None,
) -> FastAPI:
    """Create an API instance with explicit runtime dependencies.

    ``path_prefix`` mounts the API under a base path. The contract
    declares ``servers: https://…/v1``, so a conforming client asks for
    ``/v1/catalog/path`` while an unprefixed app serves
    ``/catalog/path`` — both sides internally correct, every request a
    404. Only a real client finds this; no unit test on either side can.

    Defaults to empty so the existing tests, which call the routes
    directly, keep passing unchanged. ``main.py`` sets the value the
    contract promises."""

    app = FastAPI(
        title="Evidence Gym API",
        version="0.1.0",
        description="Evidence-first media and information literacy API.",
    )
    app.state.readiness_probe = readiness_probe or StaticReadinessProbe()
    app.state.identity_verifier = identity_verifier
    app.state.learning_services = learning_services
    app.state.catalog_reader = catalog_reader
    app.state.receipt_services = receipt_services
    app.state.progress_services = progress_services
    app.add_middleware(TraceIdMiddleware)
    if cors_allowed_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(cors_allowed_origins),
            allow_credentials=False,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
        )
    # Operational probes stay at the root: a load balancer checking
    # /health should not need to know the API's version prefix.
    app.include_router(router)
    app.include_router(catalog_router, prefix=path_prefix)
    app.include_router(learning_router, prefix=path_prefix)
    app.include_router(receipt_router, prefix=path_prefix)
    app.include_router(progress_router, prefix=path_prefix)

    @app.exception_handler(ApiProblem)
    async def handle_api_problem(request: Request, exc: ApiProblem) -> JSONResponse:
        return problem_response(exc, get_trace_id(request))

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        problem = ApiProblem(
            status=422,
            code="request_validation_failed",
            title="Request validation failed",
            detail="The request did not match the expected shape.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_error(
        request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        title = "Not found" if exc.status_code == 404 else "Request failed"
        problem = ApiProblem(
            status=exc.status_code,
            code="route_not_found" if exc.status_code == 404 else "http_error",
            title=title,
            detail=title,
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(AttemptNotFound)
    @app.exception_handler(AttemptAccessDenied)
    async def handle_hidden_attempt_error(
        request: Request, exc: AttemptNotFound | AttemptAccessDenied
    ) -> JSONResponse:
        problem = ApiProblem(
            status=404,
            code="attempt-not-found",
            title="Attempt not found",
            detail="The attempt was not found.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(MissionNotFound)
    async def handle_mission_not_found(
        request: Request, exc: MissionNotFound
    ) -> JSONResponse:
        problem = ApiProblem(
            status=409,
            code="mission-version-unavailable",
            title="Mission version unavailable",
            detail="The exact mission version cannot be started.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(ReceiptNotFound)
    async def handle_receipt_not_found(
        request: Request, exc: ReceiptNotFound
    ) -> JSONResponse:
        problem = ApiProblem(
            status=404,
            code="receipt-not-found",
            title="Receipt not found",
            detail="The receipt was not found.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(EvidenceActionNotFound)
    @app.exception_handler(EvidenceMissionNotFound)
    async def handle_evidence_not_found(
        request: Request, exc: EvidenceActionNotFound | EvidenceMissionNotFound
    ) -> JSONResponse:
        problem = ApiProblem(
            status=404,
            code="evidence-action-not-found",
            title="Evidence action not found",
            detail="The evidence action was not found for this mission.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(IdempotencyConflict)
    async def handle_idempotency_conflict(
        request: Request, exc: IdempotencyConflict
    ) -> JSONResponse:
        problem = ApiProblem(
            status=409,
            code="idempotency-key-conflict",
            title="Idempotency key conflict",
            detail="The idempotency key was already used for another request.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(StaleAttemptVersion)
    async def handle_stale_version(
        request: Request, exc: StaleAttemptVersion
    ) -> JSONResponse:
        problem = ApiProblem(
            status=409,
            code="stale-attempt-version",
            title="Attempt version conflict",
            detail="The attempt was modified by another request.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(IllegalAttemptTransition)
    @app.exception_handler(RepositoryConflict)
    async def handle_attempt_conflict(
        request: Request, exc: IllegalAttemptTransition | RepositoryConflict
    ) -> JSONResponse:
        problem = ApiProblem(
            status=409,
            code="attempt-conflict",
            title="Attempt conflict",
            detail="The requested attempt operation cannot be applied.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(DomainError)
    async def handle_domain_error(
        request: Request, exc: DomainError
    ) -> JSONResponse:
        problem = ApiProblem(
            status=422,
            code="domain-validation-failed",
            title="Request validation failed",
            detail="The request contains an invalid domain value.",
        )
        return problem_response(problem, get_trace_id(request))

    @app.exception_handler(CoachProviderError)
    async def handle_coach_unavailable(
        request: Request, exc: CoachProviderError
    ) -> JSONResponse:
        problem = ApiProblem(
            status=503,
            code="coach-unavailable",
            title="Coach unavailable",
            detail="A safe coaching response is temporarily unavailable.",
        )
        return problem_response(problem, get_trace_id(request))

    return app
