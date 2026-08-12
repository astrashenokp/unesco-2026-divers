"""Storage errors exposed to the application boundary."""


class DataAccessError(Exception):
    """Base error for persistence failures."""


class DataAccessConfigurationError(DataAccessError):
    """Raised when a required database configuration is absent."""
