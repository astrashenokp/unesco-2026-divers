# Evidence Gym — learner app (Flutter)

Role 1 (Frontend & Experience) owned. Design rationale: `docs/06-design/DESIGN_SYSTEM.md` and `docs/06-design/MASCOT_AND_VISUAL_LANGUAGE.md`. Contract: `contracts/openapi.yaml` / `docs/03-contracts/API_CONTRACT.md`.

## Status

Verified on **Flutter 3.44.9 / Dart 3.12.2**:

- `flutter analyze` — no issues, in both `apps/learner` and `packages/design_system`
- `flutter test` — 6/6 passing
- `flutter build web --release` — succeeds

Not yet checked by hand: real-device behaviour, 200% text on a physical screen, and a screen-reader pass. Those are in the checklist at the end of [`SCREEN_REFERENCE.md`](../../docs/06-design/SCREEN_REFERENCE.md).

## Run it

1. Install Flutter (stable, **3.29 or newer**): https://docs.flutter.dev/get-started/install
2. `flutter pub get`
3. Run it:
   - Laptop/web: `flutter run -d chrome` — the `web/` folder is committed, so this works immediately
   - Phone or emulator: `flutter run`, after adding that platform once with
     `flutter create --platforms=android,ios .`
4. On the auth screen choose one:
   - **Enter demo** with the key below — fully offline, nothing else needed. This is the path to demo to judges.
     ```
     EVIDENCE-GYM-DEMO
     ```
   - **Continue as guest** — talks to a live API at `http://localhost:8000/` (override with `flutter run --dart-define=API_BASE_URL=https://your-api/`). Guest auth is **not** wired to Firebase yet; see the TODO in `lib/features/auth/auth_screen.dart`.
5. `flutter test` — six widget/invariant tests in `test/smoke_test.dart`.

### Talking to a local API from the web build

A Flutter web app served on one port calling an API on another is a
cross-origin request, and the browser will block it unless the server
sends CORS headers. For local development, use the built-in flag:

```
flutter run -d chrome --web-browser-flag=--disable-web-security   --dart-define=API_BASE_URL=http://localhost:8000/
```

This is scoped to that one run. Do **not** install a tool that patches
the Flutter SDK to do the same thing — it persists across projects and
breaks on upgrade. And neither approach substitutes for the server
sending correct CORS headers anywhere that is not a laptop.

> `pumpAndSettle` will hang in any test that renders a mascot: Lupa and Slid animate continuously, so there is never a frame-idle to settle on. Pump a bounded number of frames instead — see `_settle` in the test file.

### Seeing both layouts

The layout switches at 600dp. On `-d chrome`, resize the window: narrow gives the phone layout (bottom navigation bar, single column); wide gives the laptop layout (side navigation rail, and the mission screen splits into claim | working-step panes).

### Checking accessibility quickly

Settings tab → text size to 200%, "Simpler wording" on, "Reduce animation" on. Nothing should clip, scroll sideways, or lose meaning.

## What's implemented

- **Onboarding carousel** (3 slides, never auto-advances) → **auth / demo-key** → **shell**.
- **Shell** with three destinations: Path, Progress, Settings. `NavigationBar` on phones, `NavigationRail` on laptops, same order and labels in both.
- **Path** — the winding skill map, each node revealing with a spring as it scrolls in.
- **Mission** — the full flow: predict → investigate (tactile evidence props + opt-in Socratic coach) → three-axis conclusion → receipt.
- **Evidence receipt** — the full document: three-axis conclusion, evidence actually looked at, pinned mission version, integrity marker, disclaimer.
- **Report** — wired to `POST /v1/reports`; a failed send is never confirmed as sent, and demo mode says plainly that nothing left the device.
- **Progress** — segmented skill meters and process XP, with XP explicitly framed as "how you investigate", not a measure of the person.
- **Settings** — language (укр/eng), simpler wording, reduce animation, text size.
- **Report dialog** on every mission.
- **Mascots** — `Lupa` (the coach; idle / thinking / asking / encouraging) and `Slid` (the provenance trail). Both hand-drawn with `CustomPainter`, so there is no art asset to go missing.
- **Ukrainian and English** throughout, Ukrainian by default.

## Known gaps (flagged, not hidden)

- **Settings don't persist** across restarts — needs `shared_preferences`.
- **Guest auth isn't real** — `_placeholderGuestTokenProvider` returns null. Needs `flutterfire configure` + `signInAnonymously()` (ADR-008). The demo key is the working path until then.
- **No `.arb` codegen** — `lib/l10n/strings.dart` is hand-written with the same shape a generated class would have. Swapping it later touches no call sites.
- **No offline/degraded banner** yet, no offline pack download, no booster/spaced-repetition UI, no teacher views (the last three are P1/P2 anyway).
- **Difficulty levels**: the contract has no difficulty field, so per-mission levels would need Role 2/3 to add one. What's here instead is the reading-level work — "Simpler wording" — which is genuinely Role 1's boundary.
- **Nothing has been run.** See Status above.

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
