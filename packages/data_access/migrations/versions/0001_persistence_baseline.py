"""Create attempt and idempotency persistence baseline.

Revision ID: 0001_persistence_baseline
"""

from alembic import op

from data_access.schema import metadata

revision = "0001_persistence_baseline"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    metadata.create_all(bind=bind)


def downgrade() -> None:
    bind = op.get_bind()
    metadata.drop_all(bind=bind)
