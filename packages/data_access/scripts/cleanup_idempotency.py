"""Run the idempotency TTL cleanup job against DATABASE_URL."""

from __future__ import annotations

import asyncio
import os

from data_access.errors import DataAccessConfigurationError
from data_access.maintenance import run_idempotency_cleanup


def main() -> None:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise DataAccessConfigurationError("DATABASE_URL is required")
    deleted = asyncio.run(run_idempotency_cleanup(url))
    print(f"deleted_expired_idempotency_rows={deleted}")


if __name__ == "__main__":
    main()
