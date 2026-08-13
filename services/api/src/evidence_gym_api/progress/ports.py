"""Persistence-independent learner progress query port."""

from typing import Protocol

from evidence_gym_api.learning.ports import ProgressResult
from evidence_gym_api.learning.value_objects import LearnerId


class ProgressReader(Protocol):
    async def get_for_learner(self, learner_id: LearnerId) -> ProgressResult: ...
