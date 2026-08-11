# Screen reference

Every screen, every state, every control, on both form factors, with the accessibility behaviour each one owes the learner.

This is the implementation-level companion to [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) (tokens and principles) and [`MASCOT_AND_VISUAL_LANGUAGE.md`](MASCOT_AND_VISUAL_LANGUAGE.md) (mascots, colour rationale, motion). Where this document and those disagree, they win on principle and this one is wrong and should be corrected. [`SCREEN_INVENTORY.md`](SCREEN_INVENTORY.md) remains the shorter P0 list; this is the expanded form of it.

Status is marked per screen: **built** (in `apps/learner`), **partial**, or **not built**.

---

## 1. Global rules

These hold everywhere. A screen that breaks one of them is a defect, not a variation.

### Layout

| Window width | Form factor | Navigation | Mission layout |
|---|---|---|---|
| `< 600dp` | phone | bottom `NavigationBar` | one column |
| `600–1023dp` | tablet | side `NavigationRail`, labels shown | two panes |
| `≥ 1024dp` | desktop | side `NavigationRail`, labels shown | two panes |

Breakpoints follow Material's window size classes, so the behaviour matches what people already expect from other apps on the same device. Destination order, labels and icons are **identical** across form factors — switching between phone and laptop must never require relearning anything.

Reading measure is capped (`ReadableWidth`, 520–640dp depending on screen). Long lines are a readability problem for exactly the uncertain readers this product serves.

### Controls

- Minimum touch target **44×44dp**, everywhere, including chips. Path nodes are 72dp because aim is least steady there.
- Every button has a visible label. Icon-only is allowed **only** in the app bar, and only with a tooltip plus a semantic label.
- A disabled primary button must be accompanied by visible text saying what is missing. Disabled-with-no-explanation is a dead end.
- Destructive or outward-facing actions (report) are never the default-styled primary button on a screen.

### State

Every screen that loads data implements all five: **loading**, **empty**, **error + retry**, **success**, and **offline/degraded**. Loading uses a `Semantics` label so a screen reader announces it rather than sitting silent.

### Colour and status

- No green/red status colours. Ever. See `MASCOT_AND_VISUAL_LANGUAGE.md` for why — a binary-verdict palette contradicts the three-axis model.
- `danger` red appears **only** in reporting and safety flows.
- Every status is **icon + shape + text + colour**. Remove the colour and the meaning must survive.

### Motion

150–300ms. Every animation has a reduced-motion path that lands in the **same end state**, honouring both the OS setting and the in-app switch. No animation gates content, focus, or a hit target. No auto-advancing carousels. Nothing flashes faster than 3Hz.

### Language

Ukrainian and English, Ukrainian by default. "Simpler wording" shortens explanatory copy but **never** removes a safety or provenance caveat. Stable API codes and localized display text are separate values and must never be conflated.

---

## 2. Complete button inventory

Every interactive control in the app today. Use this to check nothing is missing.

| # | Screen | Control | Style | Enabled when | Action |
|---|---|---|---|---|---|
| 1 | Onboarding | Skip | text | always | → Auth |
| 2 | Onboarding | Next / Get started | filled | always | next slide, or → Auth on last |
| 3 | Auth | Continue as guest | filled | always | → Shell (live repository) |
| 4 | Auth | Demo access key | text field | always | accepts the key |
| 5 | Auth | Enter demo | outlined | always | validates key → Shell (demo repository) |
| 6 | Shell | Path / Progress / Settings | nav destinations | always | switch destination |
| 7 | Path | Mission node | circular tile | node not `locked` | → Mission |
| 8 | Path | Try again | filled | on error | refetch path |
| 9 | Mission | Report | app-bar icon + tooltip | always | opens Report dialog |
| 10 | Mission · predict | Trust / Suspicious / Investigate | choice chips | always | records instinct |
| 11 | Mission · predict | Confidence | slider, 5% steps | always | 0–100 |
| 12 | Mission · predict | Start investigating | filled | a reaction is chosen | submits prediction |
| 13 | Mission · investigate | Evidence props | tiles | not yet used | runs an evidence action |
| 14 | Mission · investigate | Ask the coach | outlined | always | requests a bounded hint |
| 15 | Mission · investigate | Draw a conclusion | filled | ≥1 evidence action, **or** mission sets `testsCriticalIgnoring` | → conclusion |
| 16 | Mission · conclude | Axis answers ×3 | choice chips | always | picks per-axis answer |
| 17 | Mission · conclude | Per-axis confidence ×3 | sliders | appears once that axis is answered | 0–100 |
| 18 | Mission · conclude | Overall confidence | slider | always | 0–100 |
| 19 | Mission · conclude | Share decision ×3 | choice chips | always | do not share / with context / keep investigating |
| 20 | Mission · conclude | Submit conclusion | filled | all three axes **and** a share decision chosen | completes the attempt |
| 21 | Mission · done | Open your evidence receipt | filled | a receipt id exists | → Receipt |
| 22 | Mission · done | Back to the path | outlined | always | pops to Path |
| 23 | Receipt | Try again | filled | on error | refetch receipt |
| 24 | Progress | Try again | filled | on error | refetch progress |
| 25 | Settings | Українська / English | segmented | always | switches locale |
| 26 | Settings | Simpler wording | switch | always | plainer copy |
| 27 | Settings | Reduce animation | switch | always | adds to the OS setting |
| 28 | Settings | Text size | slider, 100–200% | always | raises the text floor |
| 29 | Report | Reason ×6 | radios | always | selects a reason |
| 30 | Report | Detail | text field, ≤1000 | always | optional context |
| 31 | Report | Cancel | text | not sending | dismisses |
| 32 | Report | Send | filled | a reason is chosen | submits the report |

**Deliberately absent**, and each for a reason: no share-to-social button (sharing is a *decision the learner records*, not an outward action the MVP performs); no "show me the answer" button (the product's whole argument is that it does not hand over verdicts); no streak-freeze purchase; no leaderboard.

---

## 3. Screens

### 3.1 Onboarding carousel — **built**

Three slides, `PageView`, never auto-advancing.

1. *Investigate, don't guess.* — Lupa idle.
2. *The AI asks. It never decides for you.* — Lupa asking.
3. *Practice on real cases, safely.* — Lupa encouraging.

**Layout.** Single column both form factors, capped measure, centred. Each slide scrolls internally so 200% text never clips.

**States.** No data, so no loading/error state exists.

**Accessibility.** `PageView` announces position, so the dot indicator is `ExcludeSemantics` — it would otherwise duplicate. Skip is reachable first in focus order after the slide content. Mascot carries a descriptive label but no action.

---

### 3.2 Auth / demo entry — **partial**

Two ways in, presented as equals.

**Continue as guest** → Firebase Anonymous Auth per ADR-008. *Currently a placeholder that returns no token; the server will reject protected routes until `flutterfire configure` is done.* This is the one known incomplete path in the flow.

**Enter demo** → validates a key (case-insensitive, checked entirely on-device, no network) and loads the offline pack. This is the reliable presentation path.

**States.** Idle; invalid key (inline `errorText` naming the expected key); accepted.

**Accessibility.** The key field disables autocorrect and uses character capitalisation. The error is attached to the field, not floated in a toast, so a screen reader reaches it while focused on the input.

---

### 3.3 Shell — **built**

Three destinations: **Path**, **Progress**, **Settings**. Bottom bar on phone, rail on laptop with Lupa in the rail header. Body transitions with a short fade; the destination itself never animates content in a way that delays interaction.

Settings is a **top-level destination**, not buried in a profile menu. For the learners who need text scaling or reduced motion, discoverability is the difference between using the app and closing it.

---

### 3.4 Path — **built**

The winding skill map. Nodes weave left and right, each revealing with a spring as it scrolls into view.

**Node states.** `locked` (outline, lock icon, not tappable), `available` (filled `action`, compass icon), `completed` (filled `evidencePrimary`, tick). A booster-due node gains an amber ring — additive, never the only signal.

**States.** loading · empty ("No missions available yet.") · error + retry with Lupa thinking · success.

**Accessibility.** Each node's semantic label is `"<title>, <state>"` — the state word is spoken, never inferred from colour. The title text below the node is `ExcludeSemantics` because the node already announces it. Returning from a completed mission refetches, so the path never shows stale state.

**Not built:** offline-pack indicator, chapter grouping.

---

### 3.5 Mission — **built**

One screen, four steps, because the underlying Attempt is one continuous object. On laptop the claim stays pinned on the left while the working step scrolls on the right; on phone it is one column in the same order.

Persistent across all steps: error banner (`danger`, with icon), busy banner (Lupa thinking + `liveRegion` so it is announced), report action in the app bar.

#### Step 1 · Predict
Media rendered **as its description** — alt text is the primary content here, not a fallback. Claim below it. Then instinct chips and the confidence slider. `Start investigating` stays disabled until an instinct is chosen.

#### Step 2 · Investigate
Evidence props as chunky tiles that spring in, staggered. A used tile shows a tick and dims. Results accumulate below as cards, each carrying its own **limitations** line — provenance sits next to the evidence, never in a separate legal screen.

`Ask the coach` is opt-in and sits *below* the evidence so the learner reaches for their own checks first. The hint renders in a `CoachBubble` that always shows the AI label, the uncertainty level, and whether the deterministic fallback answered.

`Draw a conclusion` is disabled with visible explanatory text until at least one check is done — unless the mission version sets `testsCriticalIgnoring`, which is exactly the case where concluding without investigating is the thing being taught.

#### Step 3 · Conclude
Three axis pickers, each with **always-visible** plain-language help text (a tooltip is unusable on touch and invisible to a first-time learner). Per-axis confidence appears only once that axis is answered. Then overall confidence, then the share decision. Submit requires all three axes and a share decision.

Every axis offers an explicit uncertainty answer. This is enforced by a test, not just convention — `insufficient evidence` is a first-class outcome.

#### Step 4 · Done
Lupa encouraging, process XP, Slid trail, the disclaimer, then `Open your evidence receipt` (primary) and `Back to the path`.

**States.** bootstrap loading · bootstrap error · busy per action · action error · complete.

---

### 3.6 Evidence receipt — **built**

A document, not a scoreboard. Shows the three-axis conclusion as read-only chips, the evidence actually looked at, the pinned mission version, creation time, and the integrity marker. Demo receipts are labelled **unsigned** rather than given a convincing-looking fake hash.

An axis code the client does not recognise renders verbatim with neutral styling instead of being dropped, so a receipt stays readable across content-pack versions.

The disclaimer — *this records how you investigated; it is not a certificate that something is true or false* — is set in bold body text, not fine print.

---

### 3.7 Progress — **built**

Process XP with the framing line *XP measures your process, not how clever or trustworthy you are* directly under it. Then skill mastery as **segmented** meters: segments are countable by someone who cannot compare bar lengths precisely, and the numeric percentage is always printed alongside.

**States.** loading · empty ("Finish your first mission…") · error + retry · success.

**Not built:** booster scheduling UI, history.

---

### 3.8 Settings — **built**

- **Language** — segmented control, Українська / English.
- **Simpler wording** — switch, with a subtitle stating that safety notes are unchanged.
- **Reduce animation** — switch, with a subtitle stating the OS setting is also respected. One-way: it can only add calm.
- **Text size** — 100–200%, raising the floor only. If the OS is already at 300%, the app must not scale it back down.

**Not built:** persistence across restarts. Settings currently reset on relaunch.

---

### 3.9 Report dialog — **built**

Six reasons, optional detail (≤1000 chars), and a privacy line asking the reporter not to include personal information.

Behaviour that matters more than the layout:
- A **failed send is never confirmed as received** — the dialog stays open with its content intact rather than losing the report.
- In demo mode the confirmation says plainly that nothing was sent anywhere, instead of promising a reviewer who does not exist.
- The server answers `202` and never reveals moderation state, so a reporter cannot probe what happened to a case.

---

## 4. Standards applied

| Standard | Where it shows up |
|---|---|
| **WCAG 2.2 AA** | contrast on every token pair; 44dp targets; visible focus; 200% text without clipping; status never colour-alone; no >3Hz flashing |
| **BCP 47** | locale tags (`uk`, `en`) in settings, `Accept-Language`, and scenario packs |
| **ISO 8601** | all timestamps in the contract (`retrievedAt`, `createdAt`) |
| **RFC 9457** | Problem Details — the client's `Problem` model and every error path |
| **OpenAPI 3.1** | `contracts/openapi.yaml`; the client is a typed mirror of it |
| **Semantic versioning** | scenario pack and mission versions; attempts pin an exact version |
| **Material 3 window size classes** | the 600/1024dp breakpoints |
| **C2PA** | provenance literacy — P1, not in the MVP client |

---

## 5. Coverage checklist

Tick these before calling the client demo-ready.

- [x] Every screen has loading, empty, error+retry and success states
- [x] Every status uses icon + shape + text, not colour alone
- [x] No green/red status colours anywhere
- [x] Every axis offers an explicit uncertainty answer (test-enforced)
- [x] Every disabled primary button has visible text explaining what is missing
- [x] Every animation has a reduced-motion path to the same end state
- [x] Ukrainian and English across every screen
- [x] Phone and laptop layouts from one codebase
- [x] Demo path runs with no backend
- [x] A failed report is never confirmed as sent
- [ ] `flutter analyze` clean — **not yet run**
- [ ] Verified at 200% text on a real device
- [ ] Verified with a screen reader (TalkBack / VoiceOver)
- [x] A connection failure is presented as a connection failure, never as something the server said
- [ ] Guest auth actually authenticates
- [ ] Settings persist across restart
- [ ] Offline *pack download* (P1) — the banner exists; downloadable content does not

The unticked items are the honest gap list. Nothing above should be described as done until it is ticked.
