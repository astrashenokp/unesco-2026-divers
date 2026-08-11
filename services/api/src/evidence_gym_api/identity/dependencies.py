"""FastAPI authentication dependency."""

from fastapi import Header, Request

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.ports import IdentityVerificationError, IdentityVerifier
from evidence_gym_api.problem import ApiProblem


async def current_principal(
    request: Request,
    authorization: str | None = Header(default=None, alias="Authorization"),
) -> Principal:
    if authorization is None or not authorization.startswith("Bearer "):
        raise ApiProblem(
            status=401,
            code="authentication-required",
            title="Authentication required",
            detail="A valid Firebase ID token is required.",
        )
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise ApiProblem(
            status=401,
            code="authentication-required",
            title="Authentication required",
            detail="A valid Firebase ID token is required.",
        )

    verifier: IdentityVerifier | None = getattr(
        request.app.state, "identity_verifier", None
    )
    if verifier is None:
        raise ApiProblem(
            status=503,
            code="identity-verifier-unavailable",
            title="Service not ready",
            detail="Identity verification is unavailable.",
        )
    try:
        return await verifier.verify(token)
    except IdentityVerificationError as exc:
        raise ApiProblem(
            status=401,
            code="invalid-authentication",
            title="Authentication failed",
            detail="The Firebase ID token is invalid or expired.",
        ) from exc

