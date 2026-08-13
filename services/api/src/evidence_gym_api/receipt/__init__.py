"""Immutable Evidence Receipt application boundary."""

from evidence_gym_api.receipt.model import EvidenceReceipt
from evidence_gym_api.receipt.use_cases import GetReceipt, ReceiptNotFound

__all__ = ["EvidenceReceipt", "GetReceipt", "ReceiptNotFound"]
