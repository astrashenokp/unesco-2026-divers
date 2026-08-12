"""Deterministic in-memory adapters; never production persistence."""

from copy import deepcopy
from contextlib import asynccontextmanager
import asyncio
from datetime import UTC, datetime
from itertools import count
from collections.abc import AsyncIterator

from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    IdempotencyScope,
    MissionPolicy,
    StoredAttemptResult,
    StoredEvidenceResult,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    MissionId,
    MissionVersion,
)


class InMemoryAttemptRepository:
    def __init__(self) -> None:
        self._attempts: dict[AttemptId, Attempt] = {}

    async def get(self, attempt_id: AttemptId) -> Attempt | None:
        attempt = self._attempts.get(attempt_id)
        return deepcopy(attempt) if attempt is not None else None

    async def add(self, attempt: Attempt) -> None:
        if attempt.id in self._attempts:
            raise RepositoryConflict("attempt id already exists")
        self._attempts[attempt.id] = deepcopy(attempt)

    async def save(self, attempt: Attempt, *, expected_version: int) -> None:
        stored = self._attempts.get(attempt.id)
        if stored is None:
            raise RepositoryConflict("attempt does not exist")
        if stored.version != expected_version:
            raise RepositoryConflict("attempt version changed concurrently")
        self._attempts[attempt.id] = deepcopy(attempt)


class InMemoryMissionPolicyReader:
    def __init__(self, policies: tuple[MissionPolicy, ...] = ()) -> None:
        self._policies = {(policy.id, policy.version): policy for policy in policies}

    async def get_policy(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> MissionPolicy | None:
        return self._policies.get((mission_id, mission_version))


class SequentialAttemptIdGenerator:
    def __init__(self, prefix: str = "attempt-test") -> None:
        self._prefix = prefix
        self._sequence = count(1)

    def new(self) -> AttemptId:
        return AttemptId(f"{self._prefix}-{next(self._sequence)}")


class InMemoryIdempotencyRepository:
    def __init__(self) -> None:
        self._results: dict[IdempotencyScope, StoredAttemptResult] = {}
        self._evidence_results: dict[IdempotencyScope, StoredEvidenceResult] = {}

    async def get(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredAttemptResult | None:
        result = self._results.get(scope)
        if result is not None and result.expires_at <= at:
            del self._results[scope]
            return None
        return deepcopy(result) if result is not None else None

    async def put(
        self, scope: IdempotencyScope, result: StoredAttemptResult
    ) -> None:
        existing = self._results.get(scope)
        if existing is not None and existing != result:
            raise RepositoryConflict("idempotency result already exists")
        self._results[scope] = deepcopy(result)

    async def get_evidence(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredEvidenceResult | None:
        result = self._evidence_results.get(scope)
        if result is not None and result.expires_at <= at:
            del self._evidence_results[scope]
            return None
        return deepcopy(result) if result is not None else None

    async def put_evidence(
        self, scope: IdempotencyScope, result: StoredEvidenceResult
    ) -> None:
        existing = self._evidence_results.get(scope)
        if existing is not None and existing != result:
            raise RepositoryConflict("idempotency result already exists")
        self._evidence_results[scope] = deepcopy(result)


class InMemoryTransactionManager:
    """Serialize test mutations to model one application transaction boundary."""

    def __init__(self) -> None:
        self._lock = asyncio.Lock()

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[None]:
        async with self._lock:
            yield


class FixedClock:
    def __init__(self, current: datetime | None = None) -> None:
        self.current = current or datetime(2026, 8, 11, tzinfo=UTC)

    def now(self) -> datetime:
        return self.current
