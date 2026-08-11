"""Application ports for learning use cases."""

from dataclasses import dataclass
from contextlib import AbstractAsyncContextManager
from typing import Protocol

from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)


@dataclass(frozen=True, slots=True)
class MissionPolicy:
    id: MissionId
    version: MissionVersion
    tests_critical_ignoring: bool = False


@dataclass(frozen=True, slots=True)
class IdempotencyScope:
    learner_id: LearnerId
    operation: str
    key: IdempotencyKey


@dataclass(frozen=True, slots=True)
class StoredAttemptResult:
    request_fingerprint: str
    attempt: Attempt


class AttemptRepository(Protocol):
    async def get(self, attempt_id: AttemptId) -> Attempt | None: ...

    async def add(self, attempt: Attempt) -> None: ...

    async def save(self, attempt: Attempt, *, expected_version: int) -> None: ...


class MissionPolicyReader(Protocol):
    async def get_policy(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> MissionPolicy | None: ...


class AttemptIdGenerator(Protocol):
    def new(self) -> AttemptId: ...


class IdempotencyRepository(Protocol):
    async def get(self, scope: IdempotencyScope) -> StoredAttemptResult | None: ...

    async def put(
        self, scope: IdempotencyScope, result: StoredAttemptResult
    ) -> None: ...


class TransactionManager(Protocol):
    def transaction(self) -> AbstractAsyncContextManager[None]: ...
