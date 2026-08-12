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
    from evidence_gym_api.coach.model import CoachHint
    from evidence_gym_api.evidence.model import EvidenceResult
    from evidence_gym_api.learning.attempt import Conclusion


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


@dataclass(frozen=True, slots=True)
class StoredHintResult:
    request_fingerprint: str
    result: CoachHint
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class SkillProgress:
    skill: str
    mastery: float
    due_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class ProgressResult:
    total_xp: int
    skills: tuple[SkillProgress, ...]


@dataclass(frozen=True, slots=True)
class ProcessLevelPolicy:
    level: int
    xp_guidance: int
    skill_tags: tuple[str, ...]


@dataclass(frozen=True, slots=True)
class XpAward:
    rule_code: str
    amount: int
    level: int


@dataclass(frozen=True, slots=True)
class CompletionResult:
    receipt_id: str
    xp_awarded: int
    progress: ProgressResult


@dataclass(frozen=True, slots=True)
class StoredCompletionResult:
    request_fingerprint: str
    result: CompletionResult
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


class HintIdempotencyRepository(Protocol):
    async def get_hint(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredHintResult | None: ...

    async def put_hint(
        self, scope: IdempotencyScope, result: StoredHintResult
    ) -> None: ...


class CompletionIdempotencyRepository(Protocol):
    async def get_completion(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredCompletionResult | None: ...

    async def put_completion(
        self, scope: IdempotencyScope, result: StoredCompletionResult
    ) -> None: ...


class AtomicCompletionWriter(Protocol):
    """Persist attempt, receipt, XP, progress and outbox as one unit."""

    async def complete(
        self,
        attempt: Attempt,
        conclusion: Conclusion,
        *,
        expected_version: int,
        completed_at: datetime,
    ) -> CompletionResult: ...


class CompletionPolicyReader(Protocol):
    async def get_process_levels(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> tuple[ProcessLevelPolicy, ...] | None: ...


class CompletionScorer(Protocol):
    async def award(
        self,
        mission_id: MissionId,
        mission_version: MissionVersion,
        used_evidence_actions: int,
    ) -> XpAward: ...


class TransactionManager(Protocol):
    def transaction(self) -> AbstractAsyncContextManager[None]: ...


class Clock(Protocol):
    def now(self) -> datetime: ...
