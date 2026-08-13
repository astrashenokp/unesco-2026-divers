"""Public receipt data with ownership kept outside its serialized shape."""

from dataclasses import dataclass
from datetime import datetime

from evidence_gym_api.learning.attempt import AxisAssessment


@dataclass(frozen=True, slots=True)
class EvidenceReceipt:
    id: str
    attempt_id: str
    mission_version: str
    assessments: tuple[AxisAssessment, AxisAssessment, AxisAssessment]
    evidence_refs: tuple[str, ...]
    created_at: datetime
    hash: str
    disclaimer: str
