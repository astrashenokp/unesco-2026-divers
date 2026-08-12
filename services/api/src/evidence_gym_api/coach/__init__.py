"""Bounded coaching provider boundary; AI implementation is owned by Role 3."""

from evidence_gym_api.coach.errors import CoachProviderError
from evidence_gym_api.coach.model import CoachHint, HintUncertainty
from evidence_gym_api.coach.ports import CoachPolicyReader, CoachProvider, CoachRequest

__all__ = [
    "CoachHint",
    "CoachPolicyReader",
    "CoachProvider",
    "CoachProviderError",
    "CoachRequest",
    "HintUncertainty",
]
