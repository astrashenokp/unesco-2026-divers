"""Add query and cleanup indexes to the persistence baseline.

Revision ID: 0002_persistence_indexes
"""

from alembic import op

revision = "0002_persistence_indexes"
down_revision = "0001_persistence_baseline"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # IF NOT EXISTS keeps this additive migration safe when a fresh baseline
    # was generated from metadata that already includes the indexes.
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_attempts_learner_state_updated "
        "ON attempts (learner_id, state, updated_at)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_idempotency_expiry "
        "ON idempotency_results (expires_at)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_idempotency_expiry")
    op.execute("DROP INDEX IF EXISTS ix_attempts_learner_state_updated")
