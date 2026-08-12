"""Application ports for learning use cases."""

from __future__ import annotations

from dataclasses import dataclass
from contextlib import AbstractAsyncContextManager
from datetime import datetime
from typing import TYPE_CHECKING, Protocol

from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)

if TYPE_CHECKING:
    from evidence_gym_api.evidence.model import EvidenceResult


@dataclass(frozen=True, slots=True)
class MissionPolicy:
    id: MissionId
    version: MissionVersion
    tests_critical_ignoring: bool = False
    minimum_completion_evidence: int = 1


@dataclass(frozen=True, slots=True)
class IdempotencyScope:
    learner_id: LearnerId
    route: str
    key: IdempotencyKey


@dataclass(frozen=True, slots=True)
class StoredAttemptResult:
    request_fingerprint: str
    attempt: Attempt
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class EvidenceActionResult:
    evidence: EvidenceResult
    attempt_version: int


@dataclass(frozen=True, slots=True)
class StoredEvidenceResult:
    request_fingerprint: str
    result: EvidenceActionResult
    expires_at: datetime


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
    async def get(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredAttemptResult | None: ...

    async def put(
        self, scope: IdempotencyScope, result: StoredAttemptResult
    ) -> None: ...


class EvidenceIdempotencyRepository(Protocol):
    async def get_evidence(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredEvidenceResult | None: ...

    async def put_evidence(
        self, scope: IdempotencyScope, result: StoredEvidenceResult
    ) -> None: ...


class TransactionManager(Protocol):
    def transaction(self) -> AbstractAsyncContextManager[None]: ...


class Clock(Protocol):
    def now(self) -> datetime: ...
