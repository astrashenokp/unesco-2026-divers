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
/// The seven missions are ordered so each one teaches a distinct trap:
/// real media in a false context, a fabricated citation, a stripped
/// caption, an anonymous source, a chart that lies with true numbers, a
/// synthetic image that is nonetheless about something real, and a case
/// where the honest answer is that there is not enough to say.
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
        criteria: _uk(code)
            ? 'Висновок лише з відчуття або з вигляду.'
            : 'Concludes from instinct or visual appearance only.',
      ),
      ProcessLevel(
        level: 1,
        xpGuidance: 2,
        criteria: _uk(code)
            ? 'Перевірено джерело чи походження, але не контекст.'
            : 'Checks source identity or provenance but does not test context.',
        skillTags: const ['source_identity', 'provenance'],
      ),
      ProcessLevel(
        level: 2,
        xpGuidance: 4,
        criteria: _uk(code)
            ? 'Знайдено раніше джерело або розбіжність у даті чи місці.'
            : 'Finds the earlier source or date/place mismatch.',
        skillTags: const ['primary_source', 'context_time_place'],
      ),
      ProcessLevel(
        level: 3,
        xpGuidance: 6,
        criteria: _uk(code)
            ? 'Контекст підтверджено незалежно; медіа відокремлено від підпису.'
            : 'Corroborates context independently and separates media from caption.',
        skillTags: const ['corroboration', 'claim_decomposition'],
      ),
      ProcessLevel(
        level: 4,
        xpGuidance: 8,
        criteria: _uk(code)
            ? 'Калібрований висновок за трьома осями і відповідальне рішення про поширення.'
            : 'Makes a calibrated three-axis conclusion and chooses a responsible sharing decision.',
        skillTags: const ['uncertainty', 'responsible_sharing'],
      ),
    ];

enum DemoChapter { whoSaidIt, whenAndWhere, howItIsFramed }

const demoChapterOf = <String, DemoChapter>{
  'viral-flood-photo': DemoChapter.whoSaidIt,
  'anonymous-claim': DemoChapter.whoSaidIt,
  'citation-hunt': DemoChapter.whoSaidIt,
  'context-swap': DemoChapter.whenAndWhere,
  'old-protest-clip': DemoChapter.whenAndWhere,
  'true-numbers-false-story': DemoChapter.howItIsFramed,
  'synthetic-but-real-topic': DemoChapter.howItIsFramed,
};

String demoChapterTitle(DemoChapter chapter, String code) => switch (chapter) {
      DemoChapter.whoSaidIt => _uk(code) ? 'Хто це сказав?' : 'Who said it?',
      DemoChapter.whenAndWhere => _uk(code) ? 'Коли й де?' : 'When and where?',
      DemoChapter.howItIsFramed =>
        _uk(code) ? 'Як це подано?' : 'How is it framed?',
    };

const _order = [
  'viral-flood-photo',
  'anonymous-claim',
  'citation-hunt',
  'context-swap',
  'old-protest-clip',
  'true-numbers-false-story',
  'synthetic-but-real-topic',
];

LearningPath demoLearningPathFor(String code, {int completed = 0}) => LearningPath(
      version: '2026.08.0-demo',
      locale: code,
      nodes: [
        for (var i = 0; i < _order.length; i++)
          LearningPathNode(
            missionId: _order[i],
            title: demoMissionsFor(code)[_order[i]]!.title,
            state: i < completed
                ? 'completed'
                : i == completed
                    ? 'available'
                    : 'locked',
          ),
      ],
    );

EvidenceActionSpec _action(String id, String type, String en, String uk, String code) =>
    EvidenceActionSpec(id: id, type: type, label: _uk(code) ? uk : en);

Map<String, Mission> demoMissionsFor(String code) {
  final source = _action('check_source', 'source', 'Check the source', 'Перевірити джерело', code);
  final date = _action('check_date', 'date', 'Check the date', 'Перевірити дату', code);
  final reverse = _action('reverse_search', 'provenance', 'Reverse image search', 'Зворотний пошук фото', code);
  final others = _action('check_corroboration', 'corroboration', 'Find other reports', 'Знайти інші повідомлення', code);
  final citation = _action('check_citation', 'citation', 'Look up the paper', 'Знайти публікацію', code);
  final numbers = _action('check_numbers', 'uncertainty', 'Read the numbers', 'Прочитати цифри', code);

  return {
    'viral-flood-photo': Mission(
      id: 'viral-flood-photo',
      version: '1.0.0',
      title: _uk(code) ? 'Фото повені' : 'The flood photo',
      claim: _uk(code)
          ? 'Фото, що поширюється в мережі, нібито показує затоплення у твоєму '
              'регіоні після цьоготижневої зливи.'
          : 'A photo circulating online claims to show flooding in your region '
              'from this week\'s storm.',
      media: MissionMedia(
        type: 'image',
        altText: _uk(code)
            ? 'Драматичне фото затопленої міської вулиці з наполовину зануреним автомобілем.'
            : 'A dramatic photo of a flooded city street with a partially submerged car.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [source, date, reverse, others],
      skillTags: const ['source_identity', 'context_time_place', 'provenance'],
      contentWarnings: const ['natural-disaster'],
      rubric: demoRubric(code),
    ),
    'anonymous-claim': Mission(
      id: 'anonymous-claim',
      version: '1.0.0',
      title: _uk(code) ? 'Кажуть посадовці' : 'Officials say',
      claim: _uk(code)
          ? 'Допис стверджує: «посадовці підтвердили», що з наступного місяця '
              'зміняться правила. Жодного імені, жодного відомства.'
          : 'A post says "officials have confirmed" that the rules change next '
              'month. No name, no department.',
      media: MissionMedia(
        type: 'text',
        altText: _uk(code)
            ? 'Скріншот допису без вказаного автора чи відомства.'
            : 'A screenshot of a post with no named author or department.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [source, others, date],
      skillTags: const ['source_identity', 'corroboration', 'claim_decomposition'],
      contentWarnings: const ['impersonation'],
      rubric: demoRubric(code),
    ),
    'citation-hunt': Mission(
      id: 'citation-hunt',
      version: '1.0.0',
      title: _uk(code) ? 'Підозріле посилання' : 'The suspicious citation',
      claim: _uk(code)
          ? 'ШІ-відповідь посилається на дослідження 2021 року з переконливою '
              'назвою, авторами й номером DOI.'
          : 'An AI answer cites a 2021 study with a convincing title, authors '
              'and a DOI.',
      media: MissionMedia(
        type: 'text',
        altText: _uk(code)
            ? 'Абзац тексту з академічним посиланням у дужках.'
            : 'A paragraph of text with an academic citation in brackets.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [citation, source, others],
      skillTags: const ['citation_integrity', 'primary_source', 'uncertainty'],
      contentWarnings: const ['academic-integrity'],
      rubric: demoRubric(code),
      minimumCompletionEvidence: 3,
    ),
    'context-swap': Mission(
      id: 'context-swap',
      version: '1.0.0',
      title: _uk(code) ? 'Старе відео, новий підпис' : 'Old clip, new caption',
      claim: _uk(code)
          ? 'Відео черги до магазину підписане як зняте вчора у твоєму місті.'
          : 'A clip of a queue outside a shop is captioned as filmed yesterday '
              'in your city.',
      media: MissionMedia(
        type: 'video',
        altText: _uk(code)
            ? 'Коротке відео довгої черги людей уздовж вулиці.'
            : 'A short clip of a long queue of people along a street.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [date, reverse, others],
      skillTags: const ['context_time_place', 'provenance', 'corroboration'],
      contentWarnings: const [],
      rubric: demoRubric(code),
    ),
    'old-protest-clip': Mission(
      id: 'old-protest-clip',
      version: '1.0.0',
      title: _uk(code) ? 'Кадри не звідти' : 'Footage from elsewhere',
      claim: _uk(code)
          ? 'Кадри великого зібрання людей подані як події цього тижня в сусідній країні.'
          : 'Footage of a large gathering is presented as this week, in a '
              'neighbouring country.',
      media: MissionMedia(
        type: 'video',
        altText: _uk(code)
            ? 'Зйомка з висоти великого натовпу на площі.'
            : 'Aerial footage of a large crowd in a square.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [reverse, date, source, others],
      skillTags: const ['context_time_place', 'provenance', 'responsible_sharing'],
      contentWarnings: const ['civil-unrest'],
      rubric: demoRubric(code),
    ),
    'true-numbers-false-story': Mission(
      id: 'true-numbers-false-story',
      version: '1.0.0',
      title: _uk(code) ? 'Правдиві цифри, хибна історія' : 'True numbers, false story',
      claim: _uk(code)
          ? 'Графік показує різкий стрибок. Цифри взяті з офіційного джерела '
              'і не змінені.'
          : 'A chart shows a dramatic jump. The numbers come from an official '
              'source and have not been altered.',
      media: MissionMedia(
        type: 'image',
        altText: _uk(code)
            ? 'Стовпчикова діаграма, де вісь значень починається не з нуля.'
            : 'A bar chart whose value axis does not start at zero.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [numbers, source, date],
      skillTags: const ['claim_decomposition', 'uncertainty', 'context_time_place'],
      contentWarnings: const ['statistics-misuse'],
      rubric: demoRubric(code),
    ),
    'synthetic-but-real-topic': Mission(
      id: 'synthetic-but-real-topic',
      version: '1.0.0',
      title: _uk(code) ? 'Згенероване — і все ж про справжнє' : 'Generated, and still about something real',
      claim: _uk(code)
          ? 'Зображення майже напевно згенероване. Подія, яку воно ілюструє, '
              'справді сталася.'
          : 'The image is almost certainly generated. The event it illustrates '
              'did happen.',
      media: MissionMedia(
        type: 'image',
        altText: _uk(code)
            ? 'Гладке, надто досконале зображення сцени в місті.'
            : 'A smooth, unnaturally perfect image of a scene in a city.',
      ),
      reactions: const ['trust', 'suspicious', 'investigate'],
      evidenceActions: [reverse, others, source],
      // The point of the pack: synthetic does not mean false, and the
      // three axes must be allowed to disagree with one another.
      skillTags: const ['provenance', 'corroboration', 'responsible_sharing'],
      contentWarnings: const ['ai-generated-media'],
      rubric: demoRubric(code),
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
  final onlyDemo = _uk(code)
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

  EvidenceResult ok(String actionId, String id, String type, String en, String uk,
          String status, {List<String> extra = const []}) =>
      EvidenceResult(
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
    'viral-flood-photo:check_source': ok('check_source', 'ev-001', 'source_profile',
        'Account created 6 days ago, no prior posts',
        'Акаунт створено 6 днів тому, попередніх дописів немає', 'curated'),
    'viral-flood-photo:check_date': ok('check_date', 'ev-002', 'metadata',
        'Image metadata date is 3 years old',
        'Дата у метаданих зображення — трирічної давності', 'verified_metadata'),
    'viral-flood-photo:reverse_search': ok('reverse_search', 'ev-003', 'provenance',
        'The same image was published in 2023, in a different country',
        'Те саме зображення публікували 2023 року в іншій країні', 'curated'),
    'viral-flood-photo:check_corroboration': EvidenceResult(
      actionId: 'check_corroboration',
      status: 'not_found',
      attemptVersion: 1,
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
    'anonymous-claim:check_source': ok('check_source', 'ev-010', 'source_profile',
        'No department is named anywhere in the post or its replies',
        'Ні в дописі, ні у відповідях не названо жодного відомства', 'curated'),
    'anonymous-claim:check_corroboration': ok('check_corroboration', 'ev-011', 'corroboration',
        'The official register lists no rule change for that date',
        'В офіційному реєстрі немає змін правил на цю дату', 'verified_metadata'),
    'citation-hunt:check_citation': ok('check_citation', 'ev-020', 'citation',
        'The DOI resolves to a different paper, on an unrelated topic',
        'DOI веде до іншої статті на непов\'язану тему', 'verified_metadata',
        extra: [
          _uk(code)
              ? 'Правдоподібне формулювання — не доказ існування джерела.'
              : 'Fluent wording is not evidence that a source exists.',
        ]),
    'context-swap:check_date': ok('check_date', 'ev-030', 'metadata',
        'The clip was first uploaded two winters ago',
        'Відео вперше завантажили дві зими тому', 'verified_metadata'),
    'old-protest-clip:reverse_search': ok('reverse_search', 'ev-040', 'provenance',
        'The same footage appears in coverage from another country',
        'Ті самі кадри є в матеріалах з іншої країни', 'curated'),
    'true-numbers-false-story:check_numbers': ok('check_numbers', 'ev-050', 'analysis',
        'The axis starts at 94, not 0 — the jump is under two per cent',
        'Вісь починається з 94, а не з 0 — стрибок менший за два відсотки', 'curated',
        extra: [
          _uk(code)
              ? 'Цифри справжні. Оманливе саме подання.'
              : 'The numbers are real. The framing is what misleads.',
        ]),
    'synthetic-but-real-topic:reverse_search': ok('reverse_search', 'ev-060', 'provenance',
        'Generation artefacts in the hands and signage; no camera metadata',
        'Артефакти генерації на руках і вивісках; метаданих камери немає', 'curated'),
    'synthetic-but-real-topic:check_corroboration': ok(
        'check_corroboration', 'ev-061', 'corroboration',
        'Three independent outlets reported the event itself',
        'Три незалежні видання повідомили про саму подію', 'verified_metadata',
        extra: [
          _uk(code)
              ? 'Синтетичне зображення не робить подію вигаданою.'
              : 'A synthetic image does not make the event invented.',
        ]),
  };
}
