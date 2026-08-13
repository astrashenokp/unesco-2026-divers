"""Learning application use cases with explicit authorization and retry semantics."""

from dataclasses import dataclass, replace
from datetime import timedelta
from hashlib import sha256
import json
import re

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.coach.errors import CoachProviderError
from evidence_gym_api.coach.model import CoachHint
from evidence_gym_api.coach.ports import CoachPolicyReader, CoachProvider, CoachRequest
from evidence_gym_api.evidence.model import EvidenceResult
from evidence_gym_api.evidence.ports import DeterministicEvidenceProvider
from evidence_gym_api.learning.attempt import (
    Attempt,
    AxisAssessment,
    Conclusion,
    Confidence,
    IllegalAttemptTransition,
    Prediction,
    Reaction,
    ShareDecision,
)
from evidence_gym_api.learning.errors import (
    AttemptAccessDenied,
    AttemptNotFound,
    IdempotencyConflict,
    MissionNotFound,
    StaleAttemptVersion,
)
from evidence_gym_api.learning.ports import (
    AttemptIdGenerator,
    AtomicCompletionWriter,
    AttemptRepository,
    Clock,
    CompletionIdempotencyRepository,
    CompletionResult,
    EvidenceActionResult,
    EvidenceIdempotencyRepository,
    HintIdempotencyRepository,
    IdempotencyRepository,
    IdempotencyScope,
    MissionPolicyReader,
    StoredAttemptResult,
    StoredEvidenceResult,
    StoredHintResult,
    StoredCompletionResult,
    TransactionManager,
)
from evidence_gym_api.learning.value_objects import (
    AttemptId,
    IdempotencyKey,
    MissionId,
    MissionVersion,
)

IDEMPOTENCY_RETENTION = timedelta(hours=24)
ALLOWED_HINT_SAFETY_FLAGS = {
    "needs_more_evidence",
    "harm_sensitive",
    "provider_degraded",
}
FORBIDDEN_HINT_SAFETY_FLAGS = {
    "possible_leakage",
    "prompt_injection_detected",
    "unsupported_citation",
}
REFERENCE_LEAK_PATTERN = re.compile(
    r"(https?://|www\.|doi:\s*10\.|10\.\d{4,9}/[-._;()/:A-Z0-9]+)",
    re.IGNORECASE,
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
        clock: Clock,
    ) -> None:
        self._attempts = attempts
        self._missions = missions
        self._idempotency = idempotency
        self._ids = ids
        self._transactions = transactions
        self._clock = clock

    async def execute(self, principal: Principal, command: StartAttemptCommand) -> Attempt:
        fingerprint = _fingerprint(
            {
                "missionId": command.mission_id.value,
                "missionVersion": command.mission_version.value,
            }
        )
        scope = IdempotencyScope(
            principal.subject, "/attempts", command.idempotency_key
        )
        async with self._transactions.transaction():
            now = self._clock.now()
            replay = _replay_or_conflict(
                await self._idempotency.get(scope, at=now), fingerprint
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
                minimum_required_evidence_actions=policy.minimum_completion_evidence,
            )
            await self._attempts.add(attempt)
            await self._idempotency.put(
                scope,
                StoredAttemptResult(
                    fingerprint, attempt, now + IDEMPOTENCY_RETENTION
                ),
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
        clock: Clock,
    ) -> None:
        self._attempts = attempts
        self._idempotency = idempotency
        self._transactions = transactions
        self._clock = clock

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
            "/attempts/{attemptId}/prediction",
            command.idempotency_key,
        )
        async with self._transactions.transaction():
            now = self._clock.now()
            replay = _replay_or_conflict(
                await self._idempotency.get(scope, at=now), fingerprint
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
                scope,
                StoredAttemptResult(
                    fingerprint, attempt, now + IDEMPOTENCY_RETENTION
                ),
            )
            return attempt


@dataclass(frozen=True, slots=True)
class UseEvidenceActionCommand:
    attempt_id: AttemptId
    action_id: str
    input: dict[str, object]
    version: int
    idempotency_key: IdempotencyKey


class UseEvidenceAction:
    def __init__(
        self,
        attempts: AttemptRepository,
        evidence: DeterministicEvidenceProvider,
        idempotency: EvidenceIdempotencyRepository,
        transactions: TransactionManager,
        clock: Clock,
    ) -> None:
        self._attempts = attempts
        self._evidence = evidence
        self._idempotency = idempotency
        self._transactions = transactions
        self._clock = clock

    async def execute(
        self, principal: Principal, command: UseEvidenceActionCommand
    ) -> EvidenceActionResult:
        fingerprint = _fingerprint(
            {
                "attemptId": command.attempt_id.value,
                "actionId": command.action_id,
                "input": command.input,
                "version": command.version,
            }
        )
        scope = IdempotencyScope(
            principal.subject,
            "/attempts/{attemptId}/evidence-actions",
            command.idempotency_key,
        )
        async with self._transactions.transaction():
            now = self._clock.now()
            stored = await self._idempotency.get_evidence(scope, at=now)
            if stored is not None:
                if stored.request_fingerprint != fingerprint:
                    raise IdempotencyConflict(
                        "idempotency key was reused with another request"
                    )
                return stored.result

            attempt = await self._attempts.get(command.attempt_id)
            if attempt is None:
                raise AttemptNotFound("attempt does not exist")
            if attempt.learner_id != principal.subject:
                raise AttemptAccessDenied("attempt belongs to another learner")
            if attempt.version != command.version:
                raise StaleAttemptVersion("attempt version is stale")

            result = await self._evidence.get_result(
                attempt.mission_id, attempt.mission_version, command.action_id
            )
            expected_version = attempt.version
            attempt.record_evidence_action(result.action_id)
            await self._attempts.save(attempt, expected_version=expected_version)
            response = EvidenceActionResult(result, attempt.version)
            await self._idempotency.put_evidence(
                scope,
                StoredEvidenceResult(
                    fingerprint, response, now + IDEMPOTENCY_RETENTION
                ),
            )
            return response


@dataclass(frozen=True, slots=True)
class RequestHintCommand:
    attempt_id: AttemptId
    idempotency_key: IdempotencyKey


class RequestHint:
    """Return a bounded hint without changing the attempt or its version."""

    def __init__(
        self,
        attempts: AttemptRepository,
        policies: CoachPolicyReader,
        fallback: CoachProvider,
        idempotency: HintIdempotencyRepository,
        transactions: TransactionManager,
        clock: Clock,
        provider: CoachProvider | None = None,
    ) -> None:
        self._attempts = attempts
        self._policies = policies
        self._provider = provider
        self._fallback = fallback
        self._idempotency = idempotency
        self._transactions = transactions
        self._clock = clock

    async def execute(
        self, principal: Principal, command: RequestHintCommand
    ) -> CoachHint:
        fingerprint = _fingerprint({"attemptId": command.attempt_id.value})
        scope = IdempotencyScope(
            principal.subject,
            "/attempts/{attemptId}/hints",
            command.idempotency_key,
        )
        async with self._transactions.transaction():
            now = self._clock.now()
            stored = await self._idempotency.get_hint(scope, at=now)
            if stored is not None:
                if stored.request_fingerprint != fingerprint:
                    raise IdempotencyConflict(
                        "idempotency key was reused with another request"
                    )
                return stored.result

            attempt = await self._attempts.get(command.attempt_id)
            if attempt is None:
                raise AttemptNotFound("attempt does not exist")
            if attempt.learner_id != principal.subject:
                raise AttemptAccessDenied("attempt belongs to another learner")
            if attempt.state.value not in {"predicted", "investigating"}:
                raise IllegalAttemptTransition(
                    "hints require a predicted or investigating attempt"
                )

            data = await self._policies.get_coach_request_data(
                attempt.mission_id, attempt.mission_version
            )
            if data is None:
                raise MissionNotFound("exact mission version is unavailable")

            allowed_actions, evidence_by_action, forbidden_terms = data
            available_refs = tuple(
                evidence_id
                for action_id in attempt.evidence_action_refs
                for evidence_id in evidence_by_action.get(action_id, ())
            )
            level = min(1 + len(attempt.evidence_action_refs), 4)
            request = CoachRequest(
                mission_id=attempt.mission_id,
                mission_version=attempt.mission_version,
                attempt_state=attempt.state.value,
                level=level,
                allowed_action_ids=allowed_actions,
                available_evidence_refs=available_refs,
                forbidden_terms=forbidden_terms,
            )
            hint = await self._safe_hint(request)
            await self._idempotency.put_hint(
                scope,
                StoredHintResult(fingerprint, hint, now + IDEMPOTENCY_RETENTION),
            )
            return hint

    async def _safe_hint(self, request: CoachRequest) -> CoachHint:
        if self._provider is not None:
            try:
                candidate = await self._provider.request_hint(request)
                if self._is_safe(candidate, request):
                    return candidate
            except (
                CoachProviderError,
                TimeoutError,
                ValueError,
                TypeError,
                AttributeError,
            ):
                pass

        fallback = await self._fallback.request_hint(request)
        if self._is_safe(fallback, request):
            return fallback

        for lower_level in range(request.level - 1, 0, -1):
            lower_request = replace(request, level=lower_level)
            fallback = await self._fallback.request_hint(lower_request)
            if self._is_safe(fallback, lower_request):
                return fallback

        raise CoachProviderError("reviewed fallback violated coach policy")

    @staticmethod
    def _is_safe(hint: CoachHint, request: CoachRequest) -> bool:
        normalized_text = hint.text.casefold()
        forbidden_terms = tuple(
            term.casefold() for term in request.forbidden_terms if term
        )
        safety_flags = set(hint.safety_flags)
        return (
            bool(hint.text.strip())
            and len(hint.text) <= 600
            and hint.level == request.level
            and hint.level <= 4
            and (
                hint.suggested_action_id is None
                or hint.suggested_action_id in request.allowed_action_ids
            )
            and set(hint.evidence_refs).issubset(request.available_evidence_refs)
            and len(hint.evidence_refs) == len(set(hint.evidence_refs))
            and safety_flags.issubset(ALLOWED_HINT_SAFETY_FLAGS)
            and FORBIDDEN_HINT_SAFETY_FLAGS.isdisjoint(safety_flags)
            and not any(term in normalized_text for term in forbidden_terms)
            and REFERENCE_LEAK_PATTERN.search(hint.text) is None
        )


@dataclass(frozen=True, slots=True)
class CompleteAttemptCommand:
    attempt_id: AttemptId
    authenticity: AxisAssessment
    claim_veracity: AxisAssessment
    context_integrity: AxisAssessment
    post_confidence: Confidence
    share_decision: ShareDecision
    version: int
    idempotency_key: IdempotencyKey


class CompleteAttempt:
    """Atomically complete an attempt and replay the complete original response."""

    def __init__(
        self,
        attempts: AttemptRepository,
        writer: AtomicCompletionWriter,
        idempotency: CompletionIdempotencyRepository,
        transactions: TransactionManager,
        clock: Clock,
    ) -> None:
        self._attempts = attempts
        self._writer = writer
        self._idempotency = idempotency
        self._transactions = transactions
        self._clock = clock

    async def execute(
        self, principal: Principal, command: CompleteAttemptCommand
    ) -> CompletionResult:
        fingerprint = _fingerprint(
            {
                "attemptId": command.attempt_id.value,
                "authenticity": _axis_payload(command.authenticity),
                "claimVeracity": _axis_payload(command.claim_veracity),
                "contextIntegrity": _axis_payload(command.context_integrity),
                "postConfidence": command.post_confidence.value,
                "shareDecision": command.share_decision.value,
                "version": command.version,
            }
        )
        scope = IdempotencyScope(
            principal.subject,
            "/attempts/{attemptId}/conclusion",
            command.idempotency_key,
        )
        async with self._transactions.transaction():
            now = self._clock.now()
            stored = await self._idempotency.get_completion(scope, at=now)
            if stored is not None:
                if stored.request_fingerprint != fingerprint:
                    raise IdempotencyConflict(
                        "idempotency key was reused with another request"
                    )
                return stored.result

            attempt = await self._attempts.get(command.attempt_id)
            if attempt is None:
                raise AttemptNotFound("attempt does not exist")
            if attempt.learner_id != principal.subject:
                raise AttemptAccessDenied("attempt belongs to another learner")
            if attempt.version != command.version:
                raise StaleAttemptVersion("attempt version is stale")

            conclusion = Conclusion(
                authenticity=command.authenticity,
                claim_veracity=command.claim_veracity,
                context_integrity=command.context_integrity,
                post_confidence=command.post_confidence,
                share_decision=command.share_decision,
            )
            result = await self._writer.complete(
                attempt,
                conclusion,
                expected_version=attempt.version,
                completed_at=now,
            )
            await self._idempotency.put_completion(
                scope,
                StoredCompletionResult(
                    fingerprint, result, now + IDEMPOTENCY_RETENTION
                ),
            )
            return result


def _axis_payload(axis: AxisAssessment) -> dict[str, object]:
    return {"label": axis.label, "confidence": axis.confidence.value}
