"""Contract-compatible Problem Details responses."""

from dataclasses import dataclass

from fastapi.responses import JSONResponse


@dataclass(slots=True)
class ApiProblem(Exception):
    """An expected API failure safe to expose to the caller."""

    status: int
    code: str
    title: str
    detail: str | None = None
    type: str = "about:blank"


def problem_response(problem: ApiProblem, trace_id: str) -> JSONResponse:
    """Serialize the exact fields required by the normative OpenAPI contract."""

    body: dict[str, str | int] = {
        "type": problem.type,
        "title": problem.title,
        "status": problem.status,
        "code": problem.code,
        "traceId": trace_id,
    }
    if problem.detail is not None:
        body["detail"] = problem.detail
    return JSONResponse(
        status_code=problem.status,
        content=body,
        media_type="application/problem+json",
    )

