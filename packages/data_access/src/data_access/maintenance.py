"""Operational maintenance entry points for persistence jobs."""

from __future__ import annotations

from datetime import UTC, datetime

from data_access.db import Database
from data_access.idempotency import cleanup_expired_idempotency


async def run_idempotency_cleanup(database_url: str) -> int:
    """Delete expired snapshots in one short transaction."""
    database = Database(database_url)
    try:
        async with database.session() as session:
            async with session.begin():
                return await cleanup_expired_idempotency(session, at=datetime.now(UTC))
    finally:
        await database.dispose()
