"""Role 2 adapter from pinned mission policy to Role 4 gameplay rules."""

from gameplay import ProcessLevel, award_xp

from evidence_gym_api.learning.errors import MissionNotFound
from evidence_gym_api.learning.ports import CompletionPolicyReader, XpAward
from evidence_gym_api.learning.value_objects import MissionId, MissionVersion


class GameplayCompletionScorer:
    def __init__(self, policies: CompletionPolicyReader) -> None:
        self._policies = policies

    async def award(
        self,
        mission_id: MissionId,
        mission_version: MissionVersion,
        used_evidence_actions: int,
    ) -> XpAward:
        policy = await self._policies.get_process_levels(mission_id, mission_version)
        if policy is None:
            raise MissionNotFound("exact mission scoring policy is unavailable")
        grants = award_xp(
            tuple(
                ProcessLevel(
                    level=item.level,
                    xp_guidance=item.xp_guidance,
                    skill_tags=item.skill_tags,
                )
                for item in policy
            ),
            used_evidence_actions,
        )
        if len(grants) != 1:
            raise RuntimeError("P0 gameplay must return exactly one process XP grant")
        grant = grants[0]
        return XpAward(grant.rule_code, grant.amount, grant.level)
