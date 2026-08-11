"""Learning application use cases with explicit authorization and retry semantics."""

from dataclasses import dataclass
from hashlib import sha256
import json

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.attempt import Attempt, Confidence, Prediction, Reaction
from evidence_gym_api.learning.errors import (
    AttemptAccessDenied,
    AttemptNotFound,
    IdempotencyConflict,
    MissionNotFound,
    StaleAttemptVersion,
)
from evidence_gym_api.learning.ports import (
    AttemptIdGenerator,
    AttemptRepository,
    IdempotencyRepository,
    IdempotencyScope,
    MissionPolicyReader,
    StoredAttemptResult,
    TransactionManager,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    MissionId,
    MissionVersion,
)


def _fingerprint(payload: dict[str, object]) -> str:
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return sha256(encoded).hexdigest()


def _replay_or_conflict(
    stored: StoredAttemptResult | None, request_fingerprint: str
) -> Attempt | None:
    if stored is None:
        return None
    if stored.request_fingerprint != request_fingerprint:
        raise IdempotencyConflict("idempotency key was reused with another request")
    return stored.attempt


@dataclass(frozen=True, slots=True)
class StartAttemptCommand:
    mission_id: MissionId
    mission_version: MissionVersion
    idempotency_key: IdempotencyKey


class StartAttempt:
    def __init__(
        self,
        attempts: AttemptRepository,
        missions: MissionPolicyReader,
        idempotency: IdempotencyRepository,
        ids: AttemptIdGenerator,
        transactions: TransactionManager,
    ) -> None:
        self._attempts = attempts
        self._missions = missions
        self._idempotency = idempotency
        self._ids = ids
        self._transactions = transactions

    async def execute(self, principal: Principal, command: StartAttemptCommand) -> Attempt:
        fingerprint = _fingerprint(
            {
                "missionId": command.mission_id.value,
                "missionVersion": command.mission_version.value,
            }
        )
        scope = IdempotencyScope(
            principal.subject, "start_attempt", command.idempotency_key
        )
        async with self._transactions.transaction():
            replay = _replay_or_conflict(
                await self._idempotency.get(scope), fingerprint
            )
            if replay is not None:
                return replay

            policy = await self._missions.get_policy(
                command.mission_id, command.mission_version
            )
            if policy is None:
                raise MissionNotFound("exact mission version is unavailable")

            attempt = Attempt(
                id=self._ids.new(),
                learner_id=principal.subject,
                mission_id=policy.id,
                mission_version=policy.version,
                allows_no_evidence_conclusion=policy.tests_critical_ignoring,
            )
            await self._attempts.add(attempt)
            await self._idempotency.put(
                scope, StoredAttemptResult(fingerprint, attempt)
            )
            return attempt


@dataclass(frozen=True, slots=True)
class SubmitPredictionCommand:
    attempt_id: AttemptId
    reaction: Reaction
    confidence: Confidence
    version: int
    idempotency_key: IdempotencyKey


class SubmitPrediction:
    def __init__(
        self,
        attempts: AttemptRepository,
        idempotency: IdempotencyRepository,
        transactions: TransactionManager,
    ) -> None:
        self._attempts = attempts
        self._idempotency = idempotency
        self._transactions = transactions

    async def execute(
        self, principal: Principal, command: SubmitPredictionCommand
    ) -> Attempt:
        fingerprint = _fingerprint(
            {
                "attemptId": command.attempt_id.value,
                "reaction": command.reaction.value,
                "confidenceStatus": command.confidence.status.value,
                "confidence": command.confidence.value,
                "version": command.version,
            }
        )
        scope = IdempotencyScope(
            principal.subject,
            f"submit_prediction:{command.attempt_id.value}",
            command.idempotency_key,
        )
        async with self._transactions.transaction():
            replay = _replay_or_conflict(
                await self._idempotency.get(scope), fingerprint
            )
            if replay is not None:
                return replay

            attempt = await self._attempts.get(command.attempt_id)
            if attempt is None:
                raise AttemptNotFound("attempt does not exist")
            if attempt.learner_id != principal.subject:
                raise AttemptAccessDenied("attempt belongs to another learner")
            if attempt.version != command.version:
                raise StaleAttemptVersion("attempt version is stale")

            expected_version = attempt.version
            attempt.submit_prediction(Prediction(command.reaction, command.confidence))
            await self._attempts.save(attempt, expected_version=expected_version)
            await self._idempotency.put(
                scope, StoredAttemptResult(fingerprint, attempt)
            )
            return attempt
