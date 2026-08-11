import 'models.dart';

/// Deterministic, offline demo pack. Loaded when a learner enters the demo
/// key on the auth screen (see MASCOT_AND_VISUAL_LANGUAGE.md "Pre-auth
/// sequence") so the golden path works with zero network calls, per
/// MVP_SCOPE.md ("demo mode independent of live third-party APIs") and
/// SCREEN_INVENTORY.md ("Demo route").
const demoAccessKey = 'EVIDENCE-GYM-DEMO';

final demoLearningPath = LearningPath(
  version: '2026.08.0-demo',
  locale: 'en',
  nodes: const [
    LearningPathNode(missionId: 'viral-flood-photo', title: 'The flood photo', state: 'available'),
    LearningPathNode(missionId: 'citation-hunt-01', title: 'The suspicious citation', state: 'locked'),
    LearningPathNode(missionId: 'context-swap-01', title: 'Old clip, new caption', state: 'locked'),
  ],
);

final demoMissions = <String, Mission>{
  'viral-flood-photo': Mission(
    id: 'viral-flood-photo',
    version: '1.0.0',
    title: 'The flood photo',
    claim:
        'A photo circulating online claims to show flooding in your region '
        'from this week\'s storm.',
    media: const MissionMedia(
      type: 'image',
      altText:
          'A dramatic photo of a flooded city street with a partially submerged car.',
    ),
    reactions: const ['trust', 'suspicious', 'investigate'],
    evidenceActions: const [
      EvidenceActionSpec(id: 'check_source', type: 'source', label: 'Check the source'),
      EvidenceActionSpec(id: 'check_date', type: 'date', label: 'Check the date'),
      EvidenceActionSpec(id: 'reverse_search', type: 'provenance', label: 'Reverse image search'),
      EvidenceActionSpec(id: 'check_corroboration', type: 'corroboration', label: 'Find other reports'),
    ],
    skillTags: const ['source_identity', 'context_time_place', 'provenance'],
  ),
};

/// Deterministic offline coach.
///
/// [Hint.text] is a translation *key* here, not prose — the demo pack has
/// to speak both languages, and unlike the real service (which returns
/// text already localized from a reviewed scenario pack) a fixture cannot
/// know the learner's locale. `Strings.hintText` resolves these keys and
/// passes any unrecognised string through untouched, so live server text
/// still displays verbatim.
///
/// `fallback: true` is the honest value: there is no model behind this.
Hint demoHintFor({required int usedCount, String? nextActionId}) {
  if (usedCount == 0) {
    return const Hint(
      text: 'demo_hint_start',
      level: 1,
      evidenceRefs: [],
      uncertainty: 'low',
      fallback: true,
    );
  }
  if (nextActionId != null) {
    return Hint(
      text: 'demo_hint_next',
      level: 2,
      suggestedActionId: nextActionId,
      evidenceRefs: const [],
      uncertainty: 'medium',
      fallback: true,
    );
  }
  return const Hint(
    text: 'demo_hint_conclude',
    level: 3,
    evidenceRefs: [],
    uncertainty: 'high',
    fallback: true,
  );
}

/// A tiny deterministic evidence table so the demo never depends on a
/// live provider. Keyed by `${missionId}:${actionId}`.
final demoEvidenceResults = <String, EvidenceResult>{
  'viral-flood-photo:check_source': EvidenceResult(
    actionId: 'check_source',
    status: 'ok',
    items: [
      EvidenceItem(
        evidenceId: 'ev-001',
        type: 'source_profile',
        title: 'Account created 6 days ago, no prior posts',
        retrievedAt: DateTime.utc(2026, 8, 10, 9, 0),
        verificationStatus: 'curated',
      ),
    ],
    limitations: const ['Demo fixture — not a live lookup.'],
  ),
  'viral-flood-photo:check_date': EvidenceResult(
    actionId: 'check_date',
    status: 'ok',
    items: [
      EvidenceItem(
        evidenceId: 'ev-002',
        type: 'metadata',
        title: 'Image metadata date is 3 years old',
        retrievedAt: DateTime.utc(2026, 8, 10, 9, 1),
        verificationStatus: 'verified_metadata',
      ),
    ],
    limitations: const ['Demo fixture — not a live lookup.'],
  ),
};
