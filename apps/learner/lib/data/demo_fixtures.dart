import 'gameplay.dart';
import 'models.dart';

/// Deterministic, offline demo pack. Loaded when a learner enters the demo
/// key, so the golden path works with zero network calls (`MVP_SCOPE.md`:
/// "demo mode independent of live third-party APIs").
///
/// In real operation the server returns content already localized from a
/// reviewed scenario pack, so [Mission] carries plain strings. A fixture
/// has no server to do that, so everything here is a function of the
/// language code.
///
/// The offline demo mirrors `content/p0-demo-pack`: two Role 3 P0
/// missions, the same stable mission IDs, the same evidence action IDs
/// and the same minimum-evidence policy. It intentionally does not carry
/// extra local-only missions, because the judge-facing demo should show
/// the same pack that the API validates.
const demoAccessKey = 'EVIDENCE-GYM-DEMO';

bool _uk(String code) => code == 'uk';

/// Which chapter a mission belongs to. Grouping is a client-side
/// presentation of the ordered path the server already returns — no
/// contract field is invented here.

/// The process-level ladder, taken verbatim from the reviewed pack at
/// `content/p0-demo-pack`.
///
/// This offline demo uses one generic ladder across its local missions;
/// checked-in P0 mission JSON can carry mission-specific criteria and
/// skill tags. The invariant is the same in both places: XP must come
/// from curated content, and a demo that pays differently from its
/// reviewed rubric would be showing a judge numbers the product does
/// not actually award.
List<ProcessLevel> demoRubric(String code) => [
  ProcessLevel(
    level: 0,
    xpGuidance: 1,
    criteria:
        _uk(code)
            ? 'Висновок лише з відчуття або з вигляду.'
            : 'Concludes from instinct or visual appearance only.',
  ),
  ProcessLevel(
    level: 1,
    xpGuidance: 2,
    criteria:
        _uk(code)
            ? 'Перевірено джерело чи походження, але не контекст.'
            : 'Checks source identity or provenance but does not test context.',
    skillTags: const ['source_identity', 'provenance'],
  ),
  ProcessLevel(
    level: 2,
    xpGuidance: 4,
    criteria:
        _uk(code)
            ? 'Знайдено раніше джерело або розбіжність у даті чи місці.'
            : 'Finds the earlier source or date/place mismatch.',
    skillTags: const ['primary_source', 'context_time_place'],
  ),
  ProcessLevel(
    level: 3,
    xpGuidance: 6,
    criteria:
        _uk(code)
            ? 'Контекст підтверджено незалежно; медіа відокремлено від підпису.'
            : 'Corroborates context independently and separates media from caption.',
    skillTags: const ['corroboration', 'claim_decomposition'],
  ),
  ProcessLevel(
    level: 4,
    xpGuidance: 8,
    criteria:
        _uk(code)
            ? 'Калібрований висновок за трьома осями і відповідальне рішення про поширення.'
            : 'Makes a calibrated three-axis conclusion and chooses a responsible sharing decision.',
    skillTags: const ['uncertainty', 'responsible_sharing'],
  ),
];

enum DemoChapter { whoSaidIt, whenAndWhere, howItIsFramed }

const demoChapterOf = <String, DemoChapter>{
  'authentic-media-wrong-context': DemoChapter.whenAndWhere,
  'ai-citation-integrity': DemoChapter.whoSaidIt,
};

String demoChapterTitle(DemoChapter chapter, String code) => switch (chapter) {
  DemoChapter.whoSaidIt => _uk(code) ? 'Хто це сказав?' : 'Who said it?',
  DemoChapter.whenAndWhere => _uk(code) ? 'Коли й де?' : 'When and where?',
  DemoChapter.howItIsFramed =>
    _uk(code) ? 'Як це подано?' : 'How is it framed?',
};

const _order = ['authentic-media-wrong-context', 'ai-citation-integrity'];

LearningPath demoLearningPathFor(String code, {int completed = 0}) =>
    LearningPath(
      version: '2026.08.0-demo',
      locale: code,
      nodes: [
        for (var i = 0; i < _order.length; i++)
          LearningPathNode(
            missionId: _order[i],
            title: demoMissionsFor(code)[_order[i]]!.title,
            state:
                i < completed
                    ? 'completed'
                    : i == completed
                    ? 'available'
                    : 'locked',
          ),
      ],
    );

EvidenceActionSpec _action(
  String id,
  String type,
  String en,
  String uk,
  String code,
) => EvidenceActionSpec(id: id, type: type, label: _uk(code) ? uk : en);

Map<String, Mission> demoMissionsFor(String code) {
  final mediaSource = _action(
    'action-source-identity',
    'source_identity',
    'Check original poster',
    'Перевірити першоджерело',
    code,
  );
  final mediaProvenance = _action(
    'action-provenance-scan',
    'provenance',
    'Scan provenance',
    'Перевірити походження',
    code,
  );
  final mediaPrimary = _action(
    'action-primary-source',
    'primary_source',
    'Trace earliest source',
    'Знайти найраніше джерело',
    code,
  );
  final mediaContext = _action(
    'action-context-check',
    'context_time_place',
    'Check time and place',
    'Перевірити час і місце',
    code,
  );
  final mediaCorroboration = _action(
    'action-corroboration',
    'corroboration',
    'Look for independent confirmation',
    'Знайти незалежне підтвердження',
    code,
  );
  final claimParts = _action(
    'action-decompose-claim',
    'claim_decomposition',
    'Split citation and claim',
    'Розділити цитату й твердження',
    code,
  );
  final doiShape = _action(
    'action-doi-normalization',
    'citation_integrity',
    'Normalize DOI',
    'Нормалізувати DOI',
    code,
  );
  final registry = _action(
    'action-registry-lookup',
    'citation_integrity',
    'Query demo registries',
    'Перевірити демо-реєстри',
    code,
  );
  final journalAuthors = _action(
    'action-journal-author-check',
    'source_identity',
    'Check journal and authors',
    'Перевірити журнал і авторів',
    code,
  );
  final support = _action(
    'action-support-check',
    'primary_source',
    'Check support for 68%',
    'Перевірити доказ для 68%',
    code,
  );

  return {
    'authentic-media-wrong-context': Mission(
      id: 'authentic-media-wrong-context',
      version: '0.1.0',
      title:
          _uk(code)
              ? 'Справжнє фото, хибна історія'
              : 'Real Image, Wrong Story',
      claim:
          _uk(code)
              ? 'Терміново: центр Мюнхена нібито затоплює прямо зараз після прориву дамби, є сотні постраждалих.'
              : 'Breaking: central Munich is flooding right now after a dam failure, with hundreds injured.',
      media: MissionMedia(
        type: 'image',
        url: 'asset://p0-demo-pack/media/flood-context-card.jpg',
        altText:
            _uk(code)
                ? 'Червоний автомобіль та інші машини частково занурені на затопленій міській вулиці після сильної зливи.'
                : 'A red car and other vehicles are partly submerged on a flooded city street during heavy rain.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [
        mediaSource,
        mediaProvenance,
        mediaPrimary,
        mediaContext,
        mediaCorroboration,
      ],
      skillTags: const [
        'source_identity',
        'primary_source',
        'corroboration',
        'context_time_place',
        'provenance',
        'uncertainty',
        'responsible_sharing',
      ],
      contentWarnings: const ['natural-disaster'],
      rubric: demoRubric(code),
    ),
    'ai-citation-integrity': Mission(
      id: 'ai-citation-integrity',
      version: '0.1.0',
      title:
          _uk(code)
              ? 'Цитата, що звучить справжньо'
              : 'The Citation That Sounds Real',
      claim:
          _uk(code)
              ? 'Чатбот стверджує, що стаття Koval, Hrytsenko і Meyer (2025) з DOI 10.4242/jamr.2025.0199 доводить: 10-хвилинна гра з медіаграмотності зменшує вразливість українських студентів до дипфейків на 68%.'
              : 'A chatbot says this paper proves that one 10-minute media literacy game reduces deepfake susceptibility in Ukrainian students by 68%: Koval, Hrytsenko, and Meyer (2025), Cognitive Inoculation Against Deepfake Propaganda in Ukrainian Students, Journal of Applied Media Resilience, doi:10.4242/jamr.2025.0199.',
      media: MissionMedia(
        type: 'text',
        altText:
            _uk(code)
                ? 'Відповідь у стилі чатбота з академічною цитатою та DOI-подібним ідентифікатором.'
                : 'A chatbot-style answer containing a polished academic citation with a DOI-shaped identifier.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [
        claimParts,
        doiShape,
        registry,
        journalAuthors,
        support,
      ],
      skillTags: const [
        'citation_integrity',
        'claim_decomposition',
        'source_identity',
        'primary_source',
        'uncertainty',
        'responsible_sharing',
      ],
      contentWarnings: const ['academic-integrity'],
      rubric: demoRubric(code),
      minimumCompletionEvidence: 3,
    ),
  };
}

/// Deterministic offline coach, as a Socratic ladder.
///
/// `GAME_AND_LEARNING_DESIGN.md` specifies a hint ladder, not a single
/// hint: each rung is a little less oblique than the last. The ladder
/// stops at four and never reaches an answer — the top rung says so out
/// loud, because a coach that eventually caves teaches learners to wait
/// it out rather than to look.
///
/// [Hint.text] is a translation key resolved by `Strings.hintText`.
/// `fallback: true` is honest: there is no model behind this.
Hint demoHintFor({
  required int usedCount,
  required int level,
  String? nextActionId,
}) {
  final rung = level.clamp(1, 4);
  final uncertainty = switch (rung) {
    1 => 'low',
    2 || 3 => 'medium',
    _ => 'high',
  };
  return Hint(
    text: 'demo_hint_$rung',
    level: rung,
    // Only the middle rungs point at a specific check; the first is
    // deliberately open, and the last two are about reasoning, not doing.
    suggestedActionId: (rung == 2 || rung == 3) ? nextActionId : null,
    evidenceRefs: const [],
    uncertainty: uncertainty,
    safetyFlags: const ['provider_degraded'],
    fallback: true,
  );
}

/// Deterministic evidence, keyed by `${missionId}:${actionId}`.
///
/// Missions without a fixture for an action fall back to `not_found`,
/// which is a legitimate result the learner has to reason about rather
/// than a gap in the demo.
Map<String, EvidenceResult> demoEvidenceResultsFor(String code) {
  final onlyDemo =
      _uk(code)
          ? 'Демонстраційні дані — це не справжній запит.'
          : 'Demo fixture — not a live lookup.';
  final demoSource = EvidenceSource(
    sourceType: 'team_fixture',
    publisher: 'Evidence Gym P0 demo source packet',
    retrievedAt: DateTime.utc(2026, 8, 10, 9),
    license: const EvidenceLicense(
      identifier: 'EGYM-DEMO-0.1',
      attribution: 'Evidence Gym team-created demo metadata',
      useBasis: 'team_created',
    ),
    limitations: [onlyDemo],
  );

  EvidenceResult ok(
    String actionId,
    String id,
    String type,
    String en,
    String uk,
    String status, {
    List<String> extra = const [],
  }) => EvidenceResult(
    actionId: actionId,
    status: 'ok',
    // Overwritten by the repository, which owns the real value.
    attemptVersion: 1,
    items: [
      EvidenceItem(
        evidenceId: id,
        type: type,
        title: _uk(code) ? uk : en,
        source: demoSource,
        retrievedAt: DateTime.utc(2026, 8, 10, 9),
        verificationStatus: status,
      ),
    ],
    limitations: [onlyDemo, ...extra],
  );

  return {
    'authentic-media-wrong-context:action-source-identity': ok(
      'action-source-identity',
      'E-POST-REPOST',
      'post',
      'Repost account with no original media attribution',
      'Акаунт перепостив зображення без посилання на першоджерело',
      'curated',
      extra: [
        _uk(code)
            ? 'Сам перепост не доводить хибність твердження, але послаблює ідентичність джерела.'
            : 'A repost alone does not prove the claim false, but it weakens source identity.',
      ],
    ),
    'authentic-media-wrong-context:action-provenance-scan': ok(
      'action-provenance-scan',
      'E-MEDIA-METADATA',
      'metadata',
      'Camera-origin metadata from the checked-in USGS photo asset',
      'Метадані походження для перевіреного фото USGS у demo pack',
      'verified_metadata',
      extra: [
        _uk(code)
            ? 'Метадані підтримують історію походження, але не доводять правдивість підпису.'
            : 'Metadata supports origin history, not whether the caption is true.',
      ],
    ),
    'authentic-media-wrong-context:action-primary-source': ok(
      'action-primary-source',
      'E-ORIGINAL-CAPTION',
      'source_note',
      'USGS source page places the photo in Brooklyn, NY, September 2023',
      'Сторінка USGS розміщує фото у Брукліні, Нью-Йорк, у вересні 2023 року',
      'curated',
    ),
    'authentic-media-wrong-context:action-context-check': ok(
      'action-context-check',
      'E-MUNICH-NO-MATCH',
      'source_note',
      'Demo municipal bulletin has no matching Munich flood alert',
      'У демо-бюлетені немає відповідного попередження про повінь у Мюнхені',
      'curated',
      extra: [
        _uk(code)
            ? 'Відсутність в одному бюлетені не є універсальним доказом; її треба зважувати з першоджерелом.'
            : 'Absence in one curated bulletin is not universal proof; weigh it with the original source trace.',
      ],
    ),
    'authentic-media-wrong-context:action-corroboration': ok(
      'action-corroboration',
      'E-INDEPENDENT-CONTEXT',
      'source_note',
      'Independent demo context supports the Brooklyn 2023 explanation',
      'Незалежний демо-контекст підтримує пояснення про Бруклін 2023 року',
      'curated',
    ),
    'ai-citation-integrity:action-decompose-claim': ok(
      'action-decompose-claim',
      'E-CITATION-PARTS',
      'source_note',
      'Citation has three claims to verify separately',
      'У цитаті є три окремі твердження для перевірки',
      'curated',
    ),
    'ai-citation-integrity:action-doi-normalization': ok(
      'action-doi-normalization',
      'E-DOI-SHAPE',
      'metadata',
      'DOI-shaped string normalized as 10.4242/jamr.2025.0199',
      'DOI-подібний рядок нормалізовано як 10.4242/jamr.2025.0199',
      'curated',
      extra: [
        _uk(code)
            ? 'Синтаксис сам по собі не є доказом реєстрації.'
            : 'Syntax alone is not evidence of registration.',
      ],
    ),
    'ai-citation-integrity:action-registry-lookup': ok(
      'action-registry-lookup',
      'E-DOI-NOT-FOUND',
      'registry_record',
      'Queried demo registries returned no record for DOI 10.4242/jamr.2025.0199',
      'У перевірених демо-реєстрах немає запису для DOI 10.4242/jamr.2025.0199',
      'curated',
      extra: [
        _uk(code)
            ? 'Not found означає не знайдено в перевірених джерелах, а не сфабриковано.'
            : 'Not found in queried demo registries does not prove fabrication.',
      ],
    ),
    'ai-citation-integrity:action-journal-author-check': ok(
      'action-journal-author-check',
      'E-JOURNAL-MISMATCH',
      'registry_record',
      'Demo registry has no matching journal title or author cluster',
      'У демо-реєстрі немає відповідного журналу або групи авторів',
      'curated',
    ),
    'ai-citation-integrity:action-support-check': ok(
      'action-support-check',
      'E-SUPPORT-UNDETERMINED',
      'source_note',
      'No demo source in the fixture supports the exact 68% claim',
      'Жодне демо-джерело у fixture не підтримує точне твердження про 68%',
      'curated',
      extra: [
        _uk(code)
            ? 'Це підтримує обережний висновок про unsupported або insufficient evidence, не універсальну заяву.'
            : 'This supports an unsupported or insufficient-evidence conclusion, not a universal statement.',
      ],
    ),
  };
}
