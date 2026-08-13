"""Default ASGI entry point."""

import os
from pathlib import Path

from evidence_gym_api.app import create_app
from evidence_gym_api.catalog import FileMissionPolicyReader
from evidence_gym_api.coach.fixture_provider import FixtureCoachProvider
from evidence_gym_api.evidence import FixtureDeterministicEvidenceProvider
from evidence_gym_api.identity.model import Principal
from evidence_gym_api.identity.testing import FakeIdentityVerifier
from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.learning.api import LearningServices
from evidence_gym_api.learning.in_memory import (
    InMemoryAttemptRepository,
    InMemoryIdempotencyRepository,
    InMemoryTransactionManager,
    SequentialAttemptIdGenerator,
    SystemClock,
)
from evidence_gym_api.learning.use_cases import (
    RequestHint,
    StartAttempt,
    SubmitPrediction,
    UseEvidenceAction,
)

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
)

def _dev_identity_verifier() -> FakeIdentityVerifier | None:
    """A stand-in verifier, only when explicitly asked for.

    Every authenticated route answers 503 until `app.state
    .identity_verifier` is set, so this composition — in-memory
    repositories, fixture content, no Firebase — could be started and
    then refuse every request it was started to serve.

    Off unless `EVIDENCE_GYM_DEV_TOKENS` is set, and the value is the
    token list, so nothing is accepted that was not named. It is
    deliberately noisy to enable rather than a convenient default: a
    fallback that quietly authenticates anyone is the kind of thing that
    reaches production because nobody had to think about it.

        EVIDENCE_GYM_DEV_TOKENS=dev-token,other-token

    `FakeIdentityVerifier` is documented for "unit tests and local
    composition", which is exactly this.
    """
    raw = os.environ.get("EVIDENCE_GYM_DEV_TOKENS", "").strip()
    if not raw:
        return None
    tokens = [token.strip() for token in raw.split(",") if token.strip()]
    return FakeIdentityVerifier(
        {
            token: Principal(subject=LearnerId(f"dev-{index}"))
            for index, token in enumerate(tokens)
        }
    )


def _allowed_origins() -> tuple[str, ...]:
    """Origins permitted to call this API from a browser.

    Also opt-in. `EVIDENCE_GYM_CORS_ORIGINS=http://localhost:8080` is
    what a local Flutter web client needs.
    """
    raw = os.environ.get("EVIDENCE_GYM_CORS_ORIGINS", "").strip()
    if not raw:
        return ()
    return tuple(origin.strip() for origin in raw.split(",") if origin.strip())


# The contract declares `servers: https://…/v1`, so a conforming client
# asks for `/v1/...`. Overridable, but the default matches the contract
# rather than matching what the tests happen to call.
app = create_app(
    catalog_reader=fixture_reader,
    learning_services=learning_services,
    identity_verifier=_dev_identity_verifier(),
    allowed_origins=_allowed_origins(),
    path_prefix=os.environ.get("EVIDENCE_GYM_PATH_PREFIX", "/v1"),
)
