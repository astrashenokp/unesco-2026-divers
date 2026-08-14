"""Add durable learner content report persistence.

Revision ID: 0005_reports
"""

from alembic import op

from data_access.schema import reports

revision = "0005_reports"
down_revision = "0004_skill_mastery_numeric"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    reports.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    reports.drop(bind=bind, checkfirst=True)
