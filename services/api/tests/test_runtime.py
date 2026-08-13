"""Runtime configuration and browser boundary tests."""

import asyncio

import pytest
from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app
from evidence_gym_api.identity.ports import IdentityVerificationError
from evidence_gym_api.runtime import (
    RuntimeConfigurationError,
    cors_allowed_origins,
    identity_verifier,
)


WEB_ORIGIN = "http://localhost:8080"


def test_configured_web_origin_passes_authenticated_preflight() -> None:
    with TestClient(create_app(cors_allowed_origins=(WEB_ORIGIN,))) as client:
        response = client.options(
            "/v1/attempts",
            headers={
                "Origin": WEB_ORIGIN,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": (
                    "Authorization, Content-Type, Idempotency-Key"
                ),
            },
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == WEB_ORIGIN
    assert "POST" in response.headers["access-control-allow-methods"]
    allowed_headers = response.headers["access-control-allow-headers"].lower()
    assert "authorization" in allowed_headers
    assert "idempotency-key" in allowed_headers


def test_unconfigured_origin_receives_no_cors_authorization() -> None:
    with TestClient(create_app(cors_allowed_origins=(WEB_ORIGIN,))) as client:
        response = client.get(
            "/health", headers={"Origin": "https://untrusted.example"}
        )

    assert "access-control-allow-origin" not in response.headers


def test_cors_configuration_rejects_wildcards_and_non_origins() -> None:
    with pytest.raises(RuntimeConfigurationError):
        cors_allowed_origins({"EVIDENCE_GYM_CORS_ORIGINS": "*"})
    with pytest.raises(RuntimeConfigurationError):
        cors_allowed_origins(
            {"EVIDENCE_GYM_CORS_ORIGINS": "https://learner.example/path"}
        )


def test_development_identity_is_disabled_by_default() -> None:
    assert identity_verifier({}) is None


def test_development_identity_cannot_be_enabled_outside_development() -> None:
    with pytest.raises(RuntimeConfigurationError):
        identity_verifier(
            {
                "EVIDENCE_GYM_ENV": "production",
                "EVIDENCE_GYM_DEV_IDENTITY_ENABLED": "true",
                "EVIDENCE_GYM_DEV_IDENTITY_TOKEN": "local-token-long-enough",
                "EVIDENCE_GYM_DEV_LEARNER_ID": "local-learner",
            }
        )


def test_development_identity_accepts_only_the_explicit_token() -> None:
    verifier = identity_verifier(
        {
            "EVIDENCE_GYM_ENV": "development",
            "EVIDENCE_GYM_DEV_IDENTITY_ENABLED": "true",
            "EVIDENCE_GYM_DEV_IDENTITY_TOKEN": "local-token-long-enough",
            "EVIDENCE_GYM_DEV_LEARNER_ID": "local-learner",
        }
    )

    assert verifier is not None
    principal = asyncio.run(verifier.verify("local-token-long-enough"))
    assert principal.subject.value == "local-learner"
    with pytest.raises(IdentityVerificationError):
        asyncio.run(verifier.verify("any-other-token"))

