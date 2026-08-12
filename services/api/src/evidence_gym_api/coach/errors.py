"""Coach provider failure types hidden behind deterministic fallback."""


class CoachProviderError(RuntimeError):
    """Raised when no safe model or deterministic coach hint can be returned."""
