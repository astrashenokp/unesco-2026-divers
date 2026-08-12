"""Curated evidence-action application boundary."""

from evidence_gym_api.evidence.errors import (
    EvidenceActionNotFound,
    EvidenceMissionNotFound,
    EvidenceProviderError,
)
from evidence_gym_api.evidence.model import (
    EvidenceItem,
    EvidenceResult,
    EvidenceStatus,
    VerificationStatus,
)
from evidence_gym_api.evidence.ports import DeterministicEvidenceProvider

__all__ = [
    "DeterministicEvidenceProvider",
    "EvidenceActionNotFound",
    "EvidenceItem",
    "EvidenceMissionNotFound",
    "EvidenceProviderError",
    "EvidenceResult",
    "EvidenceStatus",
    "FixtureDeterministicEvidenceProvider",
    "VerificationStatus",
]


def __getattr__(name: str):
    """Load the catalog-backed adapter lazily to avoid a startup import cycle."""

    if name == "FixtureDeterministicEvidenceProvider":
        from evidence_gym_api.evidence.fixture_provider import (
            FixtureDeterministicEvidenceProvider,
        )

        return FixtureDeterministicEvidenceProvider
    raise AttributeError(name)
