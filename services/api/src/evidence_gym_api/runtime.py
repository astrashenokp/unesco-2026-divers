"""Fail-closed runtime configuration for local and deployed API processes."""

from __future__ import annotations

from collections.abc import Mapping
from urllib.parse import urlsplit

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.ports import IdentityVerifier
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.value_objects import LearnerId


class RuntimeConfigurationError(RuntimeError):
    """Raised when an unsafe or malformed runtime setting is requested."""


def cors_allowed_origins(environment: Mapping[str, str]) -> tuple[str, ...]:
    """Return a normalized, explicit CORS allowlist from the environment."""

    configured = environment.get("EVIDENCE_GYM_CORS_ORIGINS", "")
    origins: list[str] = []
    for candidate in configured.split(","):
        origin = candidate.strip().rstrip("/")
        if not origin:
            continue
        parsed = urlsplit(origin)
        if (
            origin == "*"
            or parsed.scheme not in {"http", "https"}
            or not parsed.netloc
            or parsed.username is not None
            or parsed.password is not None
            or parsed.path
            or parsed.query
            or parsed.fragment
        ):
            raise RuntimeConfigurationError(
                "EVIDENCE_GYM_CORS_ORIGINS must contain explicit HTTP(S) origins"
            )
        if origin not in origins:
            origins.append(origin)
    return tuple(origins)


def identity_verifier(environment: Mapping[str, str]) -> IdentityVerifier | None:
    """Build the explicitly enabled local verifier; otherwise fail closed."""

    enabled = _boolean(environment.get("EVIDENCE_GYM_DEV_IDENTITY_ENABLED", "false"))
    if not enabled:
        return None
    if environment.get("EVIDENCE_GYM_ENV", "production").strip().lower() != "development":
        raise RuntimeConfigurationError(
            "development identity may only be enabled when EVIDENCE_GYM_ENV=development"
        )

    token = environment.get("EVIDENCE_GYM_DEV_IDENTITY_TOKEN", "").strip()
    learner_id = environment.get("EVIDENCE_GYM_DEV_LEARNER_ID", "").strip()
    if len(token) < 16 or not learner_id:
        raise RuntimeConfigurationError(
            "development identity requires a token of at least 16 characters and a learner ID"
        )
    return FakeIdentityVerifier({token: Principal(LearnerId(learner_id))})


def _boolean(value: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes"}:
        return True
    if normalized in {"false", "0", "no", ""}:
        return False
    raise RuntimeConfigurationError("boolean runtime settings must be true or false")

