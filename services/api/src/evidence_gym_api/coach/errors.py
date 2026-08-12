"""Failures that must degrade to a reviewed deterministic hint."""


class CoachProviderError(Exception):
    """The coach could not return a safe, contract-valid response."""

