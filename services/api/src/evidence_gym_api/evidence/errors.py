"""Safe evidence lookup failures."""


class EvidenceProviderError(Exception):
    """Base evidence-provider failure."""


class EvidenceMissionNotFound(EvidenceProviderError):
    """The exact mission version is unavailable."""


class EvidenceActionNotFound(EvidenceProviderError):
    """The action is not defined by the pinned mission version."""

