"""Store skill mastery as a numeric projection.

Revision ID: 0004_skill_mastery_numeric
"""

from alembic import op
from sqlalchemy import Float, String

revision = "0004_skill_mastery_numeric"
down_revision = "0003_atomic_completion"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "skill_states",
        "mastery",
        existing_type=String(length=32),
        type_=Float(),
        postgresql_using="mastery::double precision",
    )


def downgrade() -> None:
    op.alter_column(
        "skill_states",
        "mastery",
        existing_type=Float(),
        type_=String(length=32),
        postgresql_using="mastery::text",
    )
