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

  // ------------------------------------------------- sign-in unavailable
  String get signInUnavailableTitle =>
      _s('Signing in is not available yet', 'Вхід поки недоступний');
  String get signInUnavailableBody => _p(
        'The server cannot verify accounts at the moment, so guest access '
            'is not working. This is on our side, not yours.',
        "Сервер зараз не може перевіряти облікові записи, тож гостьовий "
            "вхід не працює. Це на нашому боці, не на твоєму.",
        'Guest sign-in is not working right now. It is our problem, not '
            'yours.',
        "Гостьовий вхід зараз не працює. Це наша проблема, не твоя.",
      );
  String get signInUnavailableHint => _s(
        'The demo key on the first screen works without signing in, and '
            'has the full set of missions.',
        "Демо-ключ на першому екрані працює без входу — і в ньому повний "
            "набір місій.",
      );

  // --------------------------------------------------------- audience mode
  //
  // The wording avoids calling the younger mode easier, simpler or for
  // beginners. It is none of those: the reasoning, the three axes and
  // the scoring are identical, and only the case material differs. A
  // learner told they are on the easy version will read every result
  // through that.
  String get audienceQuestion => _s('Who is playing?', 'Хто гратиме?');
  String get audienceAdult => _s('Adult', 'Доросла людина');
  String get audienceAdultBody => _s(
        'Every mission, including cases built on disasters and unrest.',
        "Усі місії, зокрема побудовані на катастрофах і заворушеннях.",
      );
  String get audienceChild => _s('Child or teen', 'Дитина або підліток');
  String get audienceChildBody => _s(
        'The same skills and the same scoring, with the distressing cases '
            'left out.',
        "Ті самі навички й те саме оцінювання, але без важких прикладів.",
      );
  String get audienceNotAGate => _s(
        'You can change this later in settings. It chooses what is suitable '
            'to show — it is not a lock.',
        "Це можна змінити згодом у налаштуваннях. Вибір стосується того, що "
            "доречно показувати, — це не замок.",
      );
  String get audienceLabel => _s('Content for', 'Контент для');

  /// Short forms for the navigation rail, which is 92dp wide and cannot
  /// hold a phrase without breaking it into fragments.
  String get audienceChildShort => _s('Teen', 'Підл.');
  String audienceHiddenNote(int n) => _s(
        n == 1
            ? '1 mission is hidden in this mode.'
            : '$n missions are hidden in this mode.',
        n == 1
            ? 'У цьому режимі приховано 1 місію.'
            : 'У цьому режимі приховано місій: $n.',
      );

  /// Plain-language names for the content warning tags, so a warning
  /// never appears to the learner as a raw slug.
  String contentWarningLabel(String tag) => switch (tag) {
        'natural-disaster' => _s('Natural disaster', 'Стихійне лихо'),
        'civil-unrest' => _s('Crowds and unrest', 'Натовпи й заворушення'),
        'academic-integrity' =>
          _s('Academic dishonesty', 'Академічна недоброчесність'),
        'ai-generated-media' =>
          _s('AI-generated media', 'Згенеровані ШІ матеріали'),
        'impersonation' => _s('Impersonation', 'Видавання себе за іншого'),
        'statistics-misuse' =>
          _s('Misused statistics', 'Маніпуляція статистикою'),
        'advertising' => _s('Advertising', 'Реклама'),
        'marketing-claim' => _s('Marketing claim', 'Рекламне твердження'),
        'clickbait' => _s('Clickbait', 'Клікбейт'),
        // An unknown tag is shown as itself rather than swallowed. A
        // warning nobody sees is worse than an ugly one.
        _ => tag,
      };

  String get contentWarningTitle =>
      _s('Before you open this', 'Перш ніж відкрити');
  String get contentWarningBody => _p(
        'This mission is built on real case material that some people find '
            'upsetting. You can open it when you are ready, or go back and '
            'pick another.',
        "Ця місія побудована на реальних матеріалах, які декого можуть "
            "засмутити. Відкрий, коли будеш готова, або повернись і обери "
            "іншу.",
        'This mission shows something that can be upsetting. Open it when '
            'you are ready.',
        "У цій місії є те, що може засмутити. Відкрий, коли будеш готова.",
      );
  String get contentWarningReveal => _s('Show the mission', 'Показати місію');

  // ---------------------------------------------------------- data notice
  //
  // Every line below is read off the purpose matrix in `PRIVACY.md`.
  // Nothing here invents a data practice or promises anything the
  // engineering baseline does not already commit to. If that document
  // changes, this copy has to change with it.
  String get noticeSummary => _s(
        'What this records, before you start.',
        'Що тут записується — до того, як почнеш.',
      );
  String get noticeDemoSummary => _s(
        'Demo mode records nothing. It runs on a local pack, offline.',
        "Демо-режим не записує нічого. Він працює на локальному паку, офлайн.",
      );
  String get noticeShow => _s('What is recorded', 'Що записується');
  String get noticeHide => _s('Hide', 'Сховати');

  List<String> get noticeDetail => _uk
      ? const [
          "Твої спроби й прогрес за навичками — щоб навчання продовжувалося з того місця, де ти зупинилася. Можна вивантажити або видалити.",
          "Впевненість і те, які перевірки ти робила — щоб показати тобі ж, як змінилася твоя думка.",
          "Мова та налаштування доступності — щоб інтерфейс лишався зручним.",
          "Ідентифікатор входу — лише для сесії, видаляється разом з обліковим записом.",
          "Не збирається: справжнє ім'я, точна дата народження, контакти, місцезнаходження, рекламний ID, історія переглядів. Політичних поглядів не виводимо й не позначаємо — ніколи.",
        ]
      : const [
          'Your attempts and skill progress, so learning continues where you left off. You can export or delete it.',
          'Your confidence and which checks you ran, so the app can show you how your own thinking moved.',
          'Language and accessibility settings, so the interface stays usable.',
          'A sign-in identifier, for the session only, deleted with the account.',
          'Not collected: legal name, exact birth date, contacts, location, advertising ID, browsing history. Political views are never inferred or labelled.',
        ];

  List<String> get noticeDemoDetail => _uk
      ? const [
          "Місії та докази вже в застосунку — до сервера нічого не йде.",
          "Прогрес живе лише в цій вкладці й зникає, коли ти її закриєш.",
          "Жодних звернень до зовнішніх сервісів.",
        ]
      : const [
          'The missions and evidence are already in the app — nothing goes to a server.',
          'Progress lives in this tab only and is gone when you close it.',
          'No calls to any outside service.',
        ];

  /// Replaces an earlier line that read "built for ages 16 and up".
  ///
  /// The product is for children too, and the younger mode is how that
  /// is done. Saying 16+ while shipping a child mode would have been the
  /// notice contradicting the app.
  String get noticeAgeDefault => _s(
        'Anyone can use this. Younger learners get the same skills with the '
            'distressing cases left out — choose that on the first screen or '
            'in settings.',
        "Користуватися може будь-хто. Для молодших — ті самі навички, але без "
            "важких прикладів; обрати це можна на першому екрані або в "
            "налаштуваннях.",
      );

  String get evidenceAlreadyUsedBody => _p(
        'You have already run this check — its result is still above. '
            'Each check counts once, so repeating one does not add to '
            'anything.',
        "Ти вже робила цю перевірку — її результат лишається вище. Кожна "
            "перевірка зараховується один раз, тож повтор нічого не додає.",
        'You already ran this check. Its result is above.',
        "Ти вже робила цю перевірку. Її результат вище.",
      );

  String get byArenaTitle => _s('Where your work went', 'Куди пішла робота');

  // --------------------------------------------------------------- admin
  //
  // Every figure is a cohort figure. The wording avoids anything that
  // reads as a score for a person, because an operator who starts
  // thinking of these as individual grades will start asking for the
  // per-learner view this screen deliberately does not have.
  String get adminTitle => _s('Cohort overview', 'Огляд групи');
  String get adminScopeNote => _p(
        'Aggregate only. This view answers questions about the group, not '
            'about any individual — it cannot show what one person '
            'concluded, believed, or how their confidence moved.',
        "Лише агреговано. Цей екран відповідає на питання про групу, а не "
            "про конкретну людину — він не може показати, що саме хтось "
            "вирішив, у що вірив і як змінилася його впевненість.",
        'Group figures only. Nothing here is about one person.',
        "Лише групові цифри. Тут немає нічого про окрему людину.",
      );
  String get adminTooFewTitle =>
      _s('Too few learners to report', 'Замало учасників для звіту');
  String adminTooFewBody(int minimum) => _p(
        'Below $minimum people, an average describes each of them. Figures '
            'appear once the group is large enough that no single learner '
            'can be read out of them.',
        "Менш ніж $minimum людей — і середнє описує кожного з них окремо. "
            "Цифри з'являться, коли група стане достатньою, щоб з них не "
            "можна було вичитати конкретну людину.",
        'With fewer than $minimum people, an average describes each one.',
        "З менш ніж $minimum людьми середнє описує кожного окремо.",
      );
  String get adminLearners => _s('Learners active', 'Активних учасників');
  String get adminLearnersMeaning => _s(
        'Started at least one mission in the period.',
        'Почали щонайменше одну місію за період.',
      );
  String get adminEvidenceFirst =>
      _s('Concluded after checking', 'Висновок після перевірки');
  String get adminEvidenceFirstMeaning => _p(
        'Share of conclusions with at least one evidence check behind them. '
            'The inverse is the exact habit this product exists to change, '
            'so it is the number to watch.',
        "Частка висновків, за якими стоїть хоча б одна перевірка. "
            "Протилежне — саме та звичка, заради зміни якої існує продукт, "
            "тож дивитися варто на це число.",
        'How often people checked something before deciding.',
        "Як часто люди щось перевіряли, перш ніж вирішити.",
      );
  String get adminUncertainty =>
      _s('Said "not enough evidence"', 'Сказали «недостатньо доказів»');
  String get adminUncertaintyMeaning => _p(
        'Not an error rate. This is how often people were willing to say '
            'the evidence did not settle it — a rise here is the product '
            'working, not failing.',
        "Це не частка помилок. Це те, як часто люди були готові сказати, "
            "що докази не вирішують питання. Зростання тут означає, що "
            "продукт працює, а не навпаки.",
        'How often people said the evidence was not enough. Higher is good.',
        "Як часто люди казали, що доказів бракує. Більше — краще.",
      );
  String get adminMedianLevel =>
      _s('Typical process level', 'Типовий рівень процесу');
  String get adminMedianLevelMeaning => _s(
        'Median rung reached, from 0 to 4.',
        'Медіанна сходинка, від 0 до 4.',
      );
  String get adminByArena => _s('By subject', 'За темами');
  String get adminReports => _s('Content reports', 'Скарги на контент');
  String adminReportsCount(int n) =>
      _s('$n awaiting review', 'Очікують розгляду: $n');
  String get adminReportsMeaning => _p(
        'Reports learners filed about published content. Until a moderation '
            'owner is named, this is a count and not a queue.',
        "Скарги на опублікований контент. Доки не призначено відповідального "
            "за модерацію, це лічильник, а не черга.",
        'Reports about content. Nobody is assigned to review them yet.',
        "Скарги на контент. Поки ніхто не призначений їх розглядати.",
      );
  String get adminNoIndividualsTitle =>
      _s('There is no per-learner view', 'Погляду на окрему людину немає');
  String get adminNoIndividualsBody => _p(
        'This product records what someone believed before they checked and '
            'how their mind changed. A screen replaying one named person\'s '
            'beliefs is a different product from the one PRIVACY.md '
            'describes, so it does not exist. A teacher who needs to know '
            'how one learner is doing should ask them.',
        "Цей продукт записує, у що людина вірила до перевірки і як змінила "
            "думку. Екран, який відтворює переконання конкретної названої "
            "людини, — це вже інший продукт, ніж описаний у PRIVACY.md, тож "
            "його немає. Учителю, якому треба знати, як справи в конкретного "
            "учня, варто запитати самого учня.",
        'We do not show one person\'s answers to anyone else. Ask them '
            'instead.',
        "Ми не показуємо чиїсь відповіді іншим. Краще запитати саму людину.",
      );

  // --------------------------------------------------------- leaderboard
  //
  // The wording never praises being right, because the board does not
  // measure it. Every phrase here is about how much was checked.
  String get boardTitle => _s('Board', 'Дошка');
  String get boardExplain => _p(
        'Ranked by how much people investigated, not by how often they '
            'turned out to be right. Nothing here can be won by guessing '
            'well — the only way up is to check more.',
        "Рейтинг за тим, скільки людина перевіряла, а не за тим, як часто "
            "вгадувала. Тут нічого не виграти вдалою здогадкою — вгору веде "
            "лише ретельніша перевірка.",
        'Ranked by how much you checked, not by how often you were right.',
        "Рейтинг за тим, скільки ти перевіряла, а не за влучністю.",
      );
  String get boardJoinTitle => _s('Join the board?', 'Долучитися до дошки?');
  String get boardJoinBody => _p(
        'You choose a handle. Your real name is never used, nothing about '
            'your conclusions is shown to anyone, and you can leave at any '
            'time.',
        "Ти обираєш псевдонім. Справжнє ім'я не використовується, ніхто не "
            "бачить твоїх висновків, і піти можна будь-коли.",
        'You pick a nickname. Nobody sees your answers.',
        "Ти обираєш псевдонім. Ніхто не бачить твоїх відповідей.",
      );
  String get boardJoin => _s('Choose a handle and join', 'Обрати псевдонім');
  String get boardLeave => _s('Leave the board', 'Піти з дошки');
  String get boardEmpty =>
      _s('Nobody has joined yet.', 'Поки ніхто не долучився.');
  String boardPlace(int place) => _s('place $place', 'місце $place');
  String boardXpAndMissions(int xp, int missions) => _s(
        '$xp XP from $missions missions',
        '$xp XP за $missions місій',
      );
  String get boardThatIsYou => _s('this is you', 'це ти');
  String get boardPrivacyNote => _p(
        'The board shows a handle, process XP and a mission count. It never '
            'shows what anyone concluded, how confident they were, or how '
            'often they were right — those belong to the learner alone.',
        "Дошка показує псевдонім, XP за процес і кількість місій. Вона "
            "ніколи не показує, який висновок хтось зробив, наскільки був "
            "упевнений і як часто мав рацію — це належить лише самій людині.",
        'The board shows a nickname and XP. It never shows anyone\'s '
            'answers.',
        "Дошка показує псевдонім і XP. Чужих відповідей вона не показує.",
      );
  String get boardHandleLabel => _s('Handle', 'Псевдонім');
  String get boardHandleHint => _s(
        'Other learners will see this. Please do not use your real name.',
        "Інші учасники це побачать. Будь ласка, не використовуй справжнє ім'я.",
      );
  String get navBoard => _s('Board', 'Дошка');

  // ---------------------------------------------------------- connection
  String get offlineBadge => _s('Offline', 'Офлайн');
  String get offlineBannerText => _p(
        'You are offline. Missions already downloaded still work, and '
            'anything you finish is sent when the connection returns.',
        "Ти офлайн. Уже завантажені місії працюють, а все завершене "
            "надішлеться, щойно з'явиться зв'язок.",
        'You are offline. Downloaded missions still work.',
        "Ти офлайн. Завантажені місії працюють.",
      );
  String get onlineAgain => _s('Back online', "Зв'язок відновлено");

  // ------------------------------------------------------- offline packs
  String get offlineLabel => _s('Offline', 'Офлайн');
  String get prefetchLabel =>
      _s('Download missions ahead', 'Завантажувати місії наперед');
  String get prefetchHint => _p(
        'Keeps the next few missions on this device so a lost connection '
            'does not stop you mid-path. Uses a little storage and a little '
            'data.',
        "Тримає кілька наступних місій на цьому пристрої, щоб втрачений "
            "зв'язок не спиняв тебе посеред шляху. Витрачає трохи місця й "
            "трохи трафіку.",
        'Keeps the next missions on this device in case you lose signal.',
        "Тримає наступні місії на пристрої на випадок втрати зв'язку.",
      );
  String prefetchReady(int n) => _s(
        n == 1 ? '1 mission ready offline' : '$n missions ready offline',
        n == 1 ? 'Офлайн готова 1 місія' : 'Офлайн готових місій: $n',
      );
  String get prefetchNone =>
      _s('Nothing downloaded yet', 'Поки нічого не завантажено');

  // ------------------------------------------------------ empty progress
  //
  // An empty screen that only reports zero is worse than no screen: it
  // spends a whole destination telling someone they have done nothing.
  // Before there is progress, this space explains what will be measured
  // and offers the one action that starts it.
  String get progressEmptyTitle =>
      _s('Nothing measured yet', 'Поки нічого не виміряно');
  String get progressEmptyBody => _p(
        'Skills appear here once you have finished a mission. Each one is '
            'built from the checks you actually ran, not from how many '
            'answers you got right.',
        "Навички з'являться тут після першої пройденої місії. Кожна "
            "будується з перевірок, які ти справді зробила, а не з "
            "кількості вгаданих відповідей.",
        'Skills appear here after your first mission.',
        "Навички з'являться тут після першої місії.",
      );
  String get progressEmptyAction =>
      _s('Start your first mission', 'Почати першу місію');
  String get progressWhatIsMeasured =>
      _s('What gets measured', 'Що саме вимірюється');

  /// Plain descriptions of the skills, shown before any exist so the
  /// screen has something true to say from the first visit.
  List<({String name, String what})> get skillPreview => _uk
      ? const [
          (name: 'Хто це сказав', what: 'Чи можна встановити джерело й автора.'),
          (name: 'Коли й де', what: 'Чи збігаються час і місце з тим, що заявлено.'),
          (name: 'Першоджерело', what: 'Чи існує оригінал, на який усі посилаються.'),
          (name: 'Підтвердження', what: 'Чи каже це саме хтось незалежний.'),
          (name: 'Невизначеність', what: 'Чи визнано те, чого докази не показують.'),
        ]
      : const [
          (name: 'Who said it', what: 'Whether the source and author can be established.'),
          (name: 'When and where', what: 'Whether time and place match the claim.'),
          (name: 'Primary source', what: 'Whether the original everyone cites exists.'),
          (name: 'Corroboration', what: 'Whether anyone independent says the same.'),
          (name: 'Uncertainty', what: 'Whether what the evidence cannot show is named.'),
        ];

  // -------------------------------------------------------- level ladder
  String get ladderTitle => _s('How this is scored', 'Як це оцінюється');
  String get ladderIntro => _p(
        'Five rungs, and not one of them asks whether you were right. '
            'Investigating carefully and reaching the wrong conclusion '
            'scores above guessing correctly — that is the whole point of '
            'scoring the process.',
        "П'ять сходинок, і жодна не питає, чи ти вгадала. Уважно перевірити "
            "й дійти хибного висновку тут вартує більше, ніж вгадати "
            "правильно. Саме для цього й оцінюється процес.",
        'Five rungs. None of them asks if you were right — only how you '
            'checked.',
        "П'ять сходинок. Жодна не питає, чи ти вгадала, — лише як ти "
            "перевіряла.",
      );
  String ladderLevel(int level, int total) =>
      _s('Level $level of $total', 'Рівень $level з $total');
  String ladderXp(int xp) => _s('$xp XP', '$xp XP');
  String get ladderReached => _s('you reached this', 'ти тут');
  String get ladderNext => _s('next', 'далі');

  // ------------------------------------------------------------ correction
  String get correctionTitle =>
      _s('This mission was corrected', 'Цю місію виправили');
  String correctionBody(String was, String now) => _p(
        'You worked on version $was. It is now version $now. Your record '
            'stands exactly as you made it — nothing here has been rewritten '
            '— but the material behind it has been corrected since.',
        "Ти працювала з версією $was. Тепер це версія $now. Твій запис "
            "лишається таким, яким ти його зробила — тут нічого не "
            "переписано, — але матеріал за ним відтоді виправили.",
        'You worked on an older version of this mission. Your record is '
            'unchanged, but the material was corrected since.',
        "Ти працювала зі старішою версією. Твій запис не змінено, але "
            "матеріал відтоді виправили.",
      );

  // ------------------------------------------------------- streak and XP
  //
  // The streak is a profile signal and never gates a reward, so the copy
  // must not read as a threat. Nothing here says "don't lose it".
  String streakDays(int n) => _s(
        n == 1 ? '1 day' : '$n days',
        n == 1 ? '1 день' : '$n дн.',
      );
  String get streakLabel => _s('in a row', 'поспіль');
  String get streakNone => _s('not started', 'ще не почато');
  String get streakPaused => _s('paused', 'на паузі');
  String get streakPauseAction => _s('Pause the streak', 'Поставити на паузу');
  String get streakResumeAction => _s('Resume it', 'Зняти з паузи');
  String get streakExplain => _p(
        'Days you investigated. It never unlocks or blocks anything, and '
            'missing a day is forgiven once. Pause it whenever you need to.',
        "Дні, коли ти перевіряла. Це нічого не відкриває й нічого не "
            "блокує, а один пропущений день пробачається. Ставити на паузу "
            "можна будь-коли.",
        'Days you investigated. It does not unlock anything.',
        "Дні, коли ти перевіряла. Воно нічого не відкриває.",
      );
  String get streakPausedExplain => _p(
        'Paused. Nothing counts against you until you turn it back on.',
        "На паузі. Доки не увімкнеш, ніщо не зараховується проти тебе.",
        'Paused. Nothing counts against you.',
        "На паузі. Нічого не зараховується проти тебе.",
      );

  String get processLevelTitle =>
      _s('How you worked', 'Як ти працювала');
  String processLevelOf(int level) => _s(
        'Process level $level of 4',
        'Рівень процесу $level з 4',
      );
  String get processLevelExplain => _p(
        'This is what the XP was for. It counts what you checked, not '
            'whether your conclusion turned out to match — investigating '
            'well after a wrong first instinct scores the same as being '
            'right from the start.',
        "Саме за це нараховано XP. Рахується те, що ти перевірила, а не чи "
            "збігся твій висновок: добре перевірити після хибного першого "
            "відчуття — те саме, що вгадати одразу.",
        'This is what the XP was for. It counts what you checked, not '
            'whether you were right.',
        "Саме за це нараховано XP. Рахується перевірене, а не правильність.",
      );
  String processLevelNext(String criteria) =>
      _s('Next rung: $criteria', 'Наступна сходинка: $criteria');

  // ---------------------------------------------------------------- arenas
  //
  // Named for what the learner meets, not for an academic category.
  // "Health and science misinformation" is a research label; "someone
  // says a study proves it" is the thing they actually scrolled past.
  String get arenasTitle =>
      _s('What are you up against?', 'Проти чого працюємо?');
  String get arenasIntro => _p(
        'The same three checks work everywhere. Pick the ground you want '
            'to practise on — you can change it whenever you like.',
        "Ті самі три перевірки працюють усюди. Обери ґрунт, на якому "
            "хочеться потренуватися, — змінити можна будь-коли.",
        'The same checks work everywhere. Pick where to start.',
        "Ті самі перевірки працюють усюди. Обери, з чого почати.",
      );
  String get arenaAll => _s('Everything', 'Усе разом');
  String get arenaAllExample => _p(
        'Every mission, in the order the skills build.',
        "Усі місії, у порядку, в якому нарощуються навички.",
        'All the missions in order.',
        "Усі місії по порядку.",
      );

  String arenaTitleOf(String arena) => switch (arena) {
        'crisis' => _s('Crisis and emergency', 'Криза й надзвичайне'),
        'healthAndScience' => _s('Health and science', 'Здоров’я і наука'),
        'powerAndMoney' => _s('Power and money', 'Влада й гроші'),
        'syntheticAndRecycled' =>
          _s('Fake and recycled media', 'Підроблене й перевикористане'),
        _ => arena,
      };

  /// One concrete thing from the arena, in the words a learner would use.
  String arenaExampleOf(String arena) => switch (arena) {
        'crisis' => _p(
            'A flood photo from another year. Footage of a crowd moved to a '
                'different country. The pull to share before checking is '
                'strongest here.',
            "Фото повені з іншого року. Кадри натовпу, перенесені в іншу "
                "країну. Саме тут найдужче тягне поширити, не перевіривши.",
            'An old flood photo shared as if it were today.',
            "Старе фото повені, подане як сьогоднішнє.",
          ),
        'healthAndScience' => _p(
            'A confident answer citing a study with a real-looking title, '
                'authors and DOI — none of which exist.',
            "Впевнена відповідь із посиланням на дослідження, у якого "
                "переконлива назва, автори й DOI — і жодного з них не існує.",
            'A study that sounds real and is not.',
            "Дослідження, яке звучить справжнім, але його немає.",
          ),
        'powerAndMoney' => _p(
            '"Officials have confirmed", with no name and no department. '
                'Real figures arranged into a story they do not support.',
            "«Посадовці підтвердили» — без імені й без відомства. Справжні "
                "цифри, складені в історію, якої вони не підтверджують.",
            '"Officials say" with nobody named.',
            "«Посадовці кажуть» — і жодного імені.",
          ),
        'syntheticAndRecycled' => _p(
            'An image that is almost certainly generated, about an event '
                'that really happened. A real clip with a new caption.',
            "Зображення, майже напевно згенероване, про подію, яка справді "
                "сталася. Справжній кадр із новим підписом.",
            'A generated picture of something real.',
            "Згенероване зображення чогось справжнього.",
          ),
        _ => '',
      };

  String arenaProgress(int done, int total) => _s(
        '$done of $total done',
        'Пройдено $done з $total',
      );
  String arenaDue(int n) => _s('$n to revisit', 'повторити: $n');
  String get arenaEmpty => _p(
        'No missions here in this mode. Try another subject, or switch to '
            'the adult mode in settings.',
        "У цьому режимі тут немає місій. Обери іншу тему або перемкни "
            "дорослий режим у налаштуваннях.",
        'Nothing here right now. Try another subject.',
        "Тут поки порожньо. Обери іншу тему.",
      );
  String get arenaChange => _s('Change subject', 'Змінити тему');
  String arenaNowIn(String title) => _s('In $title', 'Тема: $title');

  // ------------------------------------------------------------------ path
  String get yourPath => _s('Your path', 'Твій шлях');
  String get pathEmpty => _s('No missions available yet.', 'Поки що немає доступних місій.');
  String get pathError =>
      _s('Couldn\'t load your path. Check your connection.', 'Не вдалося завантажити шлях. Перевір з\'єднання.');
  String get stateLocked => _s('locked', 'закрито');
  String get stateAvailable => _s('available', 'доступно');
  String get stateCompleted => _s('completed', 'пройдено');
  String get boosterDue => _s('practice due', 'час повторити');
  String nodeUnlocked(String title) =>
      _s('$title is now open', 'Відкрито: $title');
  String get lockedReason =>
      _s('Finish the one before it', 'Заверши попередню');

  // Path header
  String statXp(int xp) => _s('$xp XP', '$xp XP');
  String get statXpLabel => _s('earned', 'зароблено');
  String statGoal(int done, int total) => _s('$done of $total', '$done з $total');
  String get statMissionsLabel => _s('missions done', 'місій пройдено');
  String statSkills(int count) => _s('$count', '$count');
  String get statSkillsLabel => _s('skills practised', 'навичок у роботі');

  // `statStreak` and `statGoalLabel` were removed rather than left
  // unused. They described a streak the app does not measure and a daily
  // goal it does not track; leaving them in place is an invitation for
  // someone to wire fabricated numbers back up to real-looking labels.
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

  /// The wire codes are English and fixed by the contract; the label is
  /// not. An unrecognised code returns itself rather than throwing — a
  /// new reaction added server-side should render oddly, never crash the
  /// screen a learner just finished a mission on.
  String reactionLabel(String code) => switch (code) {
        'trust' => reactionTrust,
        'suspicious' => reactionSuspicious,
        'investigate' => reactionInvestigate,
        _ => code,
      };
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

  /// Spoken when the mission moves to a new stage.
  ///
  /// The stages swap in place inside an AnimatedSwitcher, so a screen
  /// reader user is left parked on a widget that no longer exists and is
  /// never told the mission moved on.
  String stepArrived(String step) => _s('Step: $step', 'Крок: $step');
  String get stepPrediction => _s('First impression', 'Перше враження');
  String get stepInvestigating => _s('Investigate', 'Перевірка');
  String get stepConclusion => _s('Conclusion', 'Висновок');
  String get stepReceipt => _s('Evidence receipt', 'Квитанція доказів');
  String get howItConnects => _s('How it connects', "Як це пов'язано");
  String get theClaim => _s('The claim', 'Твердження');

  /// How a piece of evidence relates to the claim. Never colour-only —
  /// this text appears under every node and in its semantics.
  String relation(String kind) => switch (kind) {
        'supports' => _s('points the same way', 'вказує в той самий бік'),
        'contradicts' => _s('points against it', 'вказує проти'),
        _ => _s('relevant, but does not settle it', 'дотичне, але не вирішує'),
      };

  String sourceStanding(String kind) => switch (kind) {
        'verified' => _s('Verified against metadata', 'Підтверджено метаданими'),
        'curated' => _s('From a reviewed pack', 'З перевіреного паку'),
        'conflicting' => _s('Sources disagree', 'Джерела не збігаються'),
        _ => _s('Nothing could be confirmed', 'Нічого не вдалося підтвердити'),
      };

  String retrievedAt(String when) => _s('retrieved $when', 'отримано $when');
  String checkedOn(String when) => _s('checked $when', 'перевірено $when');

  /// A readable, localized date.
  ///
  /// Dates were being printed with `DateTime.toString()`, which put
  /// `2026-08-12 14:23:45.123456` in front of learners in both
  /// languages. Provenance is the subject this product teaches, so the
  /// dates it shows are not a detail — a date nobody can read is a date
  /// nobody checks.
  ///
  /// Written by hand rather than via `intl` to avoid pulling a
  /// localization dependency in for one function. In Ukrainian the month
  /// takes the genitive, because "12 серпень" is what a machine writes
  /// and "12 серпня" is what a person reads.
  String formatDate(DateTime when) {
    final local = when.toLocal();
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const uk = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    final month = (_uk ? uk : en)[local.month - 1];
    return _uk
        ? '${local.day} $month ${local.year}'
        : '${local.day} $month ${local.year}';
  }

  /// Date plus time, for a record whose exact moment matters.
  String formatDateTime(DateTime when) {
    final local = when.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return _s('${formatDate(when)} at $hh:$mm',
        '${formatDate(when)}, $hh:$mm');
  }
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
  // ------------------------------------------------------------ conflict
  String get conflictTitle =>
      _s('This mission moved on elsewhere', 'Місія просунулася деінде');
  String get conflictBody => _p(
        'It looks like this mission was continued in another tab or on '
            'another device, so what is on this screen is out of date. '
            'Nothing you already finished is lost — it is recorded against '
            'the other one.',
        "Схоже, цю місію продовжили в іншій вкладці або на іншому пристрої, "
            "тож те, що на цьому екрані, застаріло. Нічого із завершеного не "
            "втрачено — воно записане в тій іншій.",
        'This mission was continued somewhere else, so this screen is out '
            'of date.',
        "Цю місію продовжили деінде, тож цей екран застарів.",
      );
  String get conflictRestart => _s('Start this mission again', 'Почати місію знову');
  String get needMoreEvidenceBody => _p(
        'Check at least one more piece of evidence before concluding. The '
            'point is not the count — a conclusion drawn from nothing is the '
            'habit this trains against.',
        "Перевір ще хоча б один доказ, перш ніж робити висновок. Річ не в "
            "кількості — висновок, зроблений ні з чого, і є тією звичкою, "
            "проти якої це тренування.",
        'Check one more piece of evidence before you conclude.',
        "Перевір ще один доказ, перш ніж робити висновок.",
      );

  // --------------------------------------------------- confidence shift
  //
  // The wording here is the design. A learner who becomes less sure after
  // checking has not failed — they found out the question was harder than
  // it looked, which is the most useful thing this product can teach. So
  // no direction is praised over another and none of it is called a
  // score.
  String get confidenceBefore => _s('Before you looked', 'До перевірки');
  String get confidenceAfter => _s('After you looked', 'Після перевірки');

  String get shiftLessSureTitle =>
      _s('You became less sure', 'Ти стала менш впевненою');
  String get shiftLessSureBody => _p(
        'That is what checking is for. Finding out a question is harder '
            'than it looked is a result, not a mistake — and it is exactly '
            'the moment most people share something anyway.',
        "Саме для цього й перевіряють. Виявити, що питання складніше, ніж "
            "здавалося, — це результат, а не помилка. І саме в цей момент "
            "більшість усе одно поширює.",
        'Good. Checking showed the question was harder than it looked.',
        "Добре. Перевірка показала, що питання складніше, ніж здавалося.",
      );

  String get shiftMoreSureTitle =>
      _s('You became more sure', 'Ти стала впевненішою');
  String get shiftMoreSureBody => _p(
        'Your confidence now rests on something you checked rather than on '
            'a first impression. Worth noticing which evidence moved you, '
            'and whether it would have moved you the other way.',
        "Тепер твоя впевненість спирається на перевірене, а не на перше "
            "враження. Варто помітити, який саме доказ тебе зрушив — і чи "
            "зрушив би він тебе в інший бік.",
        'Now your confidence is based on something you checked.',
        "Тепер твоя впевненість спирається на перевірене.",
      );

  String get shiftUnchangedTitle =>
      _s('Your confidence held', 'Впевненість не змінилася');
  String get shiftUnchangedBody => _p(
        'Your first instinct survived the evidence. That is a different '
            'thing from never checking — you now know why you think so.',
        "Твоє перше відчуття витримало перевірку. Це не те саме, що не "
            "перевіряти взагалі, — тепер ти знаєш, чому саме так думаєш.",
        'Your first guess held up after checking.',
        "Твоя перша здогадка витримала перевірку.",
      );

  String get reactionToConclusion =>
      _s('First instinct, then conclusion', 'Перше відчуття, потім висновок');

  String shiftSpoken(int before, int after) => _s(
        'Confidence before you looked, $before percent. After, $after percent.',
        'Впевненість до перевірки — $before відсотків. Після — $after відсотків.',
      );

  // --------------------------------------------------------- uncertainty
  String get uncertaintyTitle => _s(
        '"Not enough evidence" is a conclusion.',
        "«Недостатньо доказів» — це висновок.",
      );
  String get uncertaintyBody => _p(
        'You looked, and what you found does not settle the question. Saying '
            'so is more accurate than picking a side to feel finished — and '
            'it is scored as a real answer here, not as a skip.',
        "Ти перевірила, і знайдене не дає відповіді. Сказати про це — "
            "точніше, ніж обрати бік, щоб просто завершити. Тут це "
            "зараховується як справжня відповідь, а не як пропуск.",
        'You checked, and it is still unclear. Saying so is the honest '
            'answer, and it counts.',
        "Ти перевірила, і досі незрозуміло. Сказати про це — чесна "
            "відповідь, і вона зараховується.",
      );
  String get uncertaintyPrompt =>
      _s('What would settle it?', 'Що б це вирішило?');

  /// Deliberately generic: these are the moves that work on any claim,
  /// which is what makes them worth learning rather than memorising.
  List<String> get uncertaintyOptions => _uk
      ? const [
          'Первинне джерело',
          'Незалежне друге повідомлення',
          'Оригінальний файл або знімок',
          'Датований запис',
          'Відповідь того, кого це стосується',
          'Хтось, хто був на місці',
        ]
      : const [
          'The primary source',
          'An independent second report',
          'The original file or photo',
          'A dated record',
          'A response from whoever it concerns',
          'Someone who was there',
        ];
  String get uncertaintyFootnote => _s(
        'If nothing here is available yet, "Keep investigating" is the share '
            'decision that matches this conclusion.',
        "Якщо нічого з цього поки немає, «Продовжити перевірку» — це "
            "рішення про поширення, яке відповідає такому висновку.",
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
  String get receiptHowYouGotThere =>
      _s('How you got there', 'Як ти до цього дійшла');
  String stepPredicted(String reaction) =>
      _s('First instinct: $reaction', 'Перше відчуття: $reaction');
  String stepChecked(int count) =>
      _s('Ran $count checks', 'Зробила перевірок: $count');
  String get stepAsked => _s('Asked the coach', 'Запитала коуча');
  String get stepConcluded =>
      _s('Concluded on three axes', 'Зробила висновок за трьома осями');
  String stepDecided(String choice) =>
      _s('Chose: $choice', 'Обрала: $choice');
  String get receiptEvidence => _s('Evidence you looked at', 'Докази, які ти переглянула');

  /// The receipt cites record identifiers, not titles.
  ///
  /// `Receipt.evidenceRefs` in the contract is a list of bare id strings
  /// and there is no endpoint that resolves one to a title, so these
  /// cannot be made readable from the client. Rather than print raw keys
  /// as though they were content, the list says what they are — which is
  /// also the truthful description: a receipt cites records so that
  /// someone else can look them up and check the work.
  String receiptEvidenceCount(int n) => _s(
        n == 1 ? '1 record cited' : '$n records cited',
        n == 1 ? 'Цитовано 1 запис' : 'Цитовано записів: $n',
      );
  String get receiptEvidenceExplain => _p(
        'These are the identifiers of what you opened. They are here so '
            'the receipt can be checked against the same records by someone '
            'who was not you.',
        "Це ідентифікатори того, що ти відкривала. Вони тут, щоб квитанцію "
            "міг звірити з тими самими записами хтось, хто не є тобою.",
        'These identify what you opened, so someone else can check it.',
        "Це ідентифікатори того, що ти відкривала, щоб інший міг звірити.",
      );
  String get receiptNoEvidence => _s(
        'No evidence was recorded for this attempt.',
        'Для цієї спроби докази не зафіксовані.',
      );
  String receiptCreated(String when) => _s('Created $when', 'Створено $when');

  /// A receipt's identifier is a storage key, not a name. The list used
  /// to show it raw, so a learner's own record read "demo-receipt-1".
  /// The mission title would be better, but `Receipt` in the contract
  /// carries no `missionId` and there is no `GET /attempts/{id}` to
  /// resolve one from `attemptId` — so a receipt cannot currently be
  /// traced back to what it is about. Numbering is the honest fallback
  /// until that gap is closed.
  String receiptNumbered(int n) => _s('Receipt $n', 'Квитанція $n');
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
  String get appearanceLabel => _s('Appearance', 'Вигляд');
  String get themeSystem => _s('Device', 'Як на пристрої');
  String get themeLight => _s('Light', 'Світла');
  String get themeDark => _s('Dark', 'Темна');
  String get themeHint => _s(
        'Only the colours change. Nothing about how you are scored depends on this.',
        "Змінюються лише кольори. Оцінювання від цього не залежить.",
      );
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
  /// Says what happened, and promises nothing beyond it.
  ///
  /// This read "a human reviewer will look at this", which was a promise
  /// the product cannot keep: there is no named moderation owner, no
  /// queue and no review destination (#33). A product that teaches
  /// people to check a claim before believing it cannot make an unbacked
  /// one on its own confirmation screen.
  ///
  /// It must not swing the other way either and imply the report is
  /// pointless. Confirming receipt, naming what it was attached to, and
  /// declining to promise a timeline does all three at once.
  String get reportSent => _s(
        'Received. This is recorded against the version of the mission you '
            'were looking at. We can\'t promise when someone will read it.',
        "Отримано. Записано разом із тією версією місії, яку ти дивилася. "
            "Не можемо обіцяти, коли це хтось прочитає.",
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

  /// Offline needs its own line: "try again" is bad advice when the
  /// thing to do is wait, and it invites someone to hammer a button
  /// that cannot work yet. What they typed is still in the box.
  String get reportFailedOffline => _s(
        'No connection, so this hasn\'t been sent. What you wrote is still '
            'here — try again once you\'re back online.',
        "Немає зв'язку, тож це не надіслано. Написане лишилося тут — "
            "спробуй, коли з'явиться мережа.",
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
  String get demoBadgeShort => _s('Demo', 'Демо');
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
