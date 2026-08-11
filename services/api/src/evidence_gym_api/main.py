"""Default ASGI entry point."""

from evidence_gym_api.app import create_app

app = create_app()

