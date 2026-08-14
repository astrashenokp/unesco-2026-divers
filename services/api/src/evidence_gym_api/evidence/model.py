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
class EvidenceLicense:
    identifier: str
    attribution: str
    use_basis: str


@dataclass(frozen=True, slots=True)
class EvidenceSource:
    source_type: str
    publisher: str
    retrieved_at: datetime
    license: EvidenceLicense
    limitations: tuple[str, ...]
    author: str | None = None
    canonical_url: str | None = None
    canonical_id: str | None = None
    published_at: datetime | None = None
    snapshot_hash: str | None = None


@dataclass(frozen=True, slots=True)
class EvidenceItem:
    evidence_id: str
    type: str
    title: str
    source: EvidenceSource
    retrieved_at: datetime
    verification_status: VerificationStatus
    source_url: str | None = None


@dataclass(frozen=True, slots=True)
class EvidenceResult:
    action_id: str
    status: EvidenceStatus
    items: tuple[EvidenceItem, ...]
    limitations: tuple[str, ...]
