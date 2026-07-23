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

## Open on iPad

The runnable Swift Playgrounds project is:

`CorsoAthletics.swiftpm`

After a successful CI run, download the `Corso-Athletics-Playgrounds` artifact
from the GitHub Actions run, unzip it in Files, then open
`CorsoAthletics.swiftpm` with Swift Playgrounds.

## Apple build gate

The repository workflow generates a temporary Xcode project from `project.yml`,
builds the full application against an iPad simulator SDK and executes the unit
tests on an available iPad simulator. The generated Xcode project is not
committed.

This gate validates Apple's Swift compiler, SwiftUI, UIKit and PencilKit APIs.
It does not create a signed App Store or TestFlight build; signing requires an
Apple Developer team and credentials.
