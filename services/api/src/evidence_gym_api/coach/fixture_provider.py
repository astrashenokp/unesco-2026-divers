"""Reviewed deterministic fallback backed by Role 3 mission fixtures."""

from evidence_gym_api.coach.errors import CoachProviderError
from evidence_gym_api.coach.model import CoachHint
from evidence_gym_api.coach.ports import CoachProvider, CoachRequest
from evidence_gym_api.catalog.mission_fixture_reader import FileMissionPolicyReader


class FixtureCoachProvider(CoachProvider):
    def __init__(self, fixtures: FileMissionPolicyReader) -> None:
        self._fixtures = fixtures

    async def request_hint(self, request: CoachRequest) -> CoachHint:
        hint = await self._fixtures.get_fallback_hint(
            request.mission_id, request.mission_version, request.level
        )
        if hint is None:
            raise CoachProviderError("reviewed fallback hint is unavailable")
        return hint

