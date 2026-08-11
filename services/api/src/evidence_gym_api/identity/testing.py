"""Deterministic identity adapter for unit tests and local composition."""

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.ports import IdentityVerificationError


class FakeIdentityVerifier:
    def __init__(self, tokens: dict[str, Principal] | None = None) -> None:
        self._tokens = dict(tokens or {})

    async def verify(self, bearer_token: str) -> Principal:
        try:
            return self._tokens[bearer_token]
        except KeyError as exc:
            raise IdentityVerificationError("credential is invalid") from exc

