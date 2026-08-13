"""Authenticated learner progress queries."""

from evidence_gym_api.identity.model import Principal
from evidence_gym_api.learning.ports import ProgressResult
from evidence_gym_api.progress.ports import ProgressReader


class GetMyProgress:
    def __init__(self, progress: ProgressReader) -> None:
        self._progress = progress

    async def execute(self, principal: Principal) -> ProgressResult:
        return await self._progress.get_for_learner(principal.subject)
