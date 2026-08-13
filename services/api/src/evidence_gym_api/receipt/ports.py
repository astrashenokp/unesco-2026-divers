"""Persistence-independent receipt query boundary."""

from typing import Protocol

from evidence_gym_api.learning.value_objects import LearnerId
from evidence_gym_api.receipt.model import EvidenceReceipt


class ReceiptReader(Protocol):
    async def get_for_learner(
        self, receipt_id: str, learner_id: LearnerId
    ) -> EvidenceReceipt | None: ...
