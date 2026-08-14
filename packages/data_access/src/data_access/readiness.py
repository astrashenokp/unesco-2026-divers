"""Readiness probe that answers /ready with a real database round-trip."""

from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from data_access.db import Database


class DatabaseReadinessProbe:
    """Report ready only when PostgreSQL can execute a trivial statement."""

    def __init__(self, database: Database) -> None:
        self.database = database

    async def is_ready(self) -> bool:
        try:
            async with self.database.session() as session:
                await session.execute(text("SELECT 1"))
            return True
        except (SQLAlchemyError, OSError):
            return False
