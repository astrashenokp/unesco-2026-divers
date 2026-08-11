# Evidence Gym — learner app (Flutter)

Role 1 (Frontend & Experience) owned. Design rationale: `docs/06-design/DESIGN_SYSTEM.md` and `docs/06-design/MASCOT_AND_VISUAL_LANGUAGE.md`. Contract: `contracts/openapi.yaml` / `docs/03-contracts/API_CONTRACT.md`.

## Status

**Not yet verified locally** — this has not been through `flutter analyze` or `flutter test` on a machine with the SDK installed. It is written against `contracts/openapi.yaml` and reviewed by hand, but hand review is not a compiler. Treat the first `flutter analyze` as the real check and fix whatever it reports.

## Run it

1. Install Flutter (stable, **3.29 or newer** — the code uses `Color.withValues()` and `CardThemeData`, which are not in 3.24): https://docs.flutter.dev/get-started/install
2. From `apps/learner/`, generate the platform folders that don't exist yet. This is additive — it will not touch `lib/` or `pubspec.yaml`:
   ```
   flutter create --org com.evidencegym --project-name evidence_gym_learner .
   ```
3. `flutter pub get`
4. `flutter analyze`
5. Run it:
   - Laptop/web: `flutter run -d chrome`
   - Phone or emulator: `flutter run`
6. On the auth screen choose one:
   - **Enter demo** with the key below — fully offline, nothing else needed. This is the path to demo to judges.
     ```
     EVIDENCE-GYM-DEMO
     ```
   - **Continue as guest** — talks to a live API at `http://localhost:8000/` (override with `flutter run --dart-define=API_BASE_URL=https://your-api/`). Guest auth is **not** wired to Firebase yet; see the TODO in `lib/features/auth/auth_screen.dart`.
7. `flutter test` — six widget/invariant tests in `test/smoke_test.dart`.

### Seeing both layouts

The layout switches at 600dp. On `-d chrome`, resize the window: narrow gives the phone layout (bottom navigation bar, single column); wide gives the laptop layout (side navigation rail, and the mission screen splits into claim | working-step panes).

### Checking accessibility quickly

Settings tab → text size to 200%, "Simpler wording" on, "Reduce animation" on. Nothing should clip, scroll sideways, or lose meaning.

## What's implemented

- **Onboarding carousel** (3 slides, never auto-advances) → **auth / demo-key** → **shell**.
- **Shell** with three destinations: Path, Progress, Settings. `NavigationBar` on phones, `NavigationRail` on laptops, same order and labels in both.
- **Path** — the winding skill map, each node revealing with a spring as it scrolls in.
- **Mission** — the full flow: predict → investigate (evidence actions + opt-in Socratic coach) → three-axis conclusion → receipt.
- **Progress** — segmented skill meters and process XP, with XP explicitly framed as "how you investigate", not a measure of the person.
- **Settings** — language (укр/eng), simpler wording, reduce animation, text size.
- **Report dialog** on every mission.
- **Mascots** — `Lupa` (the coach; idle / thinking / asking / encouraging) and `Slid` (the provenance trail). Both hand-drawn with `CustomPainter`, so there is no art asset to go missing.
- **Ukrainian and English** throughout, Ukrainian by default.

## Known gaps (flagged, not hidden)

- **Settings don't persist** across restarts — needs `shared_preferences`, deliberately not added because it couldn't be compiled here.
- **Guest auth isn't real** — `_placeholderGuestTokenProvider` returns null. Needs `flutterfire configure` + `signInAnonymously()` (ADR-008).
- **Report doesn't reach the server** — the dialog is complete but `onSubmit` is an empty TODO; `POST /v1/reports` isn't in the client yet. It does not fake success.
- **No `.arb` codegen** — `lib/l10n/strings.dart` is hand-written with the same shape a generated class would have, because `flutter gen-l10n` couldn't be run here. Swapping it later touches no call sites.
- **Receipt is minimal** — shows XP and receipt id; doesn't yet fetch `GET /receipts/{id}` for the full evidence timeline.
- **No offline pack download**, no booster/spaced-repetition UI, no teacher views (all P1/P2 anyway).
- **Difficulty levels**: the contract has no difficulty field, so per-mission levels would need Role 2/3 to add one. What's here instead is the reading-level work — "Simpler wording" — which is genuinely Role 1's boundary.

## Layout

```
apps/learner/lib/
  main.dart, app.dart        entry, MaterialApp, theme/locale/text-scale wiring
  app_settings.dart          AppSettings + AppSettingsScope
  l10n/
    strings.dart             uk/en strings, incl. simple-language variants
    axis_localization.dart   joins stable API codes to localized labels
  data/
    models.dart              typed mirror of contracts/openapi.yaml
    api_client.dart          the only place that touches the network
    mission_repository.dart  Demo vs Live; screens depend only on this
    demo_fixtures.dart       offline pack, demo key, deterministic coach
  features/
    onboarding/ auth/ shell/ home/ mission/ profile/ settings/ report/

packages/design_system/lib/src/
  tokens.dart theme.dart breakpoints.dart
  mascot/lupa.dart mascot/slid.dart
  components/  axis picker+chip, confidence slider, evidence chip,
               path node, mission card, coach bubble, skill meter,
               reveal-on-scroll, pressable
```

## Rules this code follows

From `ROLE_1_FRONTEND_EXPERIENCE.md` and the design docs — worth knowing before editing:

- Widgets never call endpoints. They depend on `MissionRepository`; only `api_client.dart` knows about HTTP.
- No raw colours in features. Use `context.tokens`.
- No green/red status colours anywhere — a binary-verdict palette would undermine the product's whole argument. `danger` red is reserved for safety/report flows only.
- Every status is icon + shape + text, never colour alone.
- Animation is decoration. Every animated thing has a reduced-motion path that lands in the same end state.
- Stable API codes and localized display text are separate. `AxisOption.code` goes to the server, `AxisOption.label` goes on screen.
