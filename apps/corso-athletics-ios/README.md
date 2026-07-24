# Corso Athletics for iPad

Corso Athletics is a native iPad companion app that runs alongside Corso Run
Club. It does not replace the Run Club PWA or share its release pipeline.

## Product boundary

- **Corso Run Club:** the existing web app at the repository root.
- **Corso Athletics:** this native SwiftUI/PencilKit app for athletics coaching,
  attendance, results, squad selection and planning.
- The first release is local-first and iPad-only.
- Shared authentication and backend sync are later integration work. They are
  deliberately outside the pilot so the coaching workflows can be stabilised
  first.

## Native feature set

- Today dashboard with a tappable current-session program.
- Class-based CSV import with preview and duplicate checks.
- Student records, squad selection and event assignments.
- Attendance by date with past-day locking.
- Class capture, result history/editing, automatic race divisions and video timing.
- Provisional and interschool team boards with ordering and leaders.
- Configurable team-event sizes, position labels and coaching notes.
- Evidence-based team suggestions using 75m/100m results or coach skill ratings.
- Editable seven-week training program with completion tracking.
- Program-only sharing between coach iPads through AirDrop, Files or an approved school channel.
- Personalised permission-slip PDFs and class-report exports.
- Multi-page PencilKit coaching board.
- Local Ask Corso commands with confirmation, audit history and undo.
- Versioned local persistence plus full JSON backup and restore.

Coach program files contain the seven-week sessions only. They deliberately
exclude students, results, attendance, team boards and permission data. Live
multi-device sync still requires native staff authentication and school-scoped
backend access.

## Open on iPad

The runnable Swift Playgrounds project is:

`CorsoAthletics.swiftpm`

After a successful CI run, download the `Corso-Athletics-Playgrounds` artifact
from the GitHub Actions run, unzip it in Files, then open
`CorsoAthletics.swiftpm` with Swift Playgrounds.

## Apple build gate

The repository workflow generates a temporary Xcode project from `project.yml`,
builds the full application against an iPad simulator SDK, executes the unit
tests, installs the compiled app on an available iPad simulator, launches it and
captures the rendered screen. The generated Xcode project is not committed.

This gate validates Apple's Swift compiler, SwiftUI, UIKit and PencilKit APIs.
It does not create a signed App Store or TestFlight build; signing requires an
Apple Developer team and credentials.
