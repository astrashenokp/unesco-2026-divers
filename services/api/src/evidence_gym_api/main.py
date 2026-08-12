"""Default ASGI entry point."""

from pathlib import Path

from evidence_gym_api.app import create_app
from evidence_gym_api.catalog import FileMissionPolicyReader

REPOSITORY_ROOT = Path(__file__).resolve().parents[4]

app = create_app(
    catalog_reader=FileMissionPolicyReader(
        pack_root=REPOSITORY_ROOT / "content" / "p0-demo-pack",
        manifest_schema_path=REPOSITORY_ROOT / "contracts" / "scenario-pack.schema.json",
        mission_schema_path=REPOSITORY_ROOT / "contracts" / "mission-fixture.schema.json",
    )
)
