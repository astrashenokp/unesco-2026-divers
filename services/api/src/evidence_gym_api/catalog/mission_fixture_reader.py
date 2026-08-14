"""Validated, read-only adapter for Role 3 mission fixtures."""

from __future__ import annotations

from hashlib import sha256
from copy import deepcopy
import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator, FormatChecker
from jsonschema.exceptions import SchemaError, ValidationError

from evidence_gym_api.coach.model import CoachHint, HintUncertainty
from evidence_gym_api.learning.ports import MissionPolicy, ProcessLevelPolicy
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class MissionFixtureError(RuntimeError):
    """A checked-in mission pack failed integrity or schema validation."""


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise MissionFixtureError(f"duplicate JSON property: {key}")
        result[key] = value
    return result


def _load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as source:
            value = json.load(source, object_pairs_hook=_reject_duplicate_keys)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise MissionFixtureError(f"cannot read valid JSON from {path.name}") from exc
    if not isinstance(value, dict):
        raise MissionFixtureError(f"{path.name} must contain a JSON object")
    return value


def _validator(schema_path: Path) -> Draft202012Validator:
    schema = _load_json(schema_path)
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as exc:
        raise MissionFixtureError(f"invalid schema: {schema_path.name}") from exc
    return Draft202012Validator(schema, format_checker=FormatChecker())


class FileMissionPolicyReader:
    """Load immutable mission policy from a validated, hash-pinned pack."""

    def __init__(
        self,
        *,
        pack_root: Path,
        manifest_schema_path: Path,
        mission_schema_path: Path,
    ) -> None:
        self._pack_root = pack_root.resolve()
        self._manifest_validator = _validator(manifest_schema_path)
        self._mission_validator = _validator(mission_schema_path)
        self._manifest, self._policies, self._missions = self._load_missions()

    async def get_policy(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> MissionPolicy | None:
        return self._policies.get((mission_id, mission_version))

    async def get_deterministic_evidence_document(
        self,
        mission_id: MissionId,
        mission_version: MissionVersion,
        action_id: str,
    ) -> dict[str, Any] | None:
        """Return a defensive copy of one validated deterministic response."""

        mission = self._missions.get((mission_id, mission_version))
        if mission is None:
            return None
        for action in mission["evidenceActions"]:
            if action["id"] == action_id:
                return deepcopy(action["deterministicResponse"])
        return None

    async def get_coach_request_data(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> tuple[tuple[str, ...], dict[str, tuple[str, ...]], tuple[str, ...]] | None:
        """Return allowlisted action IDs and evidence refs for coach grounding."""

        mission = self._missions.get((mission_id, mission_version))
        if mission is None:
            return None
        evidence_by_action = {
            action["id"]: tuple(
                item["evidenceId"]
                for item in action["deterministicResponse"]["items"]
            )
            for action in mission["evidenceActions"]
        }
        return (
            tuple(evidence_by_action),
            evidence_by_action,
            tuple(mission["forbiddenLeakageTerms"]),
        )

    async def get_fallback_hint(
        self, mission_id: MissionId, mission_version: MissionVersion, level: int
    ) -> CoachHint | None:
        """Return one reviewed fallback hint that is safe before completion."""

        mission = self._missions.get((mission_id, mission_version))
        if mission is None:
            return None
        document = next(
            (hint for hint in mission["hintLadder"] if hint["level"] == level),
            None,
        )
        if document is None or not document["allowedBeforeConclusion"]:
            return None
        return CoachHint(
            text=document["text"],
            level=document["level"],
            suggested_action_id=document.get("suggestedActionId"),
            evidence_refs=tuple(document["evidenceRefs"]),
            uncertainty=HintUncertainty(document["uncertainty"]),
            safety_flags=("provider_degraded",),
            fallback=True,
        )

    async def get_process_levels(
        self, mission_id: MissionId, mission_version: MissionVersion
    ) -> tuple[ProcessLevelPolicy, ...] | None:
        """Return only the pinned, reviewed process-XP policy."""

        mission = self._missions.get((mission_id, mission_version))
        if mission is None:
            return None
        return tuple(
            ProcessLevelPolicy(
                level=entry["level"],
                xp_guidance=entry["xpGuidance"],
                skill_tags=tuple(entry["skillTags"]),
            )
            for entry in mission["rubric"]["processLevels"]
        )

    async def get_learning_path(self) -> dict[str, Any]:
        """Return a public path projection without answer or rubric material."""

        nodes = []
        for entry in self._manifest["missions"]:
            mission_id = MissionId(entry["id"])
            mission = self._mission_by_id(mission_id)
            if mission is None:
                continue
            nodes.append(
                {
                    "missionId": mission["id"],
                    "title": mission["title"],
                    "state": "available",
                }
            )

        return {
            "version": self._manifest["version"],
            "locale": self._manifest["locales"][0],
            "nodes": nodes,
        }

    async def get_public_mission(self, mission_id: MissionId) -> dict[str, Any] | None:
        """Return the public mission projection defined by contracts/openapi.yaml."""

        mission = self._mission_by_id(mission_id)
        if mission is None:
            return None

        presentation = mission["presentation"]
        return {
            "id": mission["id"],
            "version": mission["version"],
            "title": mission["title"],
            "claim": presentation["claim"],
            "media": deepcopy(presentation["media"]),
            "accessibility": deepcopy(presentation["accessibility"]),
            "reactions": list(presentation["allowedReactions"]),
            "evidenceActions": [
                {
                    "id": action["id"],
                    "type": action["type"],
                    "label": action["label"],
                }
                for action in mission["evidenceActions"]
            ],
            "skillTags": list(mission["learning"]["skillTags"]),
            "contentWarnings": list(mission["safety"]["contentWarnings"]),
            "testsCriticalIgnoring": mission["testsCriticalIgnoring"],
            "minimumCompletionEvidence": mission["rubric"][
                "minimumCompletionEvidence"
            ],
        }

    def _load_missions(
        self,
    ) -> tuple[
        dict[str, Any],
        dict[tuple[MissionId, MissionVersion], MissionPolicy],
        dict[tuple[MissionId, MissionVersion], dict[str, Any]],
    ]:
        manifest = _load_json(self._pack_root / "manifest.json")
        self._validate(self._manifest_validator, manifest, "manifest.json")

        policies: dict[tuple[MissionId, MissionVersion], MissionPolicy] = {}
        missions: dict[tuple[MissionId, MissionVersion], dict[str, Any]] = {}
        manifest_ids: set[str] = set()
        for entry in manifest["missions"]:
            manifest_id = entry["id"]
            if manifest_id in manifest_ids:
                raise MissionFixtureError(f"duplicate mission in manifest: {manifest_id}")
            manifest_ids.add(manifest_id)

            mission_path = self._resolve_mission_path(entry["file"])
            actual_hash = sha256(mission_path.read_bytes()).hexdigest()
            if actual_hash != entry["sha256"]:
                raise MissionFixtureError(f"mission hash mismatch: {manifest_id}")

            mission = _load_json(mission_path)
            self._validate(self._mission_validator, mission, mission_path.name)
            if mission["id"] != manifest_id:
                raise MissionFixtureError(
                    f"manifest and mission id differ: {manifest_id}"
                )

            policy = MissionPolicy(
                id=MissionId(mission["id"]),
                version=MissionVersion(mission["version"]),
                tests_critical_ignoring=mission["testsCriticalIgnoring"],
                minimum_completion_evidence=mission["rubric"][
                    "minimumCompletionEvidence"
                ],
            )
            key = (policy.id, policy.version)
            if key in policies:
                raise MissionFixtureError(
                    f"duplicate mission version: {policy.id}@{policy.version}"
                )
            policies[key] = policy
            missions[key] = mission
        return manifest, policies, missions

    def _mission_by_id(self, mission_id: MissionId) -> dict[str, Any] | None:
        for (stored_id, _version), mission in self._missions.items():
            if stored_id == mission_id:
                return mission
        return None

    def _resolve_mission_path(self, relative_path: str) -> Path:
        candidate = (self._pack_root / relative_path).resolve()
        if candidate.parent != self._pack_root / "missions":
            raise MissionFixtureError("mission path escapes the reviewed missions folder")
        if not candidate.is_file():
            raise MissionFixtureError(f"mission file is missing: {candidate.name}")
        return candidate

    @staticmethod
    def _validate(
        validator: Draft202012Validator,
        document: dict[str, Any],
        document_name: str,
    ) -> None:
        try:
            validator.validate(document)
        except ValidationError as exc:
            location = ".".join(str(part) for part in exc.absolute_path) or "root"
            raise MissionFixtureError(
                f"schema validation failed for {document_name} at {location}"
            ) from exc
