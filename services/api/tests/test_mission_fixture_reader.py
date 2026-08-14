"""Role 2 adapter tests against Role 3's checked-in fixture contract."""

from hashlib import sha256
import asyncio
import json
from pathlib import Path
import shutil

import pytest

from conftest import REPOSITORY_ROOT
from evidence_gym_api.catalog import FileMissionPolicyReader, MissionFixtureError
from evidence_gym_api.coach.fixture_provider import FixtureCoachProvider
from evidence_gym_api.coach.ports import CoachRequest
from evidence_gym_api.identity import Principal
from evidence_gym_api.learning.testing import (
    FixedClock,
    InMemoryAttemptRepository,
    InMemoryIdempotencyRepository,
    InMemoryTransactionManager,
    SequentialAttemptIdGenerator,
)
from evidence_gym_api.learning.use_cases import StartAttempt, StartAttemptCommand
from evidence_gym_api.learning.gameplay_adapter import GameplayCompletionScorer
from evidence_gym_api.learning.value_objects import (
    IdempotencyKey,
    LearnerId,
    MissionId,
    MissionVersion,
)

PACK_ROOT = REPOSITORY_ROOT / "content" / "p0-demo-pack"
MANIFEST_SCHEMA = REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json"
MISSION_SCHEMA = REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json"


def run(coroutine):
    return asyncio.run(coroutine)


def make_reader(pack_root: Path = PACK_ROOT) -> FileMissionPolicyReader:
    return FileMissionPolicyReader(
        pack_root=pack_root,
        manifest_schema_path=MANIFEST_SCHEMA,
        mission_schema_path=MISSION_SCHEMA,
    )


def test_role3_fixture_supplies_safe_deterministic_coach_fallback() -> None:
    reader = make_reader()
    provider = FixtureCoachProvider(reader)
    request = CoachRequest(
        mission_id=MissionId("ai-citation-integrity"),
        mission_version=MissionVersion("0.1.0"),
        attempt_state="predicted",
        level=1,
        allowed_action_ids=("action-decompose-claim",),
        available_evidence_refs=(),
        forbidden_terms=(),
    )

    hint = run(provider.request_hint(request))

    assert hint.level == 1
    assert hint.suggested_action_id == "action-decompose-claim"
    assert hint.fallback is True
    assert hint.safety_flags == ("provider_degraded",)


def test_gameplay_adapter_uses_pinned_role3_xp_guidance() -> None:
    scorer = GameplayCompletionScorer(make_reader())

    one_action = run(
        scorer.award(
            MissionId("authentic-media-wrong-context"),
            MissionVersion("0.1.0"),
            1,
        )
    )
    four_actions = run(
        scorer.award(
            MissionId("authentic-media-wrong-context"),
            MissionVersion("0.1.0"),
            4,
        )
    )

    assert (one_action.rule_code, one_action.amount, one_action.level) == (
        "process-xp:1",
        2,
        1,
    )
    assert (four_actions.rule_code, four_actions.amount, four_actions.level) == (
        "process-xp:4",
        8,
        4,
    )


def copy_pack(tmp_path: Path) -> Path:
    destination = tmp_path / "pack"
    shutil.copytree(PACK_ROOT, destination)
    return destination


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, value: dict) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def update_manifest_hash(pack_root: Path, mission_file: str) -> None:
    manifest_path = pack_root / "manifest.json"
    manifest = load(manifest_path)
    digest = sha256((pack_root / mission_file).read_bytes()).hexdigest()
    for entry in manifest["missions"]:
        if entry["file"] == mission_file:
            entry["sha256"] = digest
    write(manifest_path, manifest)


def test_reader_loads_both_role3_missions_by_exact_version() -> None:
    reader = make_reader()

    context = run(
        reader.get_policy(
            MissionId("authentic-media-wrong-context"), MissionVersion("0.1.0")
        )
    )
    citation = run(
        reader.get_policy(
            MissionId("ai-citation-integrity"), MissionVersion("0.1.0")
        )
    )

    assert context is not None
    assert citation is not None
    assert context.tests_critical_ignoring is False
    assert citation.tests_critical_ignoring is False
    assert context.minimum_completion_evidence == 1
    assert citation.minimum_completion_evidence == 3


def test_public_projection_preserves_reviewed_content_warning_tags() -> None:
    reader = make_reader()

    context = run(
        reader.get_public_mission(MissionId("authentic-media-wrong-context"))
    )
    citation = run(reader.get_public_mission(MissionId("ai-citation-integrity")))

    assert context is not None
    assert citation is not None
    assert context["contentWarnings"] == ["natural-disaster"]
    assert citation["contentWarnings"] == ["academic-integrity"]
    assert "riskNotes" not in context
    assert "privacyNotes" not in context


def test_reader_does_not_silently_upgrade_mission_version() -> None:
    reader = make_reader()

    missing = run(
        reader.get_policy(
            MissionId("ai-citation-integrity"), MissionVersion("0.2.0")
        )
    )

    assert missing is None


def test_start_attempt_pins_real_role3_fixture_version() -> None:
    reader = make_reader()
    use_case = StartAttempt(
        InMemoryAttemptRepository(),
        reader,
        InMemoryIdempotencyRepository(),
        SequentialAttemptIdGenerator(),
        InMemoryTransactionManager(),
        FixedClock(),
    )

    attempt = run(
        use_case.execute(
            Principal(LearnerId("learner-test-1")),
            StartAttemptCommand(
                MissionId("authentic-media-wrong-context"),
                MissionVersion("0.1.0"),
                IdempotencyKey("fixture-start-01"),
            ),
        )
    )

    assert attempt.mission_id == MissionId("authentic-media-wrong-context")
    assert attempt.mission_version == MissionVersion("0.1.0")
    assert attempt.allows_no_evidence_conclusion is False
    assert attempt.minimum_required_evidence_actions == 1


def test_start_attempt_pins_real_role3_minimum_completion_evidence() -> None:
    reader = make_reader()
    use_case = StartAttempt(
        InMemoryAttemptRepository(),
        reader,
        InMemoryIdempotencyRepository(),
        SequentialAttemptIdGenerator(),
        InMemoryTransactionManager(),
        FixedClock(),
    )

    attempt = run(
        use_case.execute(
            Principal(LearnerId("learner-test-1")),
            StartAttemptCommand(
                MissionId("ai-citation-integrity"),
                MissionVersion("0.1.0"),
                IdempotencyKey("fixture-start-02"),
            ),
        )
    )

    assert attempt.mission_id == MissionId("ai-citation-integrity")
    assert attempt.mission_version == MissionVersion("0.1.0")
    assert attempt.minimum_required_evidence_actions == 3


def test_reader_exposes_coach_grounding_and_safe_fallback_hint() -> None:
    reader = make_reader()

    data = run(
        reader.get_coach_request_data(
            MissionId("authentic-media-wrong-context"), MissionVersion("0.1.0")
        )
    )
    hint = run(
        reader.get_fallback_hint(
            MissionId("authentic-media-wrong-context"), MissionVersion("0.1.0"), 1
        )
    )

    assert data is not None
    allowed_actions, evidence_by_action, forbidden_terms = data
    assert "action-primary-source" in allowed_actions
    assert "action-primary-source" in evidence_by_action
    assert "gold label" in forbidden_terms
    assert hint is not None
    assert hint.level == 1
    assert hint.safety_flags == ("provider_degraded",)
    assert hint.fallback is True


def test_reader_maps_trusted_critical_ignoring_flag(tmp_path: Path) -> None:
    pack_root = copy_pack(tmp_path)
    relative_path = "missions/authentic-media-wrong-context.json"
    mission_path = pack_root / relative_path
    mission = load(mission_path)
    mission["testsCriticalIgnoring"] = True
    write(mission_path, mission)
    update_manifest_hash(pack_root, relative_path)

    policy = run(
        make_reader(pack_root).get_policy(
            MissionId("authentic-media-wrong-context"), MissionVersion("0.1.0")
        )
    )

    assert policy is not None
    assert policy.tests_critical_ignoring is True


def test_reader_rejects_hash_mismatch(tmp_path: Path) -> None:
    pack_root = copy_pack(tmp_path)
    mission_path = pack_root / "missions/authentic-media-wrong-context.json"
    mission_path.write_text(
        mission_path.read_text(encoding="utf-8") + " ", encoding="utf-8"
    )

    with pytest.raises(MissionFixtureError, match="hash mismatch"):
        make_reader(pack_root)


def test_reader_rejects_schema_invalid_mission_even_with_matching_hash(
    tmp_path: Path,
) -> None:
    pack_root = copy_pack(tmp_path)
    relative_path = "missions/authentic-media-wrong-context.json"
    mission_path = pack_root / relative_path
    mission = load(mission_path)
    del mission["testsCriticalIgnoring"]
    write(mission_path, mission)
    update_manifest_hash(pack_root, relative_path)

    with pytest.raises(MissionFixtureError, match="schema validation failed"):
        make_reader(pack_root)


def test_reader_rejects_manifest_and_mission_id_mismatch(tmp_path: Path) -> None:
    pack_root = copy_pack(tmp_path)
    relative_path = "missions/authentic-media-wrong-context.json"
    mission_path = pack_root / relative_path
    mission = load(mission_path)
    mission["id"] = "different-mission-id"
    write(mission_path, mission)
    update_manifest_hash(pack_root, relative_path)

    with pytest.raises(MissionFixtureError, match="manifest and mission id differ"):
        make_reader(pack_root)


def test_reader_rejects_duplicate_manifest_mission(tmp_path: Path) -> None:
    pack_root = copy_pack(tmp_path)
    manifest_path = pack_root / "manifest.json"
    manifest = load(manifest_path)
    manifest["missions"].append(dict(manifest["missions"][0]))
    write(manifest_path, manifest)

    with pytest.raises(MissionFixtureError, match="duplicate mission in manifest"):
        make_reader(pack_root)


def test_reader_rejects_path_outside_reviewed_missions_folder(tmp_path: Path) -> None:
    pack_root = copy_pack(tmp_path)
    manifest_path = pack_root / "manifest.json"
    manifest = load(manifest_path)
    manifest["missions"][0]["file"] = "../outside.json"
    write(manifest_path, manifest)

    with pytest.raises(MissionFixtureError, match="schema validation failed"):
        make_reader(pack_root)
