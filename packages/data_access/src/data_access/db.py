"""Async SQLAlchemy runtime primitives."""

from __future__ import annotations

import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from data_access.errors import DataAccessConfigurationError


class Database:
    """Owns an engine and creates one isolated session per unit of work."""

    def __init__(self, url: str | None = None) -> None:
        database_url = url or os.getenv("DATABASE_URL")
        if not database_url:
            raise DataAccessConfigurationError("DATABASE_URL is required")
        engine_options: dict[str, object] = {"pool_pre_ping": True}
        if database_url.startswith("postgresql"):
            engine_options.update(pool_size=5, max_overflow=10)
        self.engine: AsyncEngine = create_async_engine(database_url, **engine_options)
        self.sessions = async_sessionmaker(self.engine, expire_on_commit=False)

    def session(self) -> AsyncSession:
        return self.sessions()

    async def dispose(self) -> None:
        await self.engine.dispose()


class SqlAlchemyTransactionManager:
    """Expose the application transaction protocol over one AsyncSession."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[None]:
        async with self.session.begin():
            yield
