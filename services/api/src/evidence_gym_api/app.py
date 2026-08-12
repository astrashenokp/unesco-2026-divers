"""FastAPI application factory."""

from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
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
from evidence_gym_api.trace import TRACE_ID_HEADER, get_trace_id, normalize_trace_id


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
) -> FastAPI:
    """Create an API instance with explicit runtime dependencies."""

    app = FastAPI(
        title="Evidence Gym API",
        version="0.1.0",
        description="Evidence-first media and information literacy API.",
    )
    app.state.readiness_probe = readiness_probe or StaticReadinessProbe()
    app.state.identity_verifier = identity_verifier
    app.state.learning_services = learning_services
    app.state.catalog_reader = catalog_reader
    app.add_middleware(TraceIdMiddleware)
    app.include_router(router)
    app.include_router(catalog_router)
    app.include_router(learning_router)

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

    return app
