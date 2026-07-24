# Corso Athletics for iPad

Native, iPad-first athletics coaching workspace built with SwiftUI and PencilKit.

## 0.1.3 fresh-launch repair

- Uses a new pilot bundle identity so Swift Playgrounds installs a fresh app
  instead of reopening the cached failed build.
- Shows a visible Corso startup screen before loading the coaching workspace.
- Replaces the initial split-view/list dependency with a reliable native iPad
  sidebar and navigation stack.
- Falls back safely if the normal Application Support directory is unavailable.

## 0.1.2 Swift Playgrounds hotfix

- Removed the stray character before the navigation list background modifier
  that prevented `AppShell.swift` from compiling.
- Expanded the destination-symbol switch to conservative Swift syntax for
  compatibility across Swift Playgrounds compiler versions.

## 0.5.2 iPad layout & reusable-program update

- The navigation rail now scales to the actual iPad width in portrait, with a
  protected minimum target size so it never overlaps the workspace.
- Week switching and Ask Corso moved from the top bar to an expandable
  Workspace control at the bottom of the sidebar.
- Each weekly session now shows a short editable **goal** instead of a
  potentially misleading ball-game label; team-game work remains editable in
  the expanded program.
- Coaches can save a custom activity once and reuse it in any later week.
- The Board removes the empty navigation bar, combines its portrait title and
  board selector into one compact row, and gives the canvas the released space.

## 0.5.1 iPad pilot & programming update

- Portrait iPads use a compact navigation rail so the coaching workspace keeps
  most of the screen width.
- Program editing has local undo, editable weekly titles and a concise sprint,
  relay and long-jump drill library informed by the supplied coaching guides.
- Teams now shows a full-width game/relay selector instead of condensed labels.
- The Board starts higher and makes its canvas consume the remaining screen.
- Live student import and race-video use are gated behind visible staff pilot
  checks for device, recordkeeping and parent/carer video permission.
- Local state files use complete file protection and are excluded from device
  cloud backups; export only through the school-approved process.

## 0.5.0 coaching workshop

- Configurable team sizes, position labels and local carnival-rule notes.
- Relay suggestions based on recorded 75m/100m pace; untimed athletes remain
  available for coach judgement.
- Ball-game suggestions based on coach-entered catching, passing, rolling,
  movement, leadership and reliability ratings.
- Program-only sharing between iPads with a destination preview before import.
- Shared program files contain no student, result, attendance or permission data.

## 0.3.0 web-parity scope

- Tappable Today programming card and event workspace navigation.
- Native Teams, Results and Sessions areas matching the web athletics build.
- Editable seven-week programming, completion tracking and current-week controls.
- Student event assignments, permission-slip PDFs and full backup/restore.
- Automatic race divisions, on-device video timing and editable result history.
- Local Ask Corso commands with confirmation, audit history and undo.

## Core pilot scope

- Student register with Year 1–6, derived division, gender, class and faction.
- Guided CSV import for one class or a whole-school file, with preview, duplicate
  detection and invalid-row reporting before records are saved.
- Filterable class result entry with coach/date metadata and fair cohort stars.
- Date-based attendance, automatic past-day locking and explicit unlocking.
- Mutually exclusive Class, Provisional, Interschool and Reserve selection.
- Editable coaches, factions, classes and training schedule.
- Native PencilKit whiteboards with Pencil-only mode, templates, autosave and export.
- Versioned local persistence, atomic writes, file protection and backup recovery.

Records are stored in the protected iPad app container and excluded from device
cloud backups. Coach programs can be shared manually between devices, but the
pilot does not yet live-sync with the web app or another coach's device.

## Run on iPad

1. Install Apple's **Swift Playgrounds** from the App Store.
2. Save and unzip `CorsoAthletics.swiftpm.zip` in Files.
3. Open the `.swiftpm` package in Swift Playgrounds.
4. Tap **Run**.

Minimum target: iPadOS 17.5. Apple Pencil Pro squeeze requires compatible Pencil
and iPad hardware. Other Pencil models still receive PencilKit ink and supported
double-tap behaviour.

## Xcode and TestFlight

Open `CorsoAthletics.swiftpm` in a current Xcode release. Before archiving:

1. Set the Apple Developer team in `Package.swift` or Xcode signing settings.
2. Replace the placeholder app icon.
3. Run the unit tests on an iPad simulator.
4. Run the hardware pilot checklist below.
5. Archive and upload to TestFlight.

## Hardware pilot checklist

- Add, edit and delete a fake student.
- Record sprint and long-jump results, then confirm best-result stars.
- Take today's attendance; unlock, edit and relock a past day.
- Move the fake student from Provisional to Interschool and confirm no duplicate.
- Rename a coach and faction, relaunch and confirm they remain saved.
- Draw a long Pencil stroke, undo/redo, switch tools, squeeze/double-tap if supported,
  close and reopen the board, then export PNG and PDF.
- Force-close and reopen the app; confirm all pilot data remains.
- Delete the fake student.

Do not rely on the app for a live carnival until this checklist passes on the
actual school iPad. Keep paper timing sheets for the first event.
