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

    principals = {token: Principal(LearnerId(learner_id))}

    # A second, optional account carrying the operator role.
    #
    # Roles have always been on ``Principal`` and nothing set them, so
    # there was no way to sign in as anything but a learner. This is what
    # makes an operator account demonstrable without inventing a parallel
    # login path.
    #
    # It is opt-in on top of an already opt-in verifier, and it inherits
    # every guard above: development only, explicit token, minimum
    # length. Configuring one without the other simply means there is no
    # operator account, rather than a broken one.
    admin_token = environment.get("EVIDENCE_GYM_DEV_ADMIN_TOKEN", "").strip()
    admin_id = environment.get("EVIDENCE_GYM_DEV_ADMIN_ID", "").strip()
    if admin_token or admin_id:
        if len(admin_token) < 16 or not admin_id:
            raise RuntimeConfigurationError(
                "development operator identity requires a token of at least "
                "16 characters and an operator ID"
            )
        if admin_token == token:
            # Two accounts sharing one credential is one account wearing
            # two hats, and the role check would then be meaningless.
            raise RuntimeConfigurationError(
                "the operator token must differ from the learner token"
            )
        principals[admin_token] = Principal(
            LearnerId(admin_id), roles=frozenset({"operator"})
        )

    return FakeIdentityVerifier(principals)


def _boolean(value: str) -> bool:
    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes"}:
        return True
    if normalized in {"false", "0", "no", ""}:
        return False
    raise RuntimeConfigurationError("boolean runtime settings must be true or false")

