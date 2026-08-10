# Project execution playbook: від ідеї до масштабної платформи

Це головний операційний маршрут реалізації Evidence Gym. Він пояснює не лише що будувати, а в якій послідовності, хто відповідає, які артефакти мають з'явитися та за якими доказами команда переходить до наступної фази.

## Правило проходження фаз

Фаза закінчується не датою і не словами «майже готово», а exit criteria. Незавершена критична вимога переносить фазу; P1/P2-функція не може компенсувати несправний P0 vertical slice.

## Фаза 0 — Alignment і freeze проблеми

### Результат

Четверо учасників однаково формулюють користувача, проблему, рішення, головну відмінність і демонстраційний сценарій.

### Роботи

1. Прочитати raw-джерела через синтез, а не напряму перетворювати кожну ідею у feature.
2. Затвердити назву Evidence Gym як working name.
3. Зафіксувати primary audience 16–24 та secondary distribution через викладачів/NGO.
4. Затвердити core loop і три незалежні осі.
5. Затвердити дві demo-місії та явні non-goals.
6. Перевірити правила UNESCO на офіційному сайті.
7. Призначити чотири ролі, GitHub handles і backup owner кожного критичного напряму.

### Exit criteria

- концепт можна пояснити одним реченням;
- усі четверо відтворюють однаковий core loop;
- P0/P1/P2 підписані командою;
- CODEOWNERS більше не містить placeholder usernames;
- ризики deadline, demo, AI та content ownership мають owner.

## Фаза 1 — Discovery і доказова дисципліна

### Результат

Команда знає, які твердження є фактами, гіпотезами, цілями та маркетинговими перебільшеннями.

### Роботи

- створити claim register;
- верифікувати правила, попередніх переможців, C2PA/AI Act, learning-science claims;
- провести 5–8 problem interviews зі студентами;
- окремо поговорити з 2–3 викладачами/фасилітаторами;
- протестувати розуміння трьох осей без готового UI;
- перевірити правовий статус двох demo media assets;
- визначити consent і pilot data policy.

### Exit criteria

- жоден central pitch claim не спирається лише на AI-generated notes;
- для двох demo-кейсів існують source packets;
- сформульовано три найбільші user pains і три заперечення;
- продуктова гіпотеза має вимірюваний outcome.

## Фаза 2 — Contract-first design

### Результат

Frontend, backend, AI/content і QA можуть працювати паралельно без вигадування несумісних полів.

### Роботи

1. Затвердити OpenAPI subset і error model.
2. Затвердити attempt state machine та idempotency semantics.
3. Затвердити scenario-pack schema і дві fixtures.
4. Затвердити event envelope та privacy-safe analytics payloads.
5. Створити Flutter/API mock boundary.
6. Створити DB migration baseline та transaction diagram.
7. Створити prompt structured output і deterministic fallback fixtures.

### Exit criteria

- контракти проходять parser/schema checks;
- frontend відтворює golden flow на mock data;
- backend contract test повертає ті самі fixtures;
- AI output не містить довільних evidence IDs;
- producer і consumer підписали contract PR.

## Фаза 3 — Design exploration і accessibility foundation

### Результат

Затверджена одна візуальна система і всі ключові стани P0 до масштабної UI-реалізації.

### Роботи

- створити три напрямки у Google Stitch без PII/секретів;
- вибрати напрям за clarity/trust/accessibility, а не wow-ефектом;
- зафіксувати semantic tokens і component inventory;
- згенерувати/намалювати mobile-first golden screens;
- перевірити Ukrainian expansion, 200% text, keyboard/focus, grayscale/status;
- перекласти токени у Flutter ThemeExtension;
- затвердити loading/error/offline/provider unavailable states.

### Exit criteria

- дизайн не використовує binary red/green truth cue;
- усі P0 екрани мають accessibility annotations;
- Role 1 Frontend має reusable component map;
- QA bot отримує тільки read-only approved Stitch IDs.

## Фаза 4 — Skeleton і developer platform

### Результат

Одна команда піднімає локальне середовище, запускає тести та бачить trace одного mock request.

### Роботи

- Flutter workspace/features/design system;
- FastAPI modules/config/health endpoints;
- PostgreSQL migration/test container;
- Firebase dev auth або emulator strategy;
- Cloud Run dev/staging skeleton через IaC;
- CI lint/type/unit/contract/security baseline;
- OpenTelemetry trace IDs;
- secrets через `.env.example` локально та Secret Manager у cloud.

### Exit criteria

- onboarding нового учасника займає менше двох годин;
- `main` зелений;
- немає secret/service-account key у repo;
- staging deploy reproducible;
- rollback попереднього image digest перевірений.

## Фаза 5 — Перший vertical slice

### Результат

Користувач проходить одну місію від brief до Evidence Receipt із реальним server transaction.

### Порядок реалізації

1. Отримати exact mission version.
2. Створити attempt з idempotency key.
3. Записати initial reaction/confidence.
4. Виконати curated evidence action.
5. Отримати deterministic hint.
6. Подати three-axis conclusion/share decision.
7. Однією транзакцією записати conclusion, XP ledger, progress, receipt та outbox.
8. Відобразити receipt і next activity.

### Exit criteria

- happy path працює web + Android target;
- повторення mutation не дублює XP;
- offline demo завершується без зовнішніх API;
- trace пов'язує client/API/DB/outbox;
- critical E2E стабільно проходить 10 разів.

## Фаза 6 — Другий кейс і AI boundary

### Результат

Citation Hunt доводить відмінність продукту, а Socratic AI не стає single point of failure.

### Роботи

- реалізувати citation metadata adapter з fixtures/cache/circuit breaker;
- розділити exact match, mismatch, not found, provider unavailable і support unknown;
- додати bounded LLM hint із evidence allowlist;
- додати injection/leakage/hallucinated citation evals;
- додати deterministic fallback;
- виміряти latency і cost per completed mission.

### Exit criteria

- `not found != fabricated` у contract, UI і tests;
- AI не розкриває gold до conclusion;
- malformed/provider timeout не блокує урок;
- release eval suite не має critical policy failure.

## Фаза 7 — Hardening

### Результат

Vertical slice витримує типові помилки, атаки, accessibility та demo failures.

### Роботи

- authz negative tests і token edge cases;
- rate/concurrency/cost limits;
- idempotency/race/property tests;
- DB backup/restore і bad migration rehearsal;
- WAF/direct URL configuration;
- prompt injection through every untrusted field;
- screen reader/keyboard/text scale/reduced motion;
- offline/provider/LLM/DB degraded behavior;
- localization and content/license review;
- secret/log/PII audit.

### Exit criteria

- немає blocking security/a11y/AI safety issue;
- release rollback і offline fallback перевірені;
- core flow має observability dashboard;
- incident owner знає kill switches.

## Фаза 8 — Usability pilot

### Результат

Команда має чесні usability/feasibility signals, не перебільшене наукове доведення.

### Роботи

- 8–20 учасників із consent;
- unseen pre-case, product session, parallel post-case;
- вимір process actions/confidence/completion/confusion;
- accessibility observation;
- інтерв'ю “що ви тепер робитимете інакше?”;
- пріоритизація findings за demo/learning/safety.

### Exit criteria

- P0 confusion усунута або задокументовано fallback;
- pitch формулює pilot саме як pilot;
- raw notes/recordings мають TTL та access owner;
- одна цифра не використовується без denominator/context.

## Фаза 9 — Submission production

### Результат

Подано чесний, зрозумілий, доступний пакет раніше дедлайну.

### Роботи

- англомовний proposal за критеріями UNESCO;
- відео ≤3 хвилин з англійськими субтитрами;
- rehearsal на 2:45;
- clean-device test і backup recording;
- перевірка розміру, ліцензій, claims, spelling, посилань;
- двоє учасників перевіряють upload/confirmation/checksum.

### Exit criteria

- submission confirmation збережено у двох місцях;
- demo працює live й offline;
- judges can repeat one-sentence concept after viewing;
- roadmap чітко відділений від implemented MVP.

## Фаза 10 — Post-hackathon stabilization

### Результат

Prototype перетворюється на керований pilot product, а не залишається demo branch.

### Роботи

- закрити security/privacy shortcuts або видалити функції;
- data export/deletion/retention workflows;
- 12–20 reviewed missions;
- content review tool/pack publisher;
- SLO/error budgets/on-call ownership;
- external security/accessibility review;
- partner discovery без удаваних partnerships;
- terms/privacy/subprocessor register.

### Exit criteria

- production-readiness review пройдений;
- жоден demo secret/fixture не змішаний із real data;
- restore, incident і deletion drills виконані;
- підтримка має owner і response targets.

## Фаза 11 — Education pilot

### Результат

Одна–три групи використовують reviewed pack протягом 2–4 тижнів із privacy-safe measurement.

### Роботи

- facilitator onboarding/guide/printable fallback;
- assignment code та aggregate skill view;
- small-cohort suppression;
- D7/D30 retention/transfer;
- teacher feedback і classroom-device constraints;
- content correction/appeal process.

### Exit criteria

- learning outcome і guardrails виміряні;
- educator не бачить private prompt/history;
- content/moderation workload оцінений;
- рішення “continue/pivot/stop” записано.

## Фаза 12 — Production launch

### Результат

Контрольований публічний реліз із capacity, support, legal, security та rollback.

### Launch gates

- threat model і DPIA актуальні;
- SLO/capacity/load/cost caps;
- production IAM/MFA/backup/restore/monitoring;
- privacy notice, consent, deletion/export;
- license inventory і content governance;
- staged rollout/kill switches/incident rotation;
- no critical/high exploitable findings;
- AI/provider settings і subprocessor review.

## Фаза 13 — Platform scale

### Результат

Масштабування базується на виміряному навантаженні, контентному попиті та окремих ownership/security boundaries.

### Можливі еволюції

- partner authoring/review CMS;
- multi-tenant education workspaces;
- regional packs/data residency;
- analytics warehouse із privacy controls;
- content-authoring та verification-worker extraction;
- LMS/SSO/public API;
- moderated ambassador submissions;
- research integrations.

### Заборона передчасного масштабу

Не додавати Kubernetes, sharding, event-sourcing, десятки microservices, global multi-region writes або UGC marketplace без виміряного trigger, owner, threat review, cost і rollback.

## Критичний шлях залежностей

`Concept freeze → contracts → fixtures → Flutter/API skeleton → first vertical slice → second mission/AI eval → hardening → pilot → submission → stabilization → education pilot → launch → scale`

Паралельно можуть іти дизайн, proposal research і content production, але вони не можуть змінювати core contract без узгодженого contract PR.

## Щотижневий операційний огляд

1. Чи працює golden path?
2. Який learner outcome покращився?
3. Який contract/risk змінився?
4. Який blocker має DRI і deadline?
5. Що видаляємо зі scope?
6. Який security/privacy/a11y/AI gate може зупинити release?
7. Чи готовий rollback/fallback?
8. Чи всі claims залишаються чесними?
