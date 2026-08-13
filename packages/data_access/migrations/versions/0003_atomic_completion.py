"""Add atomic completion projections and outbox.

Revision ID: 0003_atomic_completion
"""

from alembic import op

from data_access.schema import (
    conclusions,
    learner_progress,
    outbox,
    receipts,
    skill_states,
    xp_ledger,
)

revision = "0003_atomic_completion"
down_revision = "0002_persistence_indexes"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    for table in (conclusions, xp_ledger, skill_states, learner_progress, receipts, outbox):
        table.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    for table in (outbox, receipts, learner_progress, skill_states, xp_ledger, conclusions):
        table.drop(bind=bind, checkfirst=True)
