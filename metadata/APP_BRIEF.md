<!-- gf-brief source=4fce3c91f87c03fdee7501ce44d7915979e1e70f17a2c139da782c174cd2f418 written=2026-10-14T17:03:54+03:00 -->
# 1Woboard

## What it is
1Woboard is a door till for volunteers running a single-screen repertory cinema or community hall. One person keeps the floor on screen: they place a station, clock a volunteer in, cover that station, ring walk-in admissions onto tonight’s till, and advance the pair that is on deck. The house stays on this device. The Home Screen name is “1Woboard”; a few in-app lines still say Callboard.

## Launch and onboarding
The Home Screen label is “1Woboard”. A cold launch shows a dark system launch screen, then the words “1Woboard” and “Opening the floor.”

On an iPhone or iPad, if onboarding has not been finished, three foyer pages follow. Each page has a page mark written as “1 of 3”, “2 of 3”, or “3 of 3” (the numerals follow the device region). “Skip” is on every page and finishes onboarding the same way “Continue” does. “Next” moves forward. On the last page the forward button reads “Continue”.

1. “A door till for the hall” — “Ring walk-ins on a covered station while the volunteer shift stays on the floor.” Buttons: “Next”, “Skip”.
2. “Cover, then ring” — “Clock in, cover a station at health 60 or more, then ring the admission onto the till.” Buttons: “Next”, “Skip”.
3. “Advance the pair” — “Tap the on-deck winner. The interleaved bout moves. Anyone else is a fault.” Buttons: “Continue”, “Skip”.

After “Continue” or “Skip” on a device, the empty floor appears. On later launches, finished onboarding is skipped and the floor opens with whatever was last saved.

On the iOS Simulator, the first launch already finishes onboarding and opens a filled floor (see Starter content). “Replay onboarding” in Settings is how those three pages appear there.

## Screens
There is no tab bar. The floor stays up. Other rooms open as sheets that swipe down to close. A keyboard toolbar “Done” dismisses the keyboard on Floor, Shifts, Bracket, and Door.

### Floor (home)

**Empty floor** (no station yet)
- Headline “The floor is empty”, line “Place the first station”.
- Field placeholder “Name”.
- “Place station” names the first station and opens the populated floor.
- Row “Settings” — “Contact, replay, or reset” opens Settings.

**Populated floor**
- Phase chip: “Dark”, “OnShift”, or “Live”.
- Title “Ring the station”.
- Next-step line, one of:
  - “Tap Ring on {station name} to take the walk-in.” when any station is “Covered” (this line wins even if the chip is “Dark”).
  - “Open Shifts and clock a volunteer in.” when the house is “Dark” and no station is “Covered”.
  - “Tap Cover on a healthy station, then ring it.” otherwise.
- A short “Saved on this floor” band appears after a successful place, cover, ring, maintain, or advance, then fades.
- Notices appear in a band with “Retry”.

**“Floor”**
- A lamp row, one lamp per station. Tapping a lamp rings that station. VoiceOver: “Ring {name}, {Open or Covered}, health {number}”.
- The first “Covered” station is the hero card (or the first station if none is covered). It shows “Open” or “Covered”, the station name, and “Health {number}”.
- Other stations sit below, each as “{name}” and “{Open or Covered} {number}”.
- On every station:
  - “Ring” takes a walk-in. On a “Covered” station it writes a “Till” ticket for 12 in the device region’s currency and adds that amount to the float. On an “Open” station it writes an “Open ring” ticket whose detail is “Gap” and leaves the float unchanged. VoiceOver on the button: “Ring {name}”.
  - “Cover” marks the station “Covered” when the house is not “Dark” and Health is 60 or more. It is dimmed and does not accept a tap once the station is already “Covered”. VoiceOver: “Cover {name}”.
  - “File incident” opens the incident slate on this floor. VoiceOver: “File incident on {name}”.
  - “Maintain” appears only when Health is under 60. It raises Health.
- A long press on a station card also opens the incident slate.

**Incident slate** (on the floor, not a sheet)
- Title “Incident on {station name}”.
- “Draw what failed. Saving lowers health.”
- A drawing area.
- “Save incident” files the drawing, lowers Health by 1, and closes the slate.
- Close control (VoiceOver “Close”) dismisses without saving.

**“Tonight”**
- Empty: “No tickets yet. Ring a covered station.”
- Filled: a horizontal strip. Each ticket shows kind “Till” or “Open ring”, the station name, and either the currency amount or “Gap”. The newest ticket is larger.

**“Float tonight”**
- Today’s float in the device region’s currency (opening 0, plus each covered ring of 12).

**“On deck”**
- Empty: “No pair is on deck. Open Bracket and seed a bout.”
- Filled: the bout name, then each seated person as “On deck” (with “Advance”) or “Waiting” (no button). “Advance” moves the on-deck winner and seats the next pair. VoiceOver on the button: “Advance {name}”.

**“Also tonight”**
- “Shifts” — “Clock a volunteer in or out” opens Shifts.
- “Finance” — “Reconcile tonight's float” opens Finance.
- “Bracket” — “Seat the next pair” opens Bracket.
- “Door” — “Read a comp or member code” opens Door.
- “Settings” — “Contact, replay, or reset” opens Settings.

After the first station is placed, there is no control to add another station.

### Shifts
Navigation title “Shifts”. Keyboard “Done”.

**Empty** (no roster and no shifts)
- “No one is on the roster”
- “Add a volunteer, then clock them in.”
- Field “Volunteer name”
- “Add volunteer”

**Roster**
- Phase line: “House is Dark until someone clocks in.”, “House is OnShift.”, or “House is Live.”
- The same name field and “Add volunteer”.
- Each volunteer shows their name and either “On the floor” with “Clock out”, or “Off duty” with “Clock in”.
- “Clock in” on the first open shift turns the house from “Dark” to “OnShift”. “Clock out” on the last open shift returns the house to “Dark”. A covered station stays “Covered”. Several volunteers can be “On the floor” at once.
- Notices with “Retry”.

### Finance
Navigation title “Finance”.

- Caption “House float” and today’s float in currency.
- Empty: “No rings tonight” and “Cover a station, then ring a walk-in. The till lands here.”
- Filled: one row per covered ring tonight, station name and amount.
- If any open rings exist tonight: “{number} open rings did not enter the float.” This line can sit under the empty state when tonight only has open rings.
- “Export tonight CSV” is dimmed until there is at least one “Till” tonight. After a successful export, a sheet offers “Share the till file”, which opens the system share sheet.
- Notices with “Retry”.

### Bracket
Navigation title “Bracket”. Keyboard “Done”.

**No pair on deck — “Seat a bout”**
- “Add two, four, or eight names, then seed the bracket.”
- Field “Bout name”
- Field “Person name” and “Add”
- Empty list line: “Names you add sit here until you seed.”
- Added names sit in a list. There is no remove control.
- “Seed bout” seats the bout and shows the on-deck pair. The typed order is mixed. For four names A, B, C, D the seated order is A, D, B, C, so the opening pair is A and D, then B and C. For two names, they are the pair. For eight names typed 1 through 8, the seated order is 1, 8, 4, 5, 2, 7, 3, 6, so the opening pair is 1 and 8, then 4 and 5, then 2 and 7, then 3 and 6.

**A pair on deck**
- The bout name.
- “{name} and {name} are on deck. Tap who wins this pair.”
- “Advance {name}” on each of those two names.
- If others remain: “Still seated” and their names, with no advance control.
- After the last pair is advanced, this sheet returns to “Seat a bout”. A new bout can be seeded; the finished bout is no longer shown.

Notices with “Retry”.

### Door
Navigation title “Door”. Keyboard “Done”.

- Title “Door code”
- “Read a comp or a member code. Digits only, eight to fourteen.”
- After a valid file: “Filed {code}”
- Camera block:
  - Not yet asked: “The next step asks the system about the camera.” and “Continue”. “Continue” shows the system camera alert (the only Allow). The alert names the app “1Woboard” and uses the usage string below.
  - Allowed: a live camera preview that reads a QR.
  - Denied or restricted: “The camera is unavailable. You can still type a code, or open Settings.” and “Open Settings”.
  - Unknown: “The camera state is unknown. Type the code instead.”
- Field “Type a code” (number pad)
- “File code”
- A code must contain a run of 8 to 14 digits. A 12-digit run is filed with a leading 0, so the “Filed” line shows 13 digits. After a valid QR, “Filed {code}” updates; another QR can be read while Door stays open. Leaving Door or sending the app to the background stops the camera. Filed codes are not kept after Door is dismissed.
- Door does not show notices on this sheet. A rejected code sets “That code needs a run of 8 to 14 digits.” on the floor behind the sheet; it is visible after Door is closed.
- On the iOS Simulator only: caption “Sample codes” and chips “012345678905” (filed with a leading 0) and “1234567890123”.

### Settings
Navigation title “Settings”.

- If there are no stations and no till marks: “Nothing is stored yet” and “Place a station on the floor. These controls stay here.”
- Otherwise: “House on this device” and “{number} stations, {number} till marks.” The words stay “stations” and “till marks” even when the count is 1. After one station and no rings this reads “1 stations, 0 till marks.” The till count is every till mark on the device, not only tonight.
- Notices with “Retry”.
- “Replay onboarding” closes Settings and shows the three foyer pages again. Saved stations, shifts, tickets, and the bout stay.
- “Reset all data” opens the alert “Reset the house?” with message “Stations, shifts, till marks, and the bracket leave this device.” Buttons: “Reset all data” and “Cancel”. Confirming clears the house and returns to onboarding.
- “Contact Callboard” opens the support page.

## Features
- Door till for walk-in admissions on a covered station
- Floor plan with station lamps, “Open” / “Covered”, and Health
- Place the first station
- Cover, then ring
- Ring on an open station writes an “Open ring” / “Gap”
- Tonight ticket strip
- Float tonight / House float
- Volunteer roster, “Clock in”, “Clock out”
- House phases “Dark”, “OnShift”, “Live”
- File incident on a drawing slate (lowers Health)
- Maintain a station when Health is under 60
- Bracket: seat a bout, on-deck pair, “Advance”
- Door code: QR or typed digits for a comp or member code
- Finance for tonight’s till and “Export tonight CSV”
- Replay onboarding, reset the house, contact Callboard
- House on this device

## Behaviours that can look like bugs
- “Place station” does nothing useful until the “Name” field has a non-blank name (spaces alone do not count). Notice: “Name the station, then place it.” Then tap “Place station” again, or “Retry”.
- After the first station is placed, there is no “Place station” control. A second station cannot be added. There is no rename or delete for a station. “Reset all data” is the only way to start the floor over.
- The walk-in amount cannot be changed. Every covered “Ring” is 12 in the device region’s currency.
- “Cover” stays dim on a station that is already “Covered”. There is no uncover control. The notice “This station is already Covered.” exists if that tap is repeated some other way.
- “Cover” while the chip is “Dark” is refused: “The house is Dark. Clock a volunteer in, then cover.” Open Shifts, “Add volunteer”, “Clock in”, then cover.
- If a station is already “Covered” and the last volunteer clocks out, the chip returns to “Dark” but the station stays “Covered”. The next-step line still says “Tap Ring on {name} to take the walk-in.” “Ring” still writes a “Till”. “Cover” on any remaining “Open” station is refused until someone clocks in again.
- “Cover” when Health is under 60 is refused: “Health is under 60. Maintain the station, then cover.” A new station starts at Health 100. Each “Save incident” lowers Health by 1. Each local calendar day since the station was placed (or since the last “Maintain”) also lowers Health by 1. “Maintain” is hidden while Health is 60 or more; file incidents (or wait through enough midnights) until Health is under 60, tap “Maintain” until Health is 60 or more, then “Cover”. Each “Maintain” today raises Health by 1 and clears the day-count penalty.
- Opening “File incident” again shows a blank slate. Earlier drawings are not shown, but Health stays lower.
- “Ring” always runs on a placed station. If the station is “Open”, Tonight shows “Open ring” and “Gap”, Finance says those “open rings did not enter the float.”, and the float does not rise. Cover first if the till should move.
- “Export tonight CSV” stays dim when Tonight only has open rings, or when there are no tickets. Cover, ring, then export.
- “Add volunteer” with a blank name: “Write a name before you add a volunteer.” There is no remove control for a volunteer.
- “Seed bout” with a blank bout name: “Name the bout before you seed it.”
- “Seed bout” unless there are exactly two, four, or eight added names: “Seed two, four, or eight entrants so the pair can interleave.” Add more names, or start over by leaving Bracket (the draft list is not saved).
- “Add” on Bracket with an empty “Person name” does nothing and shows no notice.
- Draft names, a typed door code, and an unsaved incident drawing are lost if that surface is dismissed. “Advance” is only on “On deck” names; “Waiting” / “Still seated” people have no advance button, even though onboarding says anyone else is a fault.
- After the last on-deck pair is advanced, “On deck” returns to “No pair is on deck. Open Bracket and seed a bout.”
- “Save incident” with no drawing: “Draw the incident on the slate, then save it.”
- “File code” or a QR without 8 to 14 digits: “That code needs a run of 8 to 14 digits.” That line is not drawn on Door; close Door to see it on Floor, then type or scan again.
- “Continue” on Door does not grant the camera; the system alert does. If the person denies it, Door shows “The camera is unavailable…” and “Open Settings”, or they can type a code.
- Primary buttons dim and ignore a second tap while a save is in flight.
- “Tonight” and Finance show only the current local calendar day. After midnight they look empty again; stations, cover, the roster, Health, and the bout remain. Yesterday’s till marks still count in Settings.
- “Live” appears only when someone is “On the floor”, the first station is “Covered”, and a pair is “On deck”. Missing any one of those keeps the chip at “OnShift” or “Dark”.
- Other notices that can appear: “The floor has no stations. Place one, then try again.”; “That station is not on the floor.”; “That volunteer is not on the roster.”; “No open shift to clock out.”; “That bout is not on the rail.”; “The house file was unreadable. The last good copy is back.”; “The house file could not be read. Starting from an empty floor.”; “The house could not be saved. The floor on screen is unchanged.”; “The previous house file could not be copied aside.”; “A house file could not be removed.”; “The till file could not be written. Try the export again.” Use “Retry” or “Export tonight CSV” again.

## Starter content and resume
On an iPhone or iPad: None. A first launch has no stations, no volunteers, no tickets, and no bout.

On the iOS Simulator, the first launch (when the floor is still empty) already finishes onboarding and fills the house: stations “Front door” (Covered), “Balcony”, “Side aisle”, and “Cloak”; volunteer “Nia Cole” “On the floor”; bout “Late house” with Reed and Adler “On deck” and Marlow and Quinn “Waiting”; three “Till” tickets on “Front door”; phase chip “Live”; Settings “4 stations, 3 till marks.” Door also shows “Sample codes”. That seed runs once.

Unfinished house work that was saved can be resumed: the station, cover, open shifts, tonight’s till (same local day), the seated bout, Health, and the finished-onboarding flag return on the next launch. Unsaved drafts on Shifts, Bracket, Door, and the incident slate do not.

## Permissions
Camera, only on Door, and only after “Continue” when access has not been decided. Usage string: “Callboard uses the camera to read a door QR for a comp or a member code at the foyer.”

No microphone, photos, or location.

## Absent
Login or accounts; in-app purchase; ads; analytics; user-generated content (no public posts, no report or block); account deletion flow; App Tracking Transparency prompt.

## Data and support
Data stays on this device. Settings says “House on this device”. Reset copy says stations, shifts, till marks, and the bracket leave this device.

On-screen support: “Contact Callboard” on Settings, which opens the support page.

## Scanning and health
The Door camera reads a QR for a comp or member code. It expects a run of 8 to 14 digits in the code (or the same digits typed). A 12-digit run is filed with a leading 0. It does not look up products.

The floor shows a station “Health” number (readiness of that foyer station). That is not medical or product-health information. No citations.

## Platform
The words are English. Amounts and whole numbers follow the device region (currency, grouping). The night rolls at the device’s local midnight. No country lock.

Portrait only, full screen, dark appearance. iPhone and iPad. Minimum iOS 17.0.

## Category
Business
