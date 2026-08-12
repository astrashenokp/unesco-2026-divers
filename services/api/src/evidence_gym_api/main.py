"""Default ASGI entry point."""

from pathlib import Path

from evidence_gym_api.app import create_app
from evidence_gym_api.catalog import FileMissionPolicyReader
from evidence_gym_api.coach.fixture_provider import FixtureCoachProvider
from evidence_gym_api.evidence import FixtureDeterministicEvidenceProvider
from evidence_gym_api.learning.api import LearningServices
from evidence_gym_api.learning.in_memory import (
    InMemoryAttemptRepository,
    InMemoryIdempotencyRepository,
    InMemoryTransactionManager,
    InMemoryAtomicCompletionWriter,
    SequentialAttemptIdGenerator,
    SystemClock,
)
from evidence_gym_api.learning.use_cases import (
    RequestHint,
    StartAttempt,
    SubmitPrediction,
    UseEvidenceAction,
    CompleteAttempt,
)
from evidence_gym_api.learning.gameplay_adapter import GameplayCompletionScorer

REPOSITORY_ROOT = Path(__file__).resolve().parents[4]

fixture_reader = FileMissionPolicyReader(
    pack_root=REPOSITORY_ROOT / "content" / "p0-demo-pack",
    manifest_schema_path=REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json",
    mission_schema_path=REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json",
)

attempts = InMemoryAttemptRepository()
idempotency = InMemoryIdempotencyRepository()
transactions = InMemoryTransactionManager()
clock = SystemClock()

learning_services = LearningServices(
    start_attempt=StartAttempt(
        attempts,
        fixture_reader,
        idempotency,
        SequentialAttemptIdGenerator(prefix="attempt-local"),
        transactions,
        clock,
    ),
    submit_prediction=SubmitPrediction(attempts, idempotency, transactions, clock),
    use_evidence_action=UseEvidenceAction(
        attempts,
        FixtureDeterministicEvidenceProvider(fixture_reader),
        idempotency,
        transactions,
        clock,
    ),
    request_hint=RequestHint(
        attempts,
        fixture_reader,
        FixtureCoachProvider(fixture_reader),
        idempotency,
        transactions,
        clock,
    ),
    complete_attempt=CompleteAttempt(
        attempts,
        InMemoryAtomicCompletionWriter(
            attempts, GameplayCompletionScorer(fixture_reader)
        ),
        idempotency,
        transactions,
        clock,
    ),
)

app = create_app(
    catalog_reader=fixture_reader,
    learning_services=learning_services,
)
