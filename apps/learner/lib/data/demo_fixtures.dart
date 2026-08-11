import 'models.dart';

/// Deterministic, offline demo pack. Loaded when a learner enters the demo
/// key on the auth screen, so the golden path works with zero network
/// calls (`MVP_SCOPE.md`: "demo mode independent of live third-party
/// APIs"; `SCREEN_INVENTORY.md`: "Demo route").
///
/// In real operation the server returns content already localized from a
/// reviewed scenario pack, so [Mission] carries plain strings. A fixture
/// has no server to do that, so everything here is a function of the
/// language code instead. Ukrainian is the default the product ships
/// with, and a demo that shows Ukrainian chrome around English content
/// looks broken — which is exactly what the first run looked like.
const demoAccessKey = 'EVIDENCE-GYM-DEMO';

bool _uk(String code) => code == 'uk';

LearningPath demoLearningPathFor(String code) => LearningPath(
      version: '2026.08.0-demo',
      locale: code,
      nodes: [
        LearningPathNode(
          missionId: 'viral-flood-photo',
          title: _uk(code) ? 'Фото повені' : 'The flood photo',
          state: 'available',
        ),
        LearningPathNode(
          missionId: 'citation-hunt-01',
          title: _uk(code) ? 'Підозріле посилання' : 'The suspicious citation',
          state: 'locked',
        ),
        LearningPathNode(
          missionId: 'context-swap-01',
          title: _uk(code) ? 'Старе відео, новий підпис' : 'Old clip, new caption',
          state: 'locked',
        ),
      ],
    );

Map<String, Mission> demoMissionsFor(String code) => {
      'viral-flood-photo': Mission(
        id: 'viral-flood-photo',
        version: '1.0.0',
        title: _uk(code) ? 'Фото повені' : 'The flood photo',
        claim: _uk(code)
            ? 'Фото, що поширюється в мережі, нібито показує затоплення у '
                'твоєму регіоні після цьоготижневої зливи.'
            : 'A photo circulating online claims to show flooding in your '
                'region from this week\'s storm.',
        media: MissionMedia(
          type: 'image',
          altText: _uk(code)
              ? 'Драматичне фото затопленої міської вулиці з наполовину '
                  'зануреним автомобілем.'
              : 'A dramatic photo of a flooded city street with a partially '
                  'submerged car.',
        ),
        reactions: const ['trust', 'suspicious', 'investigate'],
        evidenceActions: [
          EvidenceActionSpec(
            id: 'check_source',
            type: 'source',
            label: _uk(code) ? 'Перевірити джерело' : 'Check the source',
          ),
          EvidenceActionSpec(
            id: 'check_date',
            type: 'date',
            label: _uk(code) ? 'Перевірити дату' : 'Check the date',
          ),
          EvidenceActionSpec(
            id: 'reverse_search',
            type: 'provenance',
            label: _uk(code) ? 'Зворотний пошук фото' : 'Reverse image search',
          ),
          EvidenceActionSpec(
            id: 'check_corroboration',
            type: 'corroboration',
            label: _uk(code) ? 'Знайти інші повідомлення' : 'Find other reports',
          ),
        ],
        skillTags: const ['source_identity', 'context_time_place', 'provenance'],
      ),
    };

/// Deterministic offline coach.
///
/// [Hint.text] is a translation *key*, not prose — resolved by
/// `Strings.hintText`, which passes live server text through untouched.
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

/// Deterministic evidence, so the demo never depends on a live provider.
/// Keyed by `${missionId}:${actionId}`.
Map<String, EvidenceResult> demoEvidenceResultsFor(String code) {
  final onlyDemo = _uk(code)
      ? 'Демонстраційні дані — це не справжній запит.'
      : 'Demo fixture — not a live lookup.';
  return {
    'viral-flood-photo:check_source': EvidenceResult(
      actionId: 'check_source',
      status: 'ok',
      items: [
        EvidenceItem(
          evidenceId: 'ev-001',
          type: 'source_profile',
          title: _uk(code)
              ? 'Акаунт створено 6 днів тому, попередніх дописів немає'
              : 'Account created 6 days ago, no prior posts',
          retrievedAt: DateTime.utc(2026, 8, 10, 9, 0),
          verificationStatus: 'curated',
        ),
      ],
      limitations: [onlyDemo],
    ),
    'viral-flood-photo:check_date': EvidenceResult(
      actionId: 'check_date',
      status: 'ok',
      items: [
        EvidenceItem(
          evidenceId: 'ev-002',
          type: 'metadata',
          title: _uk(code)
              ? 'Дата у метаданих зображення — трирічної давності'
              : 'Image metadata date is 3 years old',
          retrievedAt: DateTime.utc(2026, 8, 10, 9, 1),
          verificationStatus: 'verified_metadata',
        ),
      ],
      limitations: [onlyDemo],
    ),
    'viral-flood-photo:reverse_search': EvidenceResult(
      actionId: 'reverse_search',
      status: 'ok',
      items: [
        EvidenceItem(
          evidenceId: 'ev-003',
          type: 'provenance',
          title: _uk(code)
              ? 'Те саме зображення публікували 2023 року в іншій країні'
              : 'The same image was published in 2023, in a different country',
          retrievedAt: DateTime.utc(2026, 8, 10, 9, 2),
          verificationStatus: 'curated',
        ),
      ],
      limitations: [onlyDemo],
    ),
    'viral-flood-photo:check_corroboration': EvidenceResult(
      actionId: 'check_corroboration',
      status: 'not_found',
      items: const [],
      limitations: [
        onlyDemo,
        _uk(code)
            ? 'Жодне місцеве видання не повідомляло про затоплення цього тижня. '
                'Відсутність повідомлень — не доказ, але це варте уваги.'
            : 'No local outlet reported flooding this week. Absence of reports '
                'is not proof, but it is worth noticing.',
      ],
    ),
  };
}
