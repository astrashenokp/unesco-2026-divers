# Product seed — UNESCO MIL Hackathon (raw source)

# Додаток-гра (flutter та веб-версія)

- Формат схожий на дуолінго: навчання розрізняти ШІ контент та дизінфу в медіа
- Вибір категорії(соц мережі, новини, згенеровані фото та відео)
- Підключений  LLM API , який буде допомагати аналізувати ші контент, джерела в інтернеті(корисно для студентів для перевірки статей і тд)
- ДЯКУЮ

## Категорії

- **Social Media** — фейки, маніпуляції, реклама, viral posts.*Приклад:* підозрілий Instagram-пост.
- **News & Articles** — заголовки, джерела, факти, контекст.*Приклад:* знайти першоджерело новини.
- **AI Images & Videos** — generated images, deepfakes.*Приклад:* визначити ознаки AI-зображення.
- **AI & Chatbots** — hallucinations та вигадані джерела.*Приклад:* перевірити, чи існує стаття, яку назвав AI.

## LLM Assistant

AI **не просто каже “true/false”**, а допомагає користувачу перевіряти інформацію.

*Наприклад:*

“Хто автор?” → “Яке першоджерело?” → “Чи є підтвердження в інших джерелах?”

## Source Checker

Інструмент для оцінки статей та джерел, особливо корисний студентам.

Перевіряє:

- автора;
- тип джерела;
- дату;
- посилання на дослідження;
- маніпулятивну лексику.

*Приклад:* “Це блог, а не наукова стаття — перевір оригінальне дослідження.”

## Gameplay

Користувач отримує контент і обирає:

**Trust / Suspicious / Investigate**

За правильну перевірку джерел отримує XP.

*Приклад:* перевірити автора → знайти оригінальну статтю → зробити висновок.

## Гейміфікація

- XP
- streak
- levels
- achievements
- daily challenges

*Приклад achievement:* **Source Hunter — перевірити 10 першоджерел.**

Flutter App                                  
│
├── Home
├── Learning Path
│   ├── Social Media
│   ├── News
│   └── AI Content
│
├── Lesson
│   ├── Question
│   ├── Image/video
│   ├── Answer
│   └── Explanation
│
├── Verify
│   └── LLM Assistant
│
└── Profile
├── XP
├── Streak
└── Achievements

```
       Flutter
   Mobile + Web
         │
         │ HTTP
         ▼
       Backend
   (Node / FastAPI)
    /     |      \
   ▼      ▼       ▼
```

Database  LLM    Other APIs

UNESCO_MIL_Hackathon_2026_Research_Dossier.md

> **В цьому документі зібрана для нас повна база інфи по усім проектам-переможцям UNESCO Youth Hackathon за минулі роки**
Тут розписані: їхні головні ідеї, склад команд, унікальні фішки, гейміфікація та офіційні лінки ⬇️
> 

UNESCO.pdf

https://docs.google.com/document/d/1Gw_Ur8c2xGF-0T8HksFtcOhvgxKDKJAhS3CQJyesDZg/edit?usp=sharing

> У цьому документі зібрано наукове та технічне обґрунтування того, чому наша концепція верифікаційного тренажера є перспективною. Тут розписані: детальна архітектура, стек технологій (Flutter, Python, Java) та ігрові механіки успішних аналогів: серйозної гри **«Deepfaked»** та додатка **«Fake News Detection»**, а також Кембридзькі дослідження про **теорію психологічного щеплення (Inoculation Theory)** та методи боротьби зі згасанням навичок за допомогою щоденних тренувань.
> 

Приклади наукових робіт на тематику нашої ідеї.pdf

https://docs.google.com/document/d/1ImfB97f4MjDArQEdMdxsP0_K8EA4G1yVueDG2_3UMbE/edit?usp=sharing
