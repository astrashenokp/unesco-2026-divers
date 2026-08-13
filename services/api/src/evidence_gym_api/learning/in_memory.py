"""Local in-memory learning adapters.

These adapters make the ASGI app runnable for local/dev composition and tests.
They are deliberately not production persistence.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from copy import deepcopy
import asyncio
from datetime import UTC, datetime
from itertools import count
from hashlib import sha256

from evidence_gym_api.learning.attempt import Attempt
from evidence_gym_api.learning.errors import RepositoryConflict
from evidence_gym_api.learning.ports import (
    IdempotencyScope,
    MissionPolicy,
    StoredAttemptResult,
    StoredEvidenceResult,
    StoredHintResult,
    StoredCompletionResult,
    CompletionResult,
    ProgressResult,
    SkillProgress,
    CompletionScorer,
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
        self._hint_results: dict[IdempotencyScope, StoredHintResult] = {}
        self._completion_results: dict[IdempotencyScope, StoredCompletionResult] = {}

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

    async def get_hint(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredHintResult | None:
        result = self._hint_results.get(scope)
        if result is not None and result.expires_at <= at:
            del self._hint_results[scope]
            return None
        return deepcopy(result) if result is not None else None

    async def put_hint(
        self, scope: IdempotencyScope, result: StoredHintResult
    ) -> None:
        existing = self._hint_results.get(scope)
        if existing is not None and existing != result:
            raise RepositoryConflict("idempotency result already exists")
        self._hint_results[scope] = deepcopy(result)

    async def get_completion(
        self, scope: IdempotencyScope, *, at: datetime
    ) -> StoredCompletionResult | None:
        result = self._completion_results.get(scope)
        if result is not None and result.expires_at <= at:
            del self._completion_results[scope]
            return None
        return deepcopy(result) if result is not None else None

    async def put_completion(
        self, scope: IdempotencyScope, result: StoredCompletionResult
    ) -> None:
        existing = self._completion_results.get(scope)
        if existing is not None and existing != result:
            raise RepositoryConflict("idempotency result already exists")
        self._completion_results[scope] = deepcopy(result)


class InMemoryAtomicCompletionWriter:
    """Local reference for the Role 4 atomic completion adapter."""

    def __init__(
        self, attempts: InMemoryAttemptRepository, scorer: CompletionScorer
    ) -> None:
        self._attempts = attempts
        self._scorer = scorer
        self.receipts: dict[str, dict[str, object]] = {}
        self.outbox: list[dict[str, object]] = []
        self.total_xp: dict[str, int] = {}

    async def complete(
        self, attempt, conclusion, *, expected_version: int, completed_at: datetime
    ) -> CompletionResult:
        attempt.submit_conclusion(conclusion)
        attempt.complete()
        xp_grant = await self._scorer.award(
            attempt.mission_id,
            attempt.mission_version,
            len(attempt.evidence_action_refs),
        )
        xp_awarded = xp_grant.amount
        receipt_id = f"receipt-{attempt.id.value}"
        learner_key = attempt.learner_id.value
        total_xp = self.total_xp.get(learner_key, 0) + xp_awarded
        receipt_hash = sha256(
            f"{attempt.id.value}:{attempt.mission_version.value}:{attempt.version}".encode()
        ).hexdigest()

        await self._attempts.save(attempt, expected_version=expected_version)
        self.total_xp[learner_key] = total_xp
        self.receipts[receipt_id] = {
            "id": receipt_id,
            "learner_id": attempt.learner_id.value,
            "attempt_id": attempt.id.value,
            "mission_version": attempt.mission_version.value,
            "assessments": (
                conclusion.authenticity,
                conclusion.claim_veracity,
                conclusion.context_integrity,
            ),
            "evidence_refs": attempt.evidence_action_refs,
            "hash": receipt_hash,
            "created_at": completed_at,
            "disclaimer": "This receipt records a learning process, not a universal truth verdict.",
        }
        self.outbox.append(
            {
                "type": "attempt.completed",
                "attempt_id": attempt.id.value,
                "xp_rule_code": xp_grant.rule_code,
            }
        )
        return CompletionResult(
            receipt_id=receipt_id,
            xp_awarded=xp_awarded,
            progress=ProgressResult(total_xp=total_xp, skills=()),
        )

    async def get_for_learner(self, receipt_id: str, learner_id):
        """Return an owned receipt without exposing whether another learner has it."""

        receipt = self.receipts.get(receipt_id)
        if receipt is None or receipt["learner_id"] != learner_id.value:
            return None
        from evidence_gym_api.receipt.model import EvidenceReceipt

        return EvidenceReceipt(
            id=receipt["id"],
            attempt_id=receipt["attempt_id"],
            mission_version=receipt["mission_version"],
            assessments=receipt["assessments"],
            evidence_refs=receipt["evidence_refs"],
            created_at=receipt["created_at"],
            hash=receipt["hash"],
            disclaimer=receipt["disclaimer"],
        )


class InMemoryTransactionManager:
    """Serialize mutations to model one application transaction boundary."""

    def __init__(self) -> None:
        self._lock = asyncio.Lock()

    @asynccontextmanager
    async def transaction(self) -> AsyncIterator[None]:
        async with self._lock:
            yield


class SystemClock:
    def now(self) -> datetime:
        return datetime.now(UTC)


class FixedClock:
    def __init__(self, current: datetime | None = None) -> None:
        self.current = current or datetime(2026, 8, 11, tzinfo=UTC)

    def now(self) -> datetime:
        return self.current
