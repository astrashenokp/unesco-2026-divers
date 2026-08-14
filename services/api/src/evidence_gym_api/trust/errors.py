"""Stable application failures for learner content reports."""


class ReportPersistenceUnavailable(Exception):
    """The report could not be durably committed."""
