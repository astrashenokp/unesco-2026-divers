"""Immutable normalized evidence results returned to learning use cases."""

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum


class EvidenceStatus(StrEnum):
    OK = "ok"
    NOT_FOUND = "not_found"
    UNAVAILABLE = "unavailable"
    BLOCKED = "blocked"


class VerificationStatus(StrEnum):
    VERIFIED_METADATA = "verified_metadata"
    CURATED = "curated"
    UNVERIFIED = "unverified"
    CONFLICTING = "conflicting"


@dataclass(frozen=True, slots=True)
class EvidenceItem:
    evidence_id: str
    type: str
    title: str
    retrieved_at: datetime
    verification_status: VerificationStatus
    source_url: str | None = None


@dataclass(frozen=True, slots=True)
class EvidenceResult:
    action_id: str
    status: EvidenceStatus
    items: tuple[EvidenceItem, ...]
    limitations: tuple[str, ...]

