import Foundation

/// Short, school-ready prompts for the program editor. These are original
/// summaries of the supplied sprint, relay and horizontal-jump material; the
/// app does not reproduce or distribute the source guides.
struct SessionDrillTemplate: Hashable, Identifiable, Sendable {
    let id: String
    let category: String
    let time: String
    let activity: String
    let detail: String

    var sessionActivity: SessionActivity {
        SessionActivity(id: "library-\(id)-\(UUID().uuidString)", time: time, activity: activity, detail: detail)
    }
}

enum SessionDrillLibrary {
    static let templates: [SessionDrillTemplate] = [
        .init(
            id: "posture-build-ups",
            category: "Sprint fundamentals",
            time: "5–7",
            activity: "Tall posture & build-ups",
            detail: "Check relaxed shoulders and tall hips, then complete two short progressive runs. Stop and reset technique before adding speed."
        ),
        .init(
            id: "wall-drive",
            category: "Sprint fundamentals",
            time: "5–8",
            activity: "Wall drive & 10m starts",
            detail: "Use a wall or fence to practise a strong forward body line and quick first steps, then transfer it to short two-point starts."
        ),
        .init(
            id: "stride-rhythm",
            category: "Sprint fundamentals",
            time: "5–8",
            activity: "Stride rhythm markers",
            detail: "Run through low, safe markers or cones with quick contacts. Keep the stride natural; do not reach or overstride to clear a marker."
        ),
        .init(
            id: "bend-rhythm",
            category: "200m / 400m",
            time: "6–8",
            activity: "Bend-to-straight rhythm",
            detail: "Use a controlled curve entry and a relaxed drive into the straight. Keep one effort submaximal and allow full recovery."
        ),
        .init(
            id: "relay-spacing",
            category: "Relay",
            time: "6–8",
            activity: "Relay spacing & calls",
            detail: "Set a consistent outgoing position, use one clear call, and rehearse the approach before adding a baton handover."
        ),
        .init(
            id: "relay-exchange",
            category: "Relay",
            time: "6–8",
            activity: "Exchange-zone rehearsal",
            detail: "Build speed first, then practise a clean handover in the marked exchange space. Use quality changes only; reset after an unsafe or messy attempt."
        ),
        .init(
            id: "six-step-approach",
            category: "Long jump",
            time: "6–8",
            activity: "Six-step approach drive",
            detail: "Start from a repeatable six-step mark, drive forward for the first steps, then arrive tall and balanced at take-off."
        ),
        .init(
            id: "takeoff-accuracy",
            category: "Long jump",
            time: "6–8",
            activity: "Approach accuracy run-through",
            detail: "Practise arriving close to a safe take-off marker with a consistent approach. Score control and accuracy rather than jump distance."
        ),
        .init(
            id: "landing-shape",
            category: "Long jump",
            time: "5–7",
            activity: "Safe landing shape",
            detail: "From a short approach, practise extending feet forward and landing with control in the pit. Keep repetitions low and quality high."
        )
    ]

    static var categories: [String] {
        Array(Set(templates.map(\.category))).sorted()
    }

    static func templates(in category: String) -> [SessionDrillTemplate] {
        templates.filter { $0.category == category }
    }
}
