# Callboard — Build Specification

> Portfolio app 152, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Ring walk-in admissions on covered stations, clock volunteer shifts, and advance tonight's bout bracket from the floor.

| Field | Value |
| --- | --- |
| Product name | Callboard |
| Bundle identifier | `com.callboard.floor` |
| Domain | https://callboard-floor.pro |
| Contact URL | https://callboard-floor.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `clb_` |
| User-Agent | `Callboard/1.0 (iOS; +https://callboard-floor.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Callboard -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A house manager rings walk-in admissions on covered stations and advances the interleaved bout strip while tonight's volunteer shift stays clocked on the floor.

### 2.1 User flow

1. Tap the covered front station to ring the first walk-in admission onto the till strip.
2. Long-press a dim station to file an incident and watch its health drop below cover threshold.
3. Tap Cover on a healthy station once a volunteer shift is clocked in.
4. Tap the on-deck entrant who won the bout so the interleaved bracket advances.
5. Open Shifts as a sheet to clock a volunteer in or out.
6. Open Finance as a sheet to reconcile today's TillMarks against the house float.

### 2.2 Essential behaviour

- Floor plan with station health coloring and cover state
- Shift clock for on-duty volunteers
- Cover and ring fused on the floor canvas
- Interleaved power-of-two bracket rail with on-deck advance only
- Local till strip and daily float ledger
- Incident log that penalizes station health
- Bracket sheet with optional title search to seed entrants
- Door QR scan for comps or member codes
- Midnight daykey roll for till and shift totals
- On-device export of the night's till CSV

---

## 3. Uniqueness assignment for Callboard

| Axis | Assigned value |
| --- | --- |
| Architecture | **House ADT fold (Dark | OnShift | Live); the floor is a fold over Stations and Bouts; Clock writes a ShiftMark and folds Dark to OnShift; Cover writes a CoverMark when station health is at least 60 and folds that Station Open to Covered; Ring writes a TillMark on a Covered station and adds to Float; Ring on Open writes a GapMark; Seed interleaves Bout entrants in power-of-two order; Advance writes an AdvanceMark when the tapped Entrant is an OnDeck winner and promotes the next pair, folding bracket Idle to Live when seeded; Advance elsewhere writes a FaultMark; Cover on Dark is refused; a floor with no Stations writes Bare** |
| UI approach | **SwiftUI PencilKit representable · spritekit-accent** |
| Naming convention | **Rep-house / foyer lexicon** |
| File organization | **By house role (Floor, Station, Staff, Shift, CoverMark, TillMark, Bout, Entrant, AdvanceMark, Float, GapMark, FaultMark)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **editorial · ticket-strip · high-contrast** |
| Typography | **Palatino** |
| Navigation pattern | **Floor-locked chrome (the floor plan and ticket timeline never leave; Shifts, Bracket and Finance arrive as sheets; cover and ring fuse on Floor; advance fuses on the bracket rail)** |
| AI art style | **Flat vector illustration · typographic** |
| Functional twist | **Cover-then-ring with interleaved advance (Clock folds Dark to OnShift; Cover on health≥60 folds Station Open to Covered; Ring on Covered writes TillMark; Ring on Open writes GapMark; Advance on OnDeck winner writes AdvanceMark and promotes interleaved pair; Cover on Dark refused; seed clocks shift, covers front station, and opens first bout OnDeck)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — venue_ops

**Core** — A house manager rings walk-in admissions on covered stations and advances the interleaved bout strip while tonight's volunteer shift stays clocked on the floor.

**Audience** — Volunteers running a single-screen rep cinema or community hall who need a door till, a station health floor, and a bracket between shows—not a cloud POS or a streaming queue.

**User flow**

1. Tap the covered front station to ring the first walk-in admission onto the till strip.
2. Long-press a dim station to file an incident and watch its health drop below cover threshold.
3. Tap Cover on a healthy station once a volunteer shift is clocked in.
4. Tap the on-deck entrant who won the bout so the interleaved bracket advances.
5. Open Shifts as a sheet to clock a volunteer in or out.
6. Open Finance as a sheet to reconcile today's TillMarks against the house float.

**Essential features**

- Floor plan with station health coloring and cover state
- Shift clock for on-duty volunteers
- Cover and ring fused on the floor canvas
- Interleaved power-of-two bracket rail with on-deck advance only
- Local till strip and daily float ledger
- Incident log that penalizes station health
- Bracket sheet with optional title search to seed entrants
- Door QR scan for comps or member codes
- Midnight daykey roll for till and shift totals
- On-device export of the night's till CSV

**Twist** — Cover-then-ring with interleaved advance. Home is the floor plan and horizontal ticket timeline. Clock writes a ShiftMark and folds Dark to OnShift. Cover writes a CoverMark when health is at least 60 and folds a Station Open to Covered. Ring writes a TillMark and adds to Float only on a Covered station; Ring on Open or uncovered writes a GapMark and keeps Float. Advance accepts only the two OnDeck entrants; the winner writes an AdvanceMark and promotes the next interleaved pair. Advance on a non-on-deck entrant writes a FaultMark. Cover on Dark is refused. Seed already clocks one shift, covers the front station, and seats the first bout OnDeck so Ring or Advance is live on first tap. Home verb: ring-the-station—not reel-a-queue and not lock-a-pick. Local only.

**Why this is not a repeat** — This is venue_ops with a persisted floor verb: cover gating, till rings, and interleaved bracket advance on one timeline home. It is not Quoinlock (no purse or sports odds), not Bioscope (no two-seat reel or WatchMarks), not Stallage (no inventory hop trail), and not a metric-capacity counter or a browse-first catalog crate.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Floor plan. Seats colored by health.
- Invariant: health = 100 − incidents − repairs − age penalties + recent maint. Bracket: power-of-two seed interleave.
- Never: Local till. No cloud POS.
- Desk `watch_rate`: OLS s/day vs day; R²; DU/DD/CU/CL/CD spread; COSC |dev|≤4.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

### 3.1 Architecture contract

The house is an algebraic fold with phases Dark, OnShift, and Live, and the floor is a fold over Stations and Bouts. Clock writes a ShiftMark and folds Dark to OnShift, Cover writes a CoverMark only when that station's health is at least 60 and folds the station from Open to Covered, and Cover while the house is still Dark is refused. Ring on a Covered station writes a TillMark and adds the walk-in admission to Float, while Ring on an Open station writes a GapMark and leaves Float unchanged. Seed interleaves Bout entrants into power-of-two slots so the opening OnDeck pair is the first two positions of that order and folds the bracket from Idle to Live, Advance writes an AdvanceMark only when the tapped Entrant is one of those two OnDeck names and then promotes the next pair in the same order, and Advance on any other entrant writes a FaultMark. A floor with no Stations writes Bare, and the house reaches Live only once it is OnShift, the front station is Covered, and a bout is OnDeck. Station health is derived by the unit-tested rule health = 100 - incidents - repairs - age penalties + recent maint, where incidents and repairs are mark counts on that station, age penalties are whole days since the last maint daykey, and recent maint adds credit when a maint mark shares today's daykey, and that same test covers the power-of-two seed interleave.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Floor is the only custom-rendered surface. A PKCanvasView in a UIViewRepresentable is the incident slate: a long-press on a dim station opens that slate on the floor, and the saved drawing is the incident that lowers health. An SKView is the sprite accent on that same floor plan, one lamp sprite per station for health and cover, and it does not appear on any sheet. Shifts, Bracket, Finance, Door, Settings, and onboarding are stock SwiftUI lists, forms, and sheets. The floor plan and the horizontal ticket timeline stay on screen together, with one active ticket. Cover and Ring are native buttons on the station, and Advance is a native button on each OnDeck entrant on the bracket rail. Each hit target is the whole control, at least 44 points, with a content shape on the fill. Colour is paired with a word: Open, Covered, Dark, OnShift, Live, and the health number. Radius, type, and spacing come from the existing accessors, one radius language and one elevation. Grouped reveals step 40 to 60 milliseconds and finish within 360 milliseconds. Reduce Motion shows the group at once and keeps fade. The floor uses the full width on iPad. The implementation words for the canvas and the lamp layer are not user-visible labels.

### 3.3 Naming contract

Convention: Rep-house / foyer lexicon.

Examples to follow: CoverMark names a station that passed the health gate. TillMark names a ring on a covered station. GapMark names a ring on an open station. AdvanceMark names an on-deck winner moving the interleaved bout.

### 3.4 Dependency contract

No Package.swift, no SPM product, no Podfile, and no vendored third-party source. The target links system frameworks only: SwiftUI, UIKit, Core Graphics, AVFoundation, URLSession, PencilKit, and SpriteKit. URLSession performs the optional bracket title search and sends User-Agent Callboard/1.0 (iOS; +https://callboard-floor.pro). There is no analytics SDK, no remote config, and no web view.

### 3.5 Navigation contract

The floor plan and the ticket timeline are the permanent root and stay on screen. Shifts, Bracket, Finance, Door, and Settings arrive as sheets over that root. Cover and Ring sit on each station on Floor. Advance sits on the bracket rail on Floor. Chrome is this single floor root with sheets, and there is no tab bar. ProcessInfo.processInfo.arguments is read once, after onboarding is finished. The today key leaves Floor up, log presents Finance, goals presents Bracket, shifts presents Shifts, and settings presents Settings. Each of those keys shows a different surface.

### 3.6 Screen composition contract

Floor-root fused house (Floor holds the station plan and ticket timeline; Shifts, Bracket and Finance arrive as sheets; cover, ring and advance fuse on Floor; Settings as sheet; no tab bar). physical screens: Floor, Shifts, Bracket, Finance, Door, Settings, Onboarding. Floor is the home mechanic: station plan, health and cover on each station, horizontal ticket timeline, and the bracket rail. The empty floor is a full page with the headline The floor is empty, the line Place the first station, and a full-width Place station control. The Simulator seed fills Floor with several stations, several till tickets, one clocked shift, the front station Covered, and the first bout OnDeck, so Ring is enabled. Shifts is a sheet to clock a volunteer in or out, writing a ShiftMark. Bracket is a sheet to seed entrants, with an optional title search that calls /cgi/search.pl at page_size 20. A bundled local shelf answers when that search is empty or fails, and the volunteer can still type an entrant. Finance is a sheet to reconcile today's TillMarks against the house float and to export that night's till as a CSV on device. Door is a sheet that captures a door QR for a comp or a member code. The button before requestAccess reads Continue. Denied or restricted camera explains the state and opens Settings. The session stops on disappear and on background. Simulator shows sample-code chips and a manual field. Payload handling keeps digit runs of length 8 to 14, and a 12-digit UPC-A gains a leading 0. Settings is a sheet with replay onboarding, a confirmed reset of all data, and a tappable contact link to https://callboard-floor.pro/contact-us. Onboarding is three or four full pages, with Next or Continue full width at the bottom. Skip still writes defaults. The Simulator seed marks onboarding complete so the review keys can fire.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By house role (Floor, Station, Staff, Shift, CoverMark, TillMark, Bout, Entrant, AdvanceMark, Float, GapMark, FaultMark)**

```
Callboard/
  Floor/FloorFold.swift
Floor/FloorPlanView.swift
Floor/TicketTimelineView.swift
Floor/StationLampScene.swift
Station/Station.swift
Station/StationHealth.swift
Station/IncidentSlate.swift
Staff/Staff.swift
Shift/Shift.swift
Shift/ShiftMark.swift
CoverMark/CoverMark.swift
TillMark/TillMark.swift
Bout/Bout.swift
Bout/Entrant.swift
AdvanceMark/AdvanceMark.swift
Float/Float.swift
GapMark/GapMark.swift
FaultMark/FaultMark.swift
House/HouseChart.swift
House/HouseStore.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Floor
A first-class screen for **Floor**. Must render empty, populated and error states.

### 5.3 Shifts
A first-class screen for **Shifts**. Must render empty, populated and error states.

### 5.4 Finance
A first-class screen for **Finance**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Station** — named per this app's convention.
- **Shift** — named per this app's convention.
- **Staff** — named per this app's convention.
- **Event** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **editorial · ticket-strip · high-contrast**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#0F0F0F` | Screen background |
| `surface` | `#1F1F1F` | Cards, rows, sheets |
| `ink` | `#FAFAFA` | Primary text and icons |
| `accent` | `#DD5F9E` | Primary action, key figure, progress fill |
| `muted` | `#B2B2B2` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Callboard/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Palatino**

Palatino is the only UI face, reached through one accessor with six steps: display, title, headline, body, caption, and micro. Palatino-Bold carries display, title, and the till figure. Palatino-Roman carries headline, body, and caption. Palatino-Italic is the single playful moment, used only for the active ticket's short caption. No step is larger than 34pt. Body stays on the 17pt step. Till amounts, station health, and bout counts go through NumberFormatter, with monospaced digits so columns do not jump. Day edges use Calendar.current.startOfDay before they fold into a YYYYMMDD integer. Sizes track Dynamic Type through ScaledMetric. At the largest accessibility size, a long line may fall back to New York so a Palatino headline is not clipped. There is no second type family.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **28pt** for cards, sheets and primary surfaces; **14pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **filled capsule** — the primary CTA is a full-width filled `Capsule`, never a bare text link or a plain `.plain` button.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI PencilKit representable · spritekit-accent**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI PencilKit representable · spritekit-accent** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **editorial** (Editorial: measure, rules, type hierarchy, almost no boxes.)

Reference system: **editorial** — steal rhythm and restraint, not their colours or logos.

Mood: **Magazine-inspired editorial layout with refined serif typography, structured grids, and elegant reading experiences.**.

Home rhythm (`ticket-strip`, comfortable): Horizontal tickets, perforated edge implied, one active.

Editorial: measure, rules, type hierarchy, almost no boxes. Layout `ticket-strip`, density comfortable. Kit 28/14, material, filled capsule. Palette recipe `high-contrast`. Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Soft rounded UI type, one playful moment, no serif. Reference type feel: editorial.

Motion (`stagger`): Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

UserDefaults stores one Codable Chart root, HouseChart, under the single key clb.house.v1. HouseChart holds Stations, Staff, Shifts, Bouts, Entrants, the house phase, the bracket phase, the walk-in admission amount, Float, and the append-only marks CoverMark, ShiftMark, TillMark, GapMark, AdvanceMark, and FaultMark. Each station holds incident drawings, repair marks, and maint marks so health stays derived. A mark schedules one debounced save of that record about 400ms after the last change, and the store flushes when scenePhase leaves active. TillMarks and ShiftMarks store daykey as an Int in YYYYMMDD form, taken from Calendar.current.startOfDay. At the midnight roll the previous daykey keeps its till total and shift total, and the new daykey opens a fresh float line in the same root. Screens talk only to the store seam. resetAllData deletes the key and is reachable from Settings. A decode failure replaces the root with a Bare house. The Simulator seed runs once behind clb.demo.v1, under targetEnvironment(simulator), writes the happy path, and marks onboarding complete. A device never seeds.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Callboard/1.0 (iOS; +https://callboard-floor.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.business`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.business
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Cover-then-ring with interleaved advance (Clock folds Dark to OnShift; Cover on health≥60 folds Station Open to Covered; Ring on Covered writes TillMark; Ring on Open writes GapMark; Advance on OnDeck winner writes AdvanceMark and promotes interleaved pair; Cover on Dark refused; seed clocks shift, covers front station, and opens first bout OnDeck)

Home is the floor plan and the horizontal ticket timeline, and the verb on that surface is ring-the-station. Clock folds the house from Dark to OnShift, Cover on a station whose health is at least 60 folds that station from Open to Covered, and Cover while Dark is refused. Ring on a Covered station writes a TillMark and adds to Float, Ring on an Open station writes a GapMark and keeps Float, Advance on an OnDeck winner writes an AdvanceMark and promotes the next interleaved pair, and Advance on anyone else writes a FaultMark. The Simulator seed, once, behind clb.demo.v1, clocks one shift, covers the front station, and seats a four-entrant power-of-two bout with the first pair OnDeck, so Ring and Advance are live on the first tap. Cover on Dark, Ring on Open, and Advance off the on-deck pair are unit-test fixtures and stay off the first frame.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Flat vector illustration · typographic**


Base prompt, reused and extended for every asset:

```
Flat vector illustration with typographic weight. Solid shapes, hard edges, generous negative space, and one strong figure-ground. Editorial ticket-strip mood: perforated paper, a foyer bell, a horizontal rail. No gradients, no clay, no glass, no photoreal rendering, no letters, and no numerals.
```

All 16 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `clb_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `clb_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `clb_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `clb_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `clb_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `clb_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `clb_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `clb_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `clb_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `clb_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `clb_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Cover-then-ring with interleaved advance (Clock folds Dark to OnShift; Cover on health≥60 folds Station Open to Covered; Ring on Covered writes TillMark; Ring on Open writes GapMark; Advance on OnDeck winner writes AdvanceMark and promotes interleaved pair; Cover on Dark refused; seed clocks shift, covers front station, and opens first bout OnDeck)' feature screen. |
| 11 | `clb_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `clb_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |
| 13 | `clb_StationPlinth` | 1024x1024 | **required cutout** | A single foyer station plinth, solid wood, flat vector, isolated subject, no letters. |
| 14 | `clb_TicketStub` | 1024x1024 | **required cutout** | One admission ticket stub, solid paper, flat vector, isolated subject, no readable words. |
| 15 | `clb_BoutPair` | 1024x1024 | **required cutout** | Two facing name plates on a short rail, solid, flat vector, isolated subject, no readable words. |
| 16 | `clb_DoorCrest` | 1024x1024 | **required cutout** | A small door-key fob, solid metal, flat vector, isolated subject, no letters. |

### Prompt per asset

**`clb_AppIcon`** — 1024x1024

```
A flat vector foyer bell, one solid silhouette, typographic weight, no letters and no numerals, subject filling the middle of a square canvas edge to edge.
```

**`clb_Splash`** — 1290x2796

```
A tall flat vector foyer with a quiet center band and a ticket rail along the bottom, solid shapes, no letters, filling the portrait canvas.
```

**`clb_Onboarding1`** — 1024x1536

```
A volunteer standing at a covered door station, flat vector, one solid figure, the door till readable as a job at a glance, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_Onboarding2`** — 1024x1536

```
A hand ringing a ticket onto a horizontal strip, mid gesture, flat vector, solid forms, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_Onboarding3`** — 1024x1536

```
An interleaved pair of bout plates on a short rail with one plate forward, flat vector, solid plates, no readable words.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_EmptyHome`** — 1024x1024

```
A solid closed ticket booth with the shutter down, wood and paper, fully opaque, flat vector, waiting, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_EmptyList`** — 1024x1024

```
A solid blank roster card with a torn stub edge, opaque paper, flat vector, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_CardBackdrop`** — 1200x800

```
Abstract flat vector bands like a ticket ground, low detail, filling the wide canvas, no letters.
```

**`clb_ControlFace`** — 512x512

```
A solid round till key, metal, flat vector, centered and opaque, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_TwistHero`** — 1024x1024

```
A covered station lamp beside a punched ticket, flat vector emblem, solid forms, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_SuccessMark`** — 512x512

```
A solid filled ticket-punch disk, metal, occupying the middle of the canvas, not an outline and not a hollow ring.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_HeaderDecor`** — 1200x600

```
A wide perforated ticket edge, flat vector ornament, no letters, filling the band.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_StationPlinth`** — 1024x1024

```
A single foyer station plinth, solid wood, flat vector, isolated subject, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_TicketStub`** — 1024x1024

```
One admission ticket stub, solid paper, flat vector, isolated subject, no readable words.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_BoutPair`** — 1024x1024

```
Two facing name plates on a short rail, solid, flat vector, isolated subject, no readable words.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`clb_DoorCrest`** — 1024x1024

```
A small door-key fob, solid metal, flat vector, isolated subject, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`clb.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `CallboardTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Callboard/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Callboard -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **House ADT fold (Dark | OnShift | Live); the floor is a fold over Stations and Bouts; Clock writes a ShiftMark and folds Dark to OnShift; Cover writes a CoverMark when station health is at least 60 and folds that Station Open to Covered; Ring writes a TillMark on a Covered station and adds to Float; Ring on Open writes a GapMark; Seed interleaves Bout entrants in power-of-two order; Advance writes an AdvanceMark when the tapped Entrant is an OnDeck winner and promotes the next pair, folding bracket Idle to Live when seeded; Advance elsewhere writes a FaultMark; Cover on Dark is refused; a floor with no Stations writes Bare** with no leakage across layers.
- [ ] UI approach matches **SwiftUI PencilKit representable · spritekit-accent**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Floor-locked chrome (the floor plan and ticket timeline never leave; Shifts, Bracket and Finance arrive as sheets; cover and ring fuse on Floor; advance fuses on the bracket rail)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Palatino** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Callboard
xcodegen generate
xcodebuild build-for-testing -scheme Callboard -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.callboard.floor/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Callboard -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.callboard.floor/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Callboard -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.callboard.floor/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
