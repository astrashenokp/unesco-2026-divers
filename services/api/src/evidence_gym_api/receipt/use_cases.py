"""Authorized receipt queries."""

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.receipt.model import EvidenceReceipt
from evidence_gym_api.receipt.ports import ReceiptReader


class ReceiptNotFound(Exception):
    """The receipt is absent or not owned by the caller."""


class GetReceipt:
    def __init__(self, receipts: ReceiptReader) -> None:
        self._receipts = receipts

    async def execute(self, principal: Principal, receipt_id: str) -> EvidenceReceipt:
        receipt = await self._receipts.get_for_learner(receipt_id, principal.subject)
        if receipt is None:
            raise ReceiptNotFound("receipt does not exist for this learner")
        return receipt
