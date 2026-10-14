# Callboard

Callboard is a door till for volunteers running a single-screen rep cinema or community hall. The floor plan stays on screen. A volunteer clocks in, covers a healthy station, rings walk-in admissions onto tonight's till, and advances the interleaved bout between shows. Nothing leaves the device.

## Architecture

The house is an algebraic fold with phases Dark, OnShift, and Live. The floor is a fold over stations and bouts. Clock, Cover, Ring, Seed, and Advance are the only writers, and `HouseStore` is the only seam to `UserDefaults` and the house file. That fits a venue night: every tap is a mark, and the phase is derived, so the till and the bracket cannot drift from the stations on the floor. A floor with no stations writes Bare. Live requires an open shift, a covered front station, and an OnDeck pair.

## Cover, then ring

Clock writes a ShiftMark and folds Dark to OnShift. Cover writes a CoverMark when station health is at least 60 and folds that station from Open to Covered. Cover while Dark is refused. Ring on a Covered station writes a TillMark and adds the admission to the float. Ring on an Open station writes a GapMark and leaves the float unchanged. Seed interleaves bout entrants in power-of-two order so the opening OnDeck pair is the first two slots, and folds the bracket from Idle to Live. Advance writes an AdvanceMark only when the tapped entrant is one of those two names, then promotes the next pair. Advance on anyone else writes a FaultMark. Station health is `100 - incidents - repairs - age penalties + recent maint`.

This is venue operations with a persisted floor verb. It is not a purse or odds board, not a two-seat reel, and not an inventory trail.

## Art

Style: flat vector illustration, typographic weight, solid shapes, hard edges, generous negative space. Editorial ticket-strip mood. No gradients, no clay, no glass, no photoreal rendering, no letters, and no numerals.

Prompts:

- `clb_AppIcon`: A flat vector foyer bell, one solid silhouette, typographic weight, no letters and no numerals, subject filling the middle of a square canvas edge to edge.
- `clb_Splash`: A tall flat vector foyer with a quiet center band and a ticket rail along the bottom, solid shapes, no letters, filling the portrait canvas.
- `clb_Onboarding1`: A volunteer standing at a covered door station, flat vector, one solid figure, the door till readable as a job at a glance, no letters.
- `clb_Onboarding2`: A hand ringing a ticket onto a horizontal strip, mid gesture, flat vector, solid forms, no letters.
- `clb_Onboarding3`: An interleaved pair of bout plates on a short rail with one plate forward, flat vector, solid plates, no readable words.
- `clb_EmptyHome`: A solid closed ticket booth with the shutter down, wood and paper, fully opaque, flat vector, waiting, no letters.
- `clb_EmptyList`: A solid blank roster card with a torn stub edge, opaque paper, flat vector, no letters.
- `clb_CardBackdrop`: Abstract flat vector bands like a ticket ground, low detail, filling the wide canvas, no letters.
- `clb_ControlFace`: A solid round till key, metal, flat vector, centered and opaque, no letters.
- `clb_TwistHero`: A covered station lamp beside a punched ticket, flat vector emblem, solid forms, no letters.
- `clb_SuccessMark`: A solid filled ticket-punch disk, metal, occupying the middle of the canvas, not an outline and not a hollow ring.
- `clb_HeaderDecor`: A wide perforated ticket edge, flat vector ornament, no letters, filling the band.
- `clb_StationPlinth`: A single foyer station plinth, solid wood, flat vector, isolated subject, no letters.
- `clb_TicketStub`: One admission ticket stub, solid paper, flat vector, isolated subject, no readable words.
- `clb_BoutPair`: Two facing name plates on a short rail, solid, flat vector, isolated subject, no readable words.
- `clb_DoorCrest`: A small door-key fob, solid metal, flat vector, isolated subject, no letters.

## Build

```bash
cd apps/Callboard
xcodegen generate
xcodebuild build-for-testing -scheme Callboard -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
