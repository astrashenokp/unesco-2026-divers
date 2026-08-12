import 'package:flutter/widgets.dart';

import '../app_settings.dart';

/// Ukrainian + English UI strings (P0 in `MVP_SCOPE.md`).
///
/// Hand-written rather than generated from `.arb` files for now, so the
/// UI is not blocked on setting up `flutter gen-l10n`. This class has the
/// same shape as a generated one — swapping it for real `.arb` codegen
/// later is a mechanical change and no call site has to move.
///
/// [AppSettings.simpleLanguage] selects shorter, plainer wording for the
/// explanatory copy. It never removes a provenance or safety caveat; it
/// only rephrases. Anything a learner must understand to stay safe reads
/// the same in both modes.
class Strings {
  const Strings({required this.locale, required this.simple});

  final Locale locale;
  final bool simple;

  static Strings of(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Strings(locale: settings.locale, simple: settings.simpleLanguage);
  }

  bool get _uk => locale.languageCode == 'uk';

  String _s(String en, String uk) => _uk ? uk : en;

  String _p(String en, String uk, String enSimple, String ukSimple) =>
      simple ? (_uk ? ukSimple : enSimple) : (_uk ? uk : en);

  // ---------------------------------------------------------------- common
  String get appName => 'Evidence Gym';
  String get next => _s('Next', 'Далі');
  String get back => _s('Back', 'Назад');
  String get skip => _s('Skip', 'Пропустити');
  String get getStarted => _s('Get started', 'Почати');
  String get retry => _s('Try again', 'Спробувати ще');
  String get cancel => _s('Cancel', 'Скасувати');
  String get close => _s('Close', 'Закрити');
  String get send => _s('Send', 'Надіслати');
  String get loading => _s('Loading…', 'Завантаження…');

  // ------------------------------------------------------------ onboarding
  String get onboard1Title => _s('Investigate, don\'t guess.', 'Перевіряй, а не вгадуй.');
  String get onboard1Body => _p(
        'Evidence Gym trains the habit of checking source, date and context '
            'before you trust or share anything.',
        'Evidence Gym тренує звичку перевіряти джерело, дату й контекст, '
            'перш ніж довіряти чомусь або ділитися цим.',
        'Learn to check where something came from before you share it.',
        'Навчися перевіряти, звідки щось узялося, перш ніж поширювати.',
      );

  String get onboard2Title =>
      _s('The AI asks. It never decides for you.', 'ШІ запитує. Він не вирішує за тебе.');
  String get onboard2Body => _p(
        'Lupa is your coach. It points you toward evidence and lets you draw '
            'the conclusion — on three separate, independent axes.',
        'Лупа — твій коуч. Він показує, де шукати докази, а висновок робиш ти '
            '— за трьома окремими, незалежними осями.',
        'Lupa helps you look. You decide what it means.',
        'Лупа допомагає шукати. Що це означає — вирішуєш ти.',
      );

  String get onboard3Title => _s('Practice on real cases, safely.', 'Практика на реальних кейсах.');
  String get onboard3Body => _p(
        'Short missions. Careful reasoning is rewarded over guessing right. '
            '"Insufficient evidence" is always a valid answer.',
        'Короткі місії. Тут цінується уважне міркування, а не вдале вгадування. '
            '«Недостатньо доказів» — це завжди прийнятна відповідь.',
        'Short tasks. Thinking carefully counts more than being right.',
        'Короткі завдання. Думати уважно важливіше, ніж вгадати.',
      );

  // ------------------------------------------------------------------ auth
  String get authTitle => _s('Ready when you are', 'Готові, коли ти готова');
  String get continueAsGuest => _s('Continue as guest', 'Продовжити як гість');
  String get orDivider => _s('— or —', '— або —');
  String get demoKeyLabel => _s('Demo access key', 'Демо-ключ доступу');
  String get enterDemo => _s('Enter demo', 'Увійти в демо');
  String get demoKeyPrefilled => _s(
        'Key pre-filled — debug build only.',
        'Ключ підставлено — лише в debug-збірці.',
      );
  String demoKeyWrong(String key) => _s(
        'That key doesn\'t match. Try $key for this demo.',
        'Ключ не збігається. Для цього демо спробуй $key.',
      );
  String get demoExplain => _s(
        'Demo mode runs fully offline on a reviewed local pack — no live '
            'provider calls, exactly what you\'d show a judge.',
        'Демо-режим працює повністю офлайн на перевіреному локальному паку — '
            'без звернень до зовнішніх сервісів, саме те, що показують журі.',
      );

  // ------------------------------------------------------------------ path
  String get yourPath => _s('Your path', 'Твій шлях');
  String get pathEmpty => _s('No missions available yet.', 'Поки що немає доступних місій.');
  String get pathError =>
      _s('Couldn\'t load your path. Check your connection.', 'Не вдалося завантажити шлях. Перевір з\'єднання.');
  String get stateLocked => _s('locked', 'закрито');
  String get stateAvailable => _s('available', 'доступно');
  String get stateCompleted => _s('completed', 'пройдено');
  String get boosterDue => _s('practice due', 'час повторити');
  String get lockedReason =>
      _s('Finish the one before it', 'Заверши попередню');

  // Path header
  String statXp(int xp) => _s('$xp XP', '$xp XP');
  String get statXpLabel => _s('earned', 'зароблено');
  String statStreak(int days) => _s('$days days', '$days дн.');
  String get statStreakLabel => _s('in a row', 'поспіль');
  String statGoal(int done, int total) => _s('$done of $total', '$done з $total');
  String get statGoalLabel => _s('today', 'сьогодні');
  String pathProgress(int done, int total) =>
      _s('$done of $total missions done', 'Пройдено $done з $total місій');

  // Chapters and the continue card
  String get continueTitle => _s('Pick up where you left off', 'Продовжити з місця зупинки');
  String get continueAction => _s('Continue', 'Продовжити');
  String chapterProgress(int done, int total) => _s('$done of $total', '$done з $total');
  String nodePosition(int index, int total, String chapter) =>
      _s('mission $index of $total, chapter $chapter',
         'місія $index з $total, розділ $chapter');

  // Mission detail sheet
  String get missionSkills => _s('What this trains', 'Що це тренує');
  String get missionChecks => _s('Checks available', 'Доступні перевірки');
  String missionEstimate(int minutes) =>
      _s('about $minutes minutes', 'близько $minutes хв');
  String get startMission => _s('Start this mission', 'Почати місію');
  String get missionLockedTitle => _s('Not open yet', 'Ще не відкрито');

  /// Lupa's lines on the path screen, shown in sequence. Everything she
  /// says is also visible elsewhere on the screen, so missing a line
  /// costs the learner nothing.
  List<String> lupaPathLines({required int completed, required int total}) => [
        lupaPathLine(completed: completed, total: total),
        _p(
          'Whatever you pick, check who is behind it before you decide.',
          'Що б ти не обрала — спершу подивись, хто за цим стоїть.',
          'Always check who made it.',
          'Завжди дивись, хто це зробив.',
        ),
        _p(
          'Saying you do not have enough to decide is a real answer here.',
          '«Мені бракує даних, щоб сказати» — тут це справжня відповідь.',
          'You can always answer "not enough evidence".',
          'Завжди можна відповісти «недостатньо доказів».',
        ),
      ];

  /// What Lupa says on the path screen. Never a verdict, never pressure.
  String lupaPathLine({required int completed, required int total}) {
    if (completed == 0) {
      return _p(
        'Ready to look closely at something?',
        'Готова придивитися до чогось уважніше?',
        'Want to start?',
        'Хочеш почати?',
      );
    }
    if (completed >= total) {
      return _p(
        'You have been through everything here. The habit is the point, not the score.',
        'Ти пройшла тут усе. Головне — звичка, а не бали.',
        'You finished everything here.',
        'Ти пройшла тут усе.',
      );
    }
    return _p(
      'Nice work. Take the next one whenever you feel like it.',
      'Гарна робота. Наступну візьми, коли захочеш.',
      'Good. Next one when you want.',
      'Добре. Наступна — коли захочеш.',
    );
  }

  // --------------------------------------------------------------- mission
  String get missionStartError => _s('Couldn\'t start this mission.', 'Не вдалося почати цю місію.');
  String get firstInstinct => _s('First instinct?', 'Перше відчуття?');
  String get reactionTrust => _s('Trust', 'Довіряю');
  String get reactionSuspicious => _s('Suspicious', 'Підозріло');
  String get reactionInvestigate => _s('Investigate', 'Перевірити');
  String get howConfident => _s('How confident are you?', 'Наскільки ти впевнена?');
  String get howConfidentInThat => _s('How confident in that?', 'Наскільки впевнена в цьому?');

  /// Plain-language band for a 0–100 confidence value.
  String confidenceBand(int value) {
    if (value < 20) return _s('Very unsure', 'Зовсім не впевнена');
    if (value < 45) return _s('Unsure', 'Не впевнена');
    if (value < 65) return _s('Somewhat sure', 'Певною мірою впевнена');
    if (value < 85) return _s('Fairly sure', 'Досить впевнена');
    return _s('Very sure', 'Дуже впевнена');
  }

  String percentSpoken(int value) => _s('$value percent', '$value відсотків');
  String get startInvestigating => _s('Start investigating', 'Почати перевірку');
  String get investigateTitle => _s('Investigate', 'Перевірка');
  String get whatYouFound => _s('What you found', 'Що ти знайшла');
  String propUsed(String label) => _s('$label, already checked', '$label, вже перевірено');
  String get notFoundInSources =>
      _s('Not found in the queried sources.', 'Не знайдено в перевірених джерелах.');
  String get conclude => _s('Draw a conclusion', 'Зробити висновок');
  String get needOneEvidence => _s(
        'Check at least one piece of evidence first.',
        'Спершу перевір хоча б один доказ.',
      );
  String get conclusionTitle => _s('Three-axis conclusion', 'Висновок за трьома осями');
  String get overallConfidence => _s(
        'Overall, how has your confidence changed?',
        'Загалом, як змінилася твоя впевненість?',
      );
  String get wouldYouShare => _s('Would you share this?', 'Чи поширила б ти це?');
  String get shareDoNot => _s('Do not share', 'Не поширювати');
  String get shareWithContext => _s('Share with context', 'Поширити з контекстом');
  String get shareKeepInvestigating => _s('Keep investigating', 'Продовжити перевірку');
  String get submitConclusion => _s('Submit conclusion', 'Надіслати висновок');
  String get busyPrediction => _s('Recording your instinct…', 'Записуємо твоє відчуття…');
  String busyEvidence(String action) => _s('Checking $action…', 'Перевіряємо: $action…');
  String get busyConclusion => _s('Recording your conclusion…', 'Записуємо твій висновок…');

  // --------------------------------------------------------------- receipt
  String get receiptTitle => _s('Nicely investigated.', 'Гарна перевірка.');
  String receiptXp(int xp) => _s('+$xp process XP', '+$xp XP за процес');
  String receiptId(String id) => _s('Receipt: $id', 'Квитанція: $id');
  String get backToPath => _s('Back to the path', 'Повернутися до шляху');
  String get viewReceipt => _s('Open your evidence receipt', 'Відкрити квитанцію доказів');
  String get receiptScreenTitle => _s('Evidence receipt', 'Квитанція доказів');
  String get receiptConclusions => _s('What you concluded', 'Твій висновок');
  String get receiptEvidence => _s('Evidence you looked at', 'Докази, які ти переглянула');
  String get receiptNoEvidence => _s(
        'No evidence was recorded for this attempt.',
        'Для цієї спроби докази не зафіксовані.',
      );
  String receiptCreated(String when) => _s('Created $when', 'Створено $when');
  String receiptMissionVersion(String version) =>
      _s('Mission version $version', 'Версія місії $version');
  String get receiptUnsigned => _s(
        'Demo receipt — not signed.',
        'Демо-квитанція — без підпису.',
      );
  String receiptHash(String hash) => _s('Integrity: $hash', 'Цілісність: $hash');

  /// Server receipts carry their own disclaimer text; the demo pack sends
  /// a key instead, since a fixture cannot know the locale.
  String receiptDisclaimerText(String raw) =>
      raw == 'demo_receipt_disclaimer' ? receiptDisclaimer : raw;

  String get receiptDisclaimer => _s(
        'This receipt records how you investigated. It is not a certificate '
            'that something is true or false.',
        'Ця квитанція фіксує, як ти перевіряла. Це не сертифікат того, що щось '
            'є правдою чи неправдою.',
      );

  // ----------------------------------------------------------------- coach
  String get aiCoachLabel => _s('AI coach', 'ШІ-коуч');

  /// Spoken description of the mascot. The design system holds no
  /// strings, so every Lupa is labelled from here.
  String lupaLabel(String mood) => switch (mood) {
        'thinking' => _s('Lupa is thinking', 'Лупа думає'),
        'asking' => _s('Lupa is asking a question', 'Лупа ставить питання'),
        'encouraging' => _s(
            'Lupa is pleased with how you investigated',
            'Лупа рада тому, як ти перевіряла',
          ),
        'concerned' => _s(
            'Lupa noticed something went wrong',
            'Лупа помітила, що щось пішло не так',
          ),
        _ => _s('Lupa, your coach', 'Лупа, твій коуч'),
      };

  String get tapForMore => _s('Tap for more', 'Торкнись, щоб більше');

  // Why a primary action is unavailable. A disabled button with no
  // explanation is a dead end.
  String get needReaction =>
      _s('Choose a first reaction to begin.', 'Обери перше відчуття, щоб почати.');
  String get needConclusion => _s(
        'Answer all three axes and choose whether you would share.',
        'Дай відповідь за трьома осями і обери, чи поширила б ти це.',
      );
  String uncertaintySentence(String level) => switch (level) {
        'low' => _s(
            'The coach is fairly sure this hint is useful — check it yourself anyway.',
            'Коуч доволі впевнений, що ця підказка корисна — усе одно перевір сама.',
          ),
        'medium' => _s(
            'The coach is only somewhat sure. Verify before relying on it.',
            'Коуч не дуже впевнений. Перевір, перш ніж покладатися.',
          ),
        _ => _s(
            'The coach is unsure. Treat this as a question, not an answer.',
            'Коуч не впевнений. Сприймай це як питання, а не відповідь.',
          ),
      };
  String get coachFallback => _s(
        'Offline hint — the AI coach was unavailable.',
        'Офлайн-підказка — ШІ-коуч був недоступний.',
      );
  String get askCoach => _s('Ask the coach', 'Запитати коуча');

  /// Resolves demo-pack hint keys. Live server hints arrive already
  /// localized, so anything unrecognised passes straight through.
  ///
  /// Four rungs, each less oblique than the last. The fourth stops rather
  /// than answering: a coach that eventually caves teaches learners to
  /// wait it out instead of looking.
  String hintText(String raw) => switch (raw) {
        'demo_hint_1' => _p(
            'Before deciding anything: who actually put this in front of you, and when?',
            'Перш ніж щось вирішувати: хто саме показав тобі це — і коли?',
            'Who posted this, and when?',
            'Хто це опублікував і коли?',
          ),
        'demo_hint_2' => _p(
            'There is a check here you have not used yet. What would it tell you that you do not already know?',
            'Тут є перевірка, якої ти ще не робила. Що вона скаже такого, чого ти ще не знаєш?',
            'Try a check you have not used yet.',
            'Спробуй перевірку, якої ще не робила.',
          ),
        'demo_hint_3' => _p(
            'Suppose the thing you are most confident about is wrong. What would have had to happen?',
            'Припусти, що саме те, у чому ти найвпевненіша, — хибне. Що мало б статися?',
            'What if the part you are sure about is wrong?',
            'А якщо те, у чому ти впевнена, — хибне?',
          ),
        'demo_hint_4' => _p(
            'The three axes do not have to agree. Which of them are you actually answering right now?',
            'Три осі не мусять збігатися. На яку з них ти відповідаєш просто зараз?',
            'The three answers can differ. Which one are you on?',
            'Три відповіді можуть різнитися. Яка з них зараз?',
          ),
        _ => raw,
      };

  // --------------------------------------------------------------- profile
  String get profileTitle => _s('Your progress', 'Твій прогрес');

  // Identity and data
  String get youGuest => _s('Guest', 'Гість');
  String get guestExplained => _s(
        'Nothing you do here is tied to a name. Progress lives on this '
            'device only.',
        "Ніщо тут не прив'язане до імені. Прогрес зберігається лише на "
            'цьому пристрої.',
      );
  String get exportData => _s('Export my data', 'Експортувати мої дані');
  String get exportExplained => _s(
        'Copies everything this app holds about you, as readable text.',
        'Копіює все, що застосунок про тебе зберігає, у вигляді читабельного тексту.',
      );
  String get exportCopied => _s('Copied to the clipboard.', 'Скопійовано в буфер обміну.');

  // Receipt history
  String get historyTitle => _s('Your receipts', 'Твої квитанції');
  String get historyEmpty => _s(
        'Finish a mission and its receipt will appear here.',
        "Заверши місію — і її квитанція з'явиться тут.",
      );

  // Skill detail
  String get skillWhy => _s('Why it matters', 'Чому це важливо');

  /// Why each evidence skill is worth having. Written as something a
  /// learner can act on, not a definition.
  String skillWhyText(String code) => switch (code) {
        'source_identity' => _s(
            'Most misleading posts do not fake the content. They rely on you '
                'never asking who is behind it.',
            'Більшість оманливих дописів не підробляють зміст. Вони розраховують, '
                'що ти не спитаєш, хто за цим стоїть.',
          ),
        'primary_source' => _s(
            'A summary of a summary loses the caveats. The original almost '
                'always says something narrower.',
            'Переказ переказу губить застереження. Оригінал майже завжди '
                'говорить щось вужче.',
          ),
        'corroboration' => _s(
            'Ten accounts repeating one source is still one source.',
            'Десять акаунтів, що повторюють одне джерело, — це все одно одне джерело.',
          ),
        'context_time_place' => _s(
            'Real media in the wrong context is the most common trap, because '
                'nothing about the file is fake.',
            'Справжнє медіа в хибному контексті — найпоширеніша пастка, бо в '
                'самому файлі немає нічого підробленого.',
          ),
        'provenance' => _s(
            'Where a file came from is checkable. Whether it feels real is not.',
            'Звідки взявся файл — можна перевірити. Чи він «виглядає справжнім» — ні.',
          ),
        'citation_integrity' => _s(
            'A citation that looks correct is easy to generate. Checking that '
                'it exists takes seconds.',
            'Посилання, що виглядає правильним, легко згенерувати. Перевірити, '
                'чи воно існує, — справа секунд.',
          ),
        'claim_decomposition' => _s(
            'One post usually makes several claims. They are rarely all true '
                'or all false together.',
            'Один допис зазвичай містить кілька тверджень. Вони рідко бувають '
                'усі правдиві чи всі хибні разом.',
          ),
        'uncertainty' => _s(
            'Knowing what you cannot yet conclude is a skill, not a failure.',
            'Розуміти, чого ти ще не можеш стверджувати, — це навичка, а не поразка.',
          ),
        'responsible_sharing' => _s(
            'Sharing with the context attached costs one sentence and undoes '
                'most of the harm.',
            'Поширити разом із контекстом коштує одного речення — і знімає '
                'більшу частину шкоди.',
          ),
        _ => '',
      };
  String get skillTrainedBy => _s('Trained by', 'Тренується в місіях');
  String totalXp(int xp) => _s('$xp XP earned for how you investigate', '$xp XP за те, як ти перевіряєш');
  String get skillsTitle => _s('Evidence skills', 'Навички перевірки');
  String masteryPercent(int percent) => _s('$percent% mastered', '$percent% засвоєно');
  String get profileEmpty => _s(
        'Finish your first mission to start building skills.',
        'Заверши першу місію, щоб почати розвивати навички.',
      );
  String get xpMeaning => _s(
        'XP measures your process, not how clever or trustworthy you are.',
        'XP вимірює твій процес, а не те, наскільки ти розумна чи надійна.',
      );

  String skillName(String code) => switch (code) {
        'source_identity' => _s('Who is behind it', 'Хто за цим стоїть'),
        'primary_source' => _s('Finding the primary source', 'Пошук першоджерела'),
        'corroboration' => _s('Independent corroboration', 'Незалежне підтвердження'),
        'context_time_place' => _s('Time and place', 'Час і місце'),
        'provenance' => _s('Media provenance', 'Походження медіа'),
        'citation_integrity' => _s('Citation integrity', 'Достовірність посилань'),
        'claim_decomposition' => _s('Breaking down a claim', 'Розбір твердження'),
        'uncertainty' => _s('Handling uncertainty', 'Робота з невизначеністю'),
        'responsible_sharing' => _s('Responsible sharing', 'Відповідальне поширення'),
        _ => code,
      };

  // -------------------------------------------------------------- settings
  String get settingsTitle => _s('Settings', 'Налаштування');
  String get languageLabel => _s('Language', 'Мова');
  String get readingLabel => _s('Reading and motion', 'Читання та рух');
  String get simpleLanguageLabel => _s('Simpler wording', 'Простіші слова');
  String get simpleLanguageHint => _s(
        'Shorter sentences and plainer words. Safety notes stay the same.',
        'Коротші речення й простіші слова. Застереження лишаються ті самі.',
      );
  String get reduceMotionLabel => _s('Reduce animation', 'Менше анімації');
  String get reduceMotionHint => _s(
        'Turns off movement. Your system setting is always respected too.',
        'Вимикає рух. Системне налаштування теж завжди враховується.',
      );
  String get textSizeLabel => _s('Text size', 'Розмір тексту');
  String textSizePercent(int percent) => _s('$percent%', '$percent%');

  // ---------------------------------------------------------------- report
  String get reportTitle => _s('Report this content', 'Поскаржитися на контент');
  String get reportReason => _s('What is wrong?', 'Що не так?');
  String get reportIncorrect => _s('Something here is incorrect', 'Тут щось неправильно');
  String get reportHarmful => _s('This is harmful', 'Це шкідливо');
  String get reportOutdated => _s('This is out of date', 'Це застаріло');
  String get reportCopyright => _s('Copyright problem', 'Проблема з авторським правом');
  String get reportAccessibility => _s('I couldn\'t access this', 'Я не змогла це сприйняти');
  String get reportOther => _s('Something else', 'Щось інше');
  String get reportDetail => _s('Anything you want to add (optional)', 'Що хочеш додати (необов\'язково)');
  String get reportPrivacy => _s(
        'Please don\'t include personal information about yourself or anyone else.',
        'Будь ласка, не додавай особисту інформацію про себе чи інших.',
      );
  String get reportSent => _s(
        'Thank you. A human reviewer will look at this.',
        'Дякуємо. Це перегляне людина.',
      );

  /// Demo mode has no moderation queue, so it must not claim one.
  String get reportSentDemo => _s(
        'Recorded for this demo only — nothing was sent anywhere.',
        'Записано лише для цього демо — нічого нікуди не надіслано.',
      );

  String get reportFailed => _s(
        'Couldn\'t send that. Please try again.',
        'Не вдалося надіслати. Спробуй ще раз.',
      );

  // ------------------------------------------------------------ navigation
  String get navPath => _s('Path', 'Шлях');
  String get navProgress => _s('Progress', 'Прогрес');
  String get navProfile => _s('You', 'Ти');
  String get navSettings => _s('Settings', 'Налаштування');

  // ------------------------------------------------------------------ axes
  String get axisAuthenticity => _s('Media authenticity', 'Автентичність медіа');
  String get axisClaim => _s('Claim veracity', 'Достовірність твердження');
  String get axisContext => _s('Context integrity', 'Цілісність контексту');

  String get axisHelpAuthenticity => _p(
        'Is the file itself real, edited, or machine-generated? Synthetic does '
            'not automatically mean false.',
        'Чи є сам файл справжнім, відредагованим або згенерованим машиною? '
            'Синтетичне не означає автоматично неправдиве.',
        'Is the picture or video real, edited, or made by a computer?',
        'Фото чи відео справжнє, відредаговане, чи зроблене комп\'ютером?',
      );
  String get axisHelpClaim => _p(
        'What do current reliable sources actually support? This is separate '
            'from whether the file is real.',
        'Що насправді підтверджують надійні джерела зараз? Це окреме питання '
            'від того, чи справжній файл.',
        'Do trusted sources agree with what it says?',
        'Чи погоджуються надійні джерела з тим, що тут написано?',
      );
  String get axisHelpContext => _p(
        'Are the time, place, author and caption accurate? Real media in a '
            'false context is the most common trap.',
        'Чи правильні час, місце, автор і підпис? Справжнє медіа в хибному '
            'контексті — найпоширеніша пастка.',
        'Is it shown with the right date, place and caption?',
        'Чи показано це з правильною датою, місцем і підписом?',
      );

  // Stable API codes stay in English; only these display labels localize.
  String axisOptionLabel(String code) => switch (code) {
        'authentic' => _s('Authentic', 'Автентичне'),
        'synthetic' => _s('Synthetic', 'Синтетичне'),
        'altered' => _s('Altered', 'Змінене'),
        'supported' => _s('Supported', 'Підтверджено'),
        'contradicted' => _s('Contradicted', 'Спростовано'),
        'insufficient_evidence' => _s('Insufficient evidence', 'Недостатньо доказів'),
        'accurate' => _s('Accurate', 'Точний'),
        'misleading' => _s('Misleading', 'Оманливий'),
        'fabricated_context' => _s('Fabricated context', 'Вигаданий контекст'),
        'unknown' => _s('Unknown', 'Невідомо'),
        _ => code,
      };

  // -------------------------------------------------------------- a11y/etc
  String get demoBadge => _s('DEMO DATA', 'ДЕМО-ДАНІ');
  String get demoBannerText => _s(
        'Demo pack — offline, reviewed fixtures. Not live evidence.',
        'Демо-пак — офлайн, перевірені фікстури. Це не живі дані.',
      );

  // Evidence limitations
  String get showLimitations => _s('What this does not tell you', 'Чого це не каже');
  String get hideLimitations => _s('Hide', 'Сховати');

  // Hint ladder
  String hintLevel(int level) => _s('Nudge $level of 4', 'Підказка $level з 4');
  String get hintDeeper => _s('Still stuck? Ask again', 'Досі не ясно? Запитай ще');
  String get hintExhausted => _s(
        'That is as far as the coach will go. The conclusion is yours.',
        'Далі коуч не піде. Висновок — за тобою.',
      );

  /// Shown when a request never reached a server. Deliberately does not
  /// blame the learner's connection outright — the server may equally be
  /// down — and does not promise offline content we have not downloaded.
  String get offlineTitle => _s('No connection', 'Немає з\'єднання');
  String get offlineBody => _s(
        'We couldn\'t reach the server. Your progress on this screen is safe — '
            'try again when you\'re back online.',
        'Не вдалося зв\'язатися із сервером. Твій прогрес на цьому екрані '
            'збережено — спробуй ще раз, коли з\'явиться мережа.',
      );
  String get offlineDemoHint => _s(
        'The demo pack works fully offline.',
        'Демо-пак працює повністю офлайн.',
      );
}
