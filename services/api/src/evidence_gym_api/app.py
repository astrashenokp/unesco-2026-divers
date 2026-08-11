"""FastAPI application factory."""

from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from evidence_gym_api.operational import ReadinessProbe, StaticReadinessProbe, router
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


def create_app(readiness_probe: ReadinessProbe | None = None) -> FastAPI:
    """Create an API instance with explicit runtime dependencies."""

    app = FastAPI(
        title="Evidence Gym API",
        version="0.1.0",
        description="Evidence-first media and information literacy API.",
    )
    app.state.readiness_probe = readiness_probe or StaticReadinessProbe()
    app.add_middleware(TraceIdMiddleware)
    app.include_router(router)

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

    return app

