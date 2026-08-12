"""Failures that must degrade to a reviewed deterministic hint."""


class CoachProviderError(RuntimeError):
    """Raised when no safe model or deterministic coach hint can be returned."""
