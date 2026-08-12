"""Physical schema for the first PostgreSQL persistence slice."""

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    MetaData,
    SmallInteger,
    String,
    Table,
    UniqueConstraint,
)

metadata = MetaData()

attempts = Table(
    "attempts",
    metadata,
    # Domain identifiers are opaque strings; physical UUID enforcement belongs
    # to a later migration once all producers use UUIDv7.
    Column("id", String(128), primary_key=True),
    Column("learner_id", String(128), nullable=False),
    Column("mission_id", String(128), nullable=False),
    Column("mission_version", String(128), nullable=False),
    Column("allows_no_evidence_conclusion", Boolean, nullable=False),
    Column("minimum_required_evidence_actions", SmallInteger, nullable=False),
    Column("state", String(32), nullable=False),
    Column("version", Integer, nullable=False),
    Column("prediction_json", JSON, nullable=True),
    Column("evidence_action_refs", JSON, nullable=False),
    Column("conclusion_json", JSON, nullable=True),
    Column("created_at", DateTime(timezone=True), nullable=False),
    Column("updated_at", DateTime(timezone=True), nullable=False),
    CheckConstraint("minimum_required_evidence_actions BETWEEN 0 AND 6", name="ck_attempts_min_evidence"),
    CheckConstraint("version >= 1", name="ck_attempts_version_positive"),
    CheckConstraint(
        "state IN ('ready', 'predicted', 'investigating', 'concluded', 'reflected', 'completed')",
        name="ck_attempts_state",
    ),
    Index("ix_attempts_learner_state_updated", "learner_id", "state", "updated_at"),
)

evidence_actions = Table(
    "evidence_actions",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column(
        "attempt_id", String(128), ForeignKey("attempts.id", ondelete="CASCADE"), nullable=False
    ),
    Column("action_ref", String(256), nullable=False),
    Column("ordinal", SmallInteger, nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    UniqueConstraint("attempt_id", "action_ref", name="uq_evidence_actions_attempt_ref"),
    UniqueConstraint("attempt_id", "ordinal", name="uq_evidence_actions_attempt_ordinal"),
)

idempotency_results = Table(
    "idempotency_results",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("route", String(256), nullable=False),
    Column("learner_id", String(128), nullable=False),
    Column("key", String(128), nullable=False),
    Column("result_kind", String(32), nullable=False),
    Column("request_fingerprint", String(128), nullable=False),
    Column("result_json", JSON, nullable=False),
    Column("expires_at", DateTime(timezone=True), nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    UniqueConstraint("route", "learner_id", "key", name="uq_idempotency_scope"),
    Index("ix_idempotency_expiry", "expires_at"),
)

__all__ = ["attempts", "evidence_actions", "idempotency_results", "metadata"]
