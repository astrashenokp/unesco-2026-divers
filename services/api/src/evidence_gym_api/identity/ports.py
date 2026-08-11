"""Identity provider boundary owned by Backend & Domain."""

from typing import Protocol

from evidence_gym_api.identity.model import Principal


class IdentityVerificationError(ValueError):
    """A bearer credential could not establish a trusted principal."""


class IdentityVerifier(Protocol):
    async def verify(self, bearer_token: str) -> Principal:
        """Verify a credential without trusting client-supplied identity fields."""

