# Evidence Gym — learner app (Flutter)

Role 1 (Frontend & Experience) owned. Design rationale: `docs/06-design/DESIGN_SYSTEM.md` and `docs/06-design/MASCOT_AND_VISUAL_LANGUAGE.md`. Contract: `contracts/openapi.yaml` / `docs/03-contracts/API_CONTRACT.md`.

## Status

Verified on **Flutter 3.44.9 / Dart 3.12.2**:

- `dart analyze` — no issues in `apps/learner` and `packages/design_system`
- `flutter test` — 55 passing in `apps/learner`, 42 passing in `design_system`
- `flutter build web --release` — succeeds

Local note: `flutter analyze` can hit an internal analysis-server
`FormatException` from this Unicode workspace path before it reports code
diagnostics. `dart analyze` is the local analyzer check for this workspace; CI
or a plain ASCII checkout may still run `flutter analyze`.

Those tests include a WCAG contrast audit over every token pair that renders together, text-scale checks at 100% and 200% in both languages on phone and laptop widths, and semantics tests that activate controls the way assistive technology does rather than by tapping pixels.

Still unchecked by hand: real-device behaviour and a pass with a live screen reader (TalkBack/VoiceOver). Those are the unticked rows at the end of [`SCREEN_REFERENCE.md`](../../docs/06-design/SCREEN_REFERENCE.md).

## Run it

1. Install Flutter (stable, **3.29 or newer**): https://docs.flutter.dev/get-started/install
2. `flutter pub get`
3. Run it:
   - Laptop/web: `flutter run -d chrome` — the `web/` folder is committed, so this works immediately
   - Phone or emulator: `flutter run`, after adding that platform once with
     `flutter create --platforms=android,ios .`
4. On the auth screen choose one:
   - **Enter demo** with the key below — fully offline, nothing else needed.
     This path now mirrors the two checked-in Role 3 P0 missions from
     `content/p0-demo-pack`.
     ```
     EVIDENCE-GYM-DEMO
     ```
   - **Continue as guest** — talks to a live API at `http://localhost:8000/` (override with `flutter run --dart-define=API_BASE_URL=https://your-api/`). Guest auth is **not** wired to Firebase yet; see the TODO in `lib/features/auth/auth_screen.dart`.
5. `flutter test` — smoke, accessibility and mission-flow suites.

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
- **Shell** with four destinations: Path, Progress, You, Settings. `NavigationBar` on phones, `NavigationRail` on laptops, same order and labels in both.
- **Path** — the winding skill map, each node revealing with a spring as it scrolls in.
- **Mission** — the full flow: predict → investigate (tactile evidence props + opt-in Socratic coach) → three-axis conclusion → receipt.
- **Evidence receipt** — the full document: three-axis conclusion, evidence actually looked at, pinned mission version, integrity marker, disclaimer.
- **Report** — wired to `POST /v1/reports`; a failed send is never confirmed as sent, and demo mode says plainly that nothing left the device.
- **Progress** — segmented skill meters and process XP, with XP explicitly framed as "how you investigate", not a measure of the person.
- **Profile** — guest identity explained, receipt history, and a data export that copies everything held as readable text.
- **Skill detail** — what each evidence skill is, why it matters, which missions train it.
- **Settings** — language (укр/eng), simpler wording, reduce animation, text size. All persisted.
- **Report dialog** on every mission.
- **Mascots** — `Lupa` (idle / thinking / asking / encouraging / concerned, tappable, with a particle celebration) and `Slid` (the provenance trail, tracking real progress). Both hand-drawn with `CustomPainter`, so there is no art asset to go missing.
- **Ukrainian and English** throughout, Ukrainian by default.

## Known gaps (flagged, not hidden)

- **Guest auth isn't real** — `_placeholderGuestTokenProvider` returns null. Needs `flutterfire configure` + `signInAnonymously()` (ADR-008). The demo key is the working path until then.
- **No `.arb` codegen** — `lib/l10n/strings.dart` is hand-written with the same shape a generated class would have. Swapping it later touches no call sites.
- **No offline pack download**, no booster/spaced-repetition UI, no teacher views (all P1/P2).
- **No receipt list endpoint** in the contract, so live receipt history returns empty rather than inventing one. Role 2 would need `GET /v1/receipts`.
- **`Attempt.version` cannot be refreshed** — the contract has no `GET /attempts/{id}` and evidence responses carry no version, so if the server bumps it on `predicted → investigating` the conclusion would 409 with no recovery. Needs a decision from Role 2.
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
    onboarding/ auth/ shell/ home/ mission/ receipt/ profile/ settings/
    report/ common/

packages/design_system/lib/src/
  tokens.dart theme.dart breakpoints.dart
  mascot/lupa.dart mascot/slid.dart
  motion.dart                one place for every duration and curve
  components/  axis picker+chip, confidence slider, evidence chip,
               prop tile, path node, path trail, mission card,
               coach bubble, skill meter, rolling number,
               living background, reveal-on-scroll, pressable
```

## Rules this code follows

From `ROLE_1_FRONTEND_EXPERIENCE.md` and the design docs — worth knowing before editing:

- Widgets never call endpoints. They depend on `MissionRepository`; only `api_client.dart` knows about HTTP.
- No raw colours in features. Use `context.tokens`.
- No green/red status colours anywhere — a binary-verdict palette would undermine the product's whole argument. `danger` red is reserved for safety/report flows only.
- Every status is icon + shape + text, never colour alone.
- Animation is decoration. Every animated thing has a reduced-motion path that lands in the same end state.
- Stable API codes and localized display text are separate. `AxisOption.code` goes to the server, `AxisOption.label` goes on screen.
- A control that declares a role must carry the action on the same `Semantics` node. `Semantics(button: true, child: ExcludeSemantics(InkWell))` announces a button that does nothing — this shipped three times before tests caught it.
- Interactive widgets must be focusable. A `GestureDetector` is not, so it is unreachable by keyboard.
- Idempotency keys belong to a logical action, not to a call. Minting one per request defeats the mechanism entirely.
