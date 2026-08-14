"""Physical schema for the first PostgreSQL persistence slice."""

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Float,
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

conclusions = Table(
    "conclusions",
    metadata,
    Column("attempt_id", String(128), ForeignKey("attempts.id", ondelete="CASCADE"), primary_key=True),
    Column("mission_version", String(128), nullable=False),
    Column("authenticity_json", JSON, nullable=False),
    Column("claim_veracity_json", JSON, nullable=False),
    Column("context_integrity_json", JSON, nullable=False),
    Column("post_confidence", SmallInteger, nullable=False),
    Column("share_decision", String(64), nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    CheckConstraint("post_confidence BETWEEN 0 AND 100", name="ck_conclusions_post_confidence"),
)

xp_ledger = Table(
    "xp_ledger",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("learner_id", String(128), nullable=False),
    Column("attempt_id", String(128), ForeignKey("attempts.id", ondelete="CASCADE"), nullable=False),
    Column("rule_code", String(128), nullable=False),
    Column("amount", Integer, nullable=False),
    Column("level", SmallInteger, nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    UniqueConstraint("attempt_id", "rule_code", name="uq_xp_ledger_attempt_rule"),
    CheckConstraint("amount >= 0", name="ck_xp_ledger_amount_nonnegative"),
    CheckConstraint("level BETWEEN 0 AND 4", name="ck_xp_ledger_level"),
)

skill_states = Table(
    "skill_states",
    metadata,
    Column("learner_id", String(128), nullable=False),
    Column("skill", String(128), nullable=False),
    Column("mastery", Float, nullable=False),
    Column("practices", Integer, nullable=False),
    Column("due_at", DateTime(timezone=True), nullable=True),
    Column("algorithm_version", Integer, nullable=False),
    Column("updated_at", DateTime(timezone=True), nullable=False),
    UniqueConstraint("learner_id", "skill", name="uq_skill_states_learner_skill"),
    CheckConstraint("practices >= 0", name="ck_skill_states_practices"),
)

learner_progress = Table(
    "learner_progress",
    metadata,
    Column("learner_id", String(128), primary_key=True),
    Column("total_xp", Integer, nullable=False),
    Column("updated_at", DateTime(timezone=True), nullable=False),
    CheckConstraint("total_xp >= 0", name="ck_learner_progress_total_xp"),
)

receipts = Table(
    "receipts",
    metadata,
    Column("id", String(128), primary_key=True),
    Column("attempt_id", String(128), ForeignKey("attempts.id", ondelete="RESTRICT"), nullable=False),
    Column("mission_version", String(128), nullable=False),
    Column("payload_json", JSON, nullable=False),
    Column("hash", String(128), nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    UniqueConstraint("attempt_id", name="uq_receipts_attempt"),
)

reports = Table(
    "reports",
    metadata,
    Column("id", String(128), primary_key=True),
    Column("reporter_id", String(128), nullable=False),
    Column("mission_id", String(128), nullable=False),
    Column("mission_version", String(128), nullable=True),
    Column("reason", String(32), nullable=False),
    Column("detail", String(1000), nullable=True),
    Column("status", String(32), nullable=False, server_default="pending"),
    Column("created_at", DateTime(timezone=True), nullable=False),
    CheckConstraint(
        "reason IN ('incorrect', 'harmful', 'outdated', 'copyright', 'accessibility', 'other')",
        name="ck_reports_reason",
    ),
    CheckConstraint(
        "status IN ('pending', 'under_review', 'resolved', 'dismissed')",
        name="ck_reports_status",
    ),
    Index("ix_reports_status_created", "status", "created_at"),
)

outbox = Table(
    "outbox",
    metadata,
    Column("event_id", String(128), primary_key=True),
    Column("event_type", String(128), nullable=False),
    Column("occurred_at", DateTime(timezone=True), nullable=False),
    Column("producer", String(128), nullable=False),
    Column("subject_id", String(128), nullable=False),
    Column("correlation_id", String(128), nullable=False),
    Column("schema_version", SmallInteger, nullable=False),
    Column("payload", JSON, nullable=False),
    Column("published_at", DateTime(timezone=True), nullable=True),
)

Index("ix_xp_ledger_learner_created", xp_ledger.c.learner_id, xp_ledger.c.created_at)
Index("ix_outbox_published_event", outbox.c.published_at, outbox.c.event_id)

__all__ = [
    "attempts",
    "conclusions",
    "evidence_actions",
    "idempotency_results",
    "learner_progress",
    "metadata",
    "outbox",
    "reports",
    "skill_states",
    "xp_ledger",
]
