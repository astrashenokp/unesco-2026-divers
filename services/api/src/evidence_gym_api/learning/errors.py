"""Stable application failures for learning use cases."""


class LearningApplicationError(Exception):
    """Base application-layer failure."""


class MissionNotFound(LearningApplicationError):
    """The exact published mission version is unavailable."""


class AttemptNotFound(LearningApplicationError):
    """The attempt does not exist."""


class AttemptAccessDenied(LearningApplicationError):
    """The principal does not own the requested attempt."""


class StaleAttemptVersion(LearningApplicationError):
    """The client attempted to mutate an outdated aggregate version."""


class IdempotencyConflict(LearningApplicationError):
    """An idempotency key was reused with a different request."""


class RepositoryConflict(LearningApplicationError):
    """A repository uniqueness or optimistic-concurrency check failed."""

