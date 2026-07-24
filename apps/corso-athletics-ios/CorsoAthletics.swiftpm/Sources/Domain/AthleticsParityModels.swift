import Foundation

enum TeamEvent: String, Codable, CaseIterable, Identifiable, Sendable {
    case passBall = "Pass Ball"
    case tunnelBall = "Tunnel Ball"
    case leaderBall = "Leader Ball"
    case sprintRelay = "Sprint Relay"

    var id: Self { self }

    var athleticsEvent: AthleticsEvent {
        switch self {
        case .passBall:
            return .passBall
        case .tunnelBall:
            return .tunnelBall
        case .leaderBall:
            return .leaderBall
        case .sprintRelay:
            return .sprintRelay
        }
    }

    var guidance: String {
        switch self {
        case .passBall:
            return "Build a clean single-file passing order. Put reliable hands early and a calm finisher last."
        case .tunnelBall:
            return "Build a tight tunnel. Put the strongest accurate roller at the back and quick movers through the middle."
        case .leaderBall:
            return "The leader faces the line and controls the rhythm. Order receivers for clean catches and fast turns."
        case .sprintRelay:
            return "Runner 1 starts, runners 2–3 cover the middle legs, and runner 4 anchors."
        }
    }

    func positionLabel(at index: Int, count: Int, isLeader: Bool) -> String {
        if isLeader { return "Leader" }
        switch self {
        case .passBall:
            return index == count - 1 ? "Finisher" : "Pass \(index + 1)"
        case .tunnelBall:
            return index == count - 1 ? "Roller" : "Tunnel \(index + 1)"
        case .leaderBall:
            return "Receiver \(index + 1)"
        case .sprintRelay:
            switch index {
            case 0: return "Starter"
            case 1: return "Leg 2"
            case 2: return "Leg 3"
            default: return "Anchor"
            }
        }
    }
}

enum TeamSkill: String, Codable, CaseIterable, Identifiable, Sendable {
    case handling = "Catching"
    case passing = "Passing"
    case rolling = "Rolling"
    case movement = "Movement"
    case leadership = "Leadership"
    case reliability = "Reliability"

    var id: Self { self }
}

struct TeamSkillProfile: Codable, Equatable, Sendable {
    var ratings: [String: Int] = [:]

    subscript(skill: TeamSkill) -> Int? {
        get { ratings[skill.rawValue] }
        set {
            if let newValue {
                ratings[skill.rawValue] = min(max(newValue, 1), 5)
            } else {
                ratings.removeValue(forKey: skill.rawValue)
            }
        }
    }

    var assessmentCount: Int {
        TeamSkill.allCases.filter { self[$0] != nil }.count
    }

    mutating func normalize() {
        ratings = ratings.reduce(into: [:]) { output, entry in
            guard TeamSkill(rawValue: entry.key) != nil else { return }
            output[entry.key] = min(max(entry.value, 1), 5)
        }
    }

    func average(for skills: [TeamSkill]) -> Double? {
        let values = skills.compactMap { self[$0] }.map(Double.init)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

struct TeamEventRule: Codable, Equatable, Sendable {
    var teamSize: Int
    var positionLabels: [String]
    var ruleNote: String

    static var defaults: [String: TeamEventRule] {
        Dictionary(uniqueKeysWithValues: TeamEvent.allCases.map { event in
            (event.rawValue, defaultRule(for: event))
        })
    }

    static func defaultRule(for event: TeamEvent) -> TeamEventRule {
        switch event {
        case .passBall:
            return TeamEventRule(
                teamSize: 10,
                positionLabels: ["Starter"] + (2...9).map { "Pass \($0)" } + ["Finisher"],
                ruleNote: "Single-file passing order. Prioritise clean catching, accurate passing and a reliable finish."
            )
        case .tunnelBall:
            return TeamEventRule(
                teamSize: 10,
                positionLabels: ["Front"] + (2...9).map { "Tunnel \($0)" } + ["Roller"],
                ruleNote: "Keep the tunnel compact. Use quick movers through the line and a strong, accurate roller."
            )
        case .leaderBall:
            return TeamEventRule(
                teamSize: 7,
                positionLabels: ["Leader"] + (1...6).map { "Receiver \($0)" },
                ruleNote: "The leader controls the rhythm. Receivers need clean catches, fast turns and dependable returns."
            )
        case .sprintRelay:
            return TeamEventRule(
                teamSize: 4,
                positionLabels: ["Starter", "Leg 2", "Leg 3", "Anchor"],
                ruleNote: "Use 75m and 100m evidence, then adjust for starts, bends, handovers and pressure."
            )
        }
    }

    mutating func normalize(for event: TeamEvent) {
        let fallback = Self.defaultRule(for: event)
        teamSize = min(max(teamSize, 2), 30)
        ruleNote = ruleNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if ruleNote.isEmpty { ruleNote = fallback.ruleNote }

        var labels = positionLabels.compactMap { raw -> String? in
            let label = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return label.isEmpty ? nil : label
        }
        if labels.count < teamSize {
            let fallbackLabels = fallback.positionLabels
            for index in labels.count..<teamSize {
                labels.append(index < fallbackLabels.count ? fallbackLabels[index] : "Position \(index + 1)")
            }
        } else if labels.count > teamSize {
            labels = Array(labels.prefix(teamSize))
        }
        positionLabels = labels
    }

    func positionLabel(at index: Int) -> String {
        positionLabels.indices.contains(index) ? positionLabels[index] : "Position \(index + 1)"
    }
}

enum TeamStage: String, Codable, CaseIterable, Identifiable, Sendable {
    case provisional = "Provisional"
    case interschool = "Interschool"

    var id: Self { self }

    func includes(_ selection: SquadSelection) -> Bool {
        switch self {
        case .provisional:
            return selection == .provisional
        case .interschool:
            return selection == .interschool || selection == .reserve
        }
    }
}

enum TeamPlacement: String, Codable, CaseIterable, Identifiable, Sendable {
    case available = "Available"
    case teamA = "Team A"
    case teamB = "Team B"

    var id: Self { self }
}

struct TeamBoardScope: Codable, Hashable, Identifiable, Sendable {
    var event: TeamEvent
    var stage: TeamStage
    var division: CompetitionDivision
    var gender: AthleteGender?

    var id: String {
        "\(event.rawValue)|\(stage.rawValue.lowercased())|\(division.rawValue)|\(gender?.rawValue ?? "All")"
    }

    init(
        event: TeamEvent,
        stage: TeamStage,
        division: CompetitionDivision,
        gender: AthleteGender? = nil
    ) {
        self.event = event
        self.stage = stage
        self.division = division
        self.gender = gender
    }
}

struct TeamBoard: Codable, Equatable, Sendable {
    var teamA: [UUID] = []
    var teamB: [UUID] = []
    var teamALeader: UUID?
    var teamBLeader: UUID?

    mutating func normalize(validAthleteIDs: Set<UUID>) {
        var seen = Set<UUID>()
        teamA = teamA.filter { validAthleteIDs.contains($0) && seen.insert($0).inserted }
        teamB = teamB.filter { validAthleteIDs.contains($0) && seen.insert($0).inserted }
        if let leader = teamALeader, !teamA.contains(leader) { teamALeader = nil }
        if let leader = teamBLeader, !teamB.contains(leader) { teamBLeader = nil }
        if let teamALeader {
            teamA.moveToFront(teamALeader)
        }
        if let teamBLeader {
            teamB.moveToFront(teamBLeader)
        }
    }
}

struct SessionActivity: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String
    var time: String
    var activity: String
    var detail: String
    var completed = false
}

/// A coach-created activity that can be dropped into any later session. It is
/// deliberately separate from a scheduled activity so completing a session
/// never changes the reusable template.
struct SavedSessionActivity: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: UUID
    var time: String
    var activity: String
    var detail: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        time: String,
        activity: String,
        detail: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.time = time.trimmingCharacters(in: .whitespacesAndNewlines)
        self.activity = activity.trimmingCharacters(in: .whitespacesAndNewlines)
        self.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }

    init(sessionActivity: SessionActivity) {
        self.init(
            time: sessionActivity.time,
            activity: sessionActivity.activity,
            detail: sessionActivity.detail
        )
    }

    var isUsable: Bool {
        !activity.isEmpty || !detail.isEmpty
    }

    func makeSessionActivity() -> SessionActivity {
        SessionActivity(
            id: "saved-\(id.uuidString)-\(UUID().uuidString)",
            time: time,
            activity: activity,
            detail: detail
        )
    }
}

struct TrainingSession: Codable, Equatable, Identifiable, Sendable {
    var week: Int
    var title: String
    var purpose: String
    var outcome: String
    var ballGames: String
    var activities: [SessionActivity]

    var id: Int { week }
}

struct SessionOverride: Codable, Equatable, Sendable {
    var title: String
    var purpose: String
    var outcome: String
    var ballGames: String
    var activities: [SessionActivity]

    init(
        title: String = "",
        purpose: String = "",
        outcome: String = "",
        ballGames: String,
        activities: [SessionActivity]
    ) {
        self.title = title
        self.purpose = purpose
        self.outcome = outcome
        self.ballGames = ballGames
        self.activities = activities
    }

    var isUsable: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !outcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !ballGames.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !activities.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case title, purpose, outcome, ballGames, activities
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        purpose = try values.decodeIfPresent(String.self, forKey: .purpose) ?? ""
        outcome = try values.decodeIfPresent(String.self, forKey: .outcome) ?? ""
        ballGames = try values.decodeIfPresent(String.self, forKey: .ballGames) ?? ""
        activities = try values.decodeIfPresent([SessionActivity].self, forKey: .activities) ?? []
    }
}

enum PermissionSlipKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case provisionalTraining = "Provisional training"
    case interschoolCarnival = "Interschool carnival"

    var id: Self { self }
}

struct PermissionSlipTemplate: Codable, Equatable, Sendable {
    var title: String
    var body: String
    var acknowledgement: String
}

struct PermissionSlipSettings: Codable, Equatable, Sendable {
    var provisionalTraining = PermissionSlipTemplate(
        title: "Provisional Athletics Training Permission",
        body: """
        Your child, {{studentName}}, has been invited to attend provisional athletics training.

        Training details: {{trainingDetails}}

        Please return this form to the school. Contact: {{contactName}} ({{contactDetails}}).
        """,
        acknowledgement: "I give permission for my child to attend provisional athletics training."
    )
    var interschoolCarnival = PermissionSlipTemplate(
        title: "Interschool Athletics Carnival Permission",
        body: """
        Your child, {{studentName}}, has been selected for the interschool athletics carnival.

        Carnival details: {{carnivalDetails}}

        Events: {{studentEvents}}

        Please return this form to the school. Contact: {{contactName}} ({{contactDetails}}).
        """,
        acknowledgement: "I give permission for my child to attend the interschool athletics carnival."
    )
    var trainingDetails = "Thursday, 3:10 pm–4:05 pm, after school"
    var carnivalDetails = ""
    var contactName = ""
    var contactDetails = ""

    subscript(kind: PermissionSlipKind) -> PermissionSlipTemplate {
        get {
            switch kind {
            case .provisionalTraining:
                return provisionalTraining
            case .interschoolCarnival:
                return interschoolCarnival
            }
        }
        set {
            switch kind {
            case .provisionalTraining:
                provisionalTraining = newValue
            case .interschoolCarnival:
                interschoolCarnival = newValue
            }
        }
    }
}

enum AssistantAuditAction: String, Codable, Sendable {
    case result
    case attendance
    case selection
    case team
}

struct AssistantAuditRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var command: String
    var summary: String
    var action: AssistantAuditAction
    var targetIDs: [UUID]
    var addedAt: Date
    var addedBy: String
    var undoneAt: Date?
    var undoneBy: String?
}

enum TrainingProgram {
    static let activityOptions: [String: [String]] = [
        "Briefing": [
            "Roll, expectations and provisional-squad message.",
            "Confirm event groups, session roles and safety reminders.",
            "Quality repetitions only; finish feeling sharp."
        ],
        "Warm-up": [
            "Jog, mobility, marching, skipping and 2 × 20m build-ups.",
            "Mobility, A-march, A-skip, ankling and 2 × 20m build-ups.",
            "Short mobility sequence, drills and 2 × 20m build-ups."
        ],
        "75m / 100m": [
            "Two-point starts, acceleration and running through the line.",
            "4 × 10m reactions, 2 × 20m starts and 2 × 60m quality runs.",
            "One timed 75m; likely 100m runners add one 100m."
        ],
        "200m / 400m": [
            "Years 3–4 controlled 200m; Years 5–6 controlled 400m.",
            "Race-rhythm segment followed by a short finish effort.",
            "Bend running, pacing and one controlled effort with full recovery."
        ],
        "Long jump": [
            "Approach check and two measured jumps.",
            "Four approach run-throughs and three jumps.",
            "Two competition-routine jumps; stop while sharp."
        ],
        "Relays": [
            "Runner order, calls and clean sprint-relay handovers.",
            "Two clean changes and one relay at 90% effort.",
            "Positions, order and two timed sprint-relay attempts."
        ],
        "Team games": [
            "Pass Ball technique, team order and 2–3 timed attempts.",
            "Tunnel Ball technique, rapid reset and 2–3 timed attempts.",
            "Leader Ball roles, clean movement and 2–3 complete attempts."
        ],
        "Review": [
            "Record notes, water and dismissal.",
            "Capture technique priorities and selection notes.",
            "Positive review and carnival reminders."
        ]
    ]

    static let ballGameOptions = [
        "Pass Ball",
        "Tunnel Ball",
        "Leader Ball",
        "Pass Ball + Tunnel Ball",
        "Pass Ball + Leader Ball",
        "Tunnel Ball + Leader Ball",
        "Pass Ball + Tunnel Ball + Leader Ball"
    ]

    static let sessions: [TrainingSession] = [
        session(
            week: 1,
            title: "Baseline & fundamentals",
            purpose: "Identify likely event groups and establish safe, consistent technique.",
            outcome: "Students can show a safe, consistent start and jump approach.",
            ballGames: "Pass Ball",
            rows: [
                ("0–3", "Briefing", "Roll, expectations and provisional-squad message."),
                ("3–10", "Warm-up", "Jog, mobility, tall-posture checks and 2 × 20m build-ups."),
                ("10–20", "75m / 100m", "Two-point starts and one timed 75m; likely 100m runners add one 100m."),
                ("20–30", "200m / 400m", "Years 3–4 controlled 200m; Years 5–6 controlled 400m."),
                ("30–40", "Long jump", "Approach check, safe take-off marker and two measured jumps."),
                ("40–50", "Team games", "Pass Ball accuracy, team order and 2–3 timed attempts."),
                ("50–55", "Review", "Record notes, water and dismissal.")
            ]
        ),
        session(
            week: 2,
            title: "Sprint technique",
            purpose: "Improve reactions, acceleration, relaxed speed and running through the line.",
            outcome: "Students can accelerate smoothly and run through the finish line.",
            ballGames: "Tunnel Ball",
            rows: [
                ("0–3", "Briefing", "Fast starts, relaxed arms, finish beyond the line."),
                ("3–10", "Warm-up", "Mobility, A-march, A-skip, tall-posture checks and 2 × 20m build-ups."),
                ("10–20", "75m / 100m", "Wall-drive shapes, then 4 × 10m reactions and 2 × 20m whistle starts."),
                ("20–30", "75m / 100m", "3 × 30m with a strong forward drive; stand tall gradually rather than popping up."),
                ("30–40", "75m / 100m", "3 × 40–50m with a run-through cone beyond the finish."),
                ("40–50", "Team games", "Tunnel Ball technique, rapid reset and 2–3 timed attempts."),
                ("50–55", "Review", "Praise one technique win and record changes.")
            ]
        ),
        session(
            week: 3,
            title: "200m, 400m & long jump",
            purpose: "Develop race rhythm and a repeatable long-jump approach.",
            outcome: "Students can hold their rhythm and use a repeatable take-off mark.",
            ballGames: "Leader Ball",
            rows: [
                ("0–3", "Briefing", "Pace early, finish strongly, jump with control."),
                ("3–10", "Warm-up", "Jog, mobility, skips and 2 × 30m build-ups."),
                ("10–20", "200m / 400m", "Bend running, 120m at race rhythm and one controlled 200m effort."),
                ("20–30", "200m / 400m", "2 × 150–200m at controlled rhythm with full recovery."),
                ("30–40", "Long jump", "Six-step approach run-throughs, then three controlled jumps with a safe landing."),
                ("40–50", "Team games", "Leader Ball roles, clean movement and 2–3 complete attempts."),
                ("50–55", "Review", "Capture pacing and take-off notes.")
            ]
        ),
        session(
            week: 4,
            title: "Individual-event rehearsal",
            purpose: "Sharpen Week 5 events without creating fatigue.",
            outcome: "Students can rehearse their event routine with confidence.",
            ballGames: "Pass Ball + Tunnel Ball",
            rows: [
                ("0–3", "Briefing", "Quality repetitions only; competition is next week."),
                ("3–10", "Warm-up", "Mobility, stride-rhythm markers and 2 × 20m build-ups."),
                ("10–20", "200m / 400m", "One 120–150m rhythm run and one 60m finish."),
                ("20–30", "200m / 400m", "One controlled 200m and one 100m finish."),
                ("30–40", "Long jump", "Approach-accuracy run-throughs, then three full-quality jumps from a confirmed mark."),
                ("40–50", "Team games", "Five minutes each: one clean run, then timed attempts."),
                ("50–55", "Review", "Confirm race plan and jump approach.")
            ]
        ),
        session(
            week: 5,
            title: "Main-carnival preparation",
            purpose: "Prepare sprints, relays and team games after the individual events.",
            outcome: "Students can complete clean relay changes and recover from team-game errors.",
            ballGames: "Leader Ball + Sprint Relay",
            rows: [
                ("0–3", "Briefing", "Reduce workload for students tired from individual events."),
                ("3–10", "Warm-up", "Easy jog, movement preparation and 2 × 20m build-ups."),
                ("10–20", "75m / 100m", "2 × 30m starts and 2 × 60m quality efforts."),
                ("20–30", "Relays", "Set spacing and a clear call, then rehearse clean exchanges before one 90% relay."),
                ("30–40", "Team games", "Pass Ball and Tunnel Ball error-recovery practice."),
                ("40–50", "Team games", "Leader Ball positions, order and two timed attempts."),
                ("50–55", "Review", "Confirm carnival roles and reserves.")
            ]
        ),
        session(
            week: 7,
            title: "Interschool squad",
            purpose: "Target the confirmed event groups using school-carnival results.",
            outcome: "Athletes can apply one clear technical priority in their event.",
            ballGames: "Pass Ball + weakest team game",
            rows: [
                ("0–5", "Briefing", "Confirm events, reserves and session groups."),
                ("5–12", "Warm-up", "Mobility, sprint drills and build-up runs."),
                ("12–22", "Relays", "3 × 30m starts, exchange-zone rehearsal and one 90% relay."),
                ("22–32", "200m / 400m", "Race-rhythm segment followed by a short finish effort."),
                ("32–42", "Long jump", "Three competition-routine jumps from a repeatable start mark; stop while technique is sharp."),
                ("42–52", "Team games", "Pass Ball plus the game needing most improvement."),
                ("52–55", "Review", "Record final technical priorities.")
            ]
        ),
        session(
            week: 8,
            title: "Final rehearsal & taper",
            purpose: "Leave students organised, quick and confident for Week 9.",
            outcome: "Athletes leave organised, fresh and confident for interschool.",
            ballGames: "Pass Ball + Tunnel Ball + Leader Ball",
            rows: [
                ("0–5", "Briefing", "Final roles, equipment and competition expectations."),
                ("5–12", "Warm-up", "Short mobility sequence, tall running drills and 2 × 20m build-ups."),
                ("12–22", "Relays", "One 30m start, one 60m run and two clean exchange-zone changes."),
                ("22–32", "200m / 400m", "One short race-rhythm effort only—no full race."),
                ("32–42", "Long jump", "Two quality jumps; stop while sharp."),
                ("42–50", "Team games", "Brief clean rehearsals of each team event."),
                ("50–55", "Review", "Positive review and interschool reminders.")
            ]
        )
    ]

    static func session(for week: Int, overrides: [Int: SessionOverride]) -> TrainingSession? {
        guard let base = sessions.first(where: { $0.week == week }) else { return nil }
        guard let override = overrides[week] else { return base }
        return TrainingSession(
            week: base.week,
            title: override.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? base.title : override.title,
            purpose: override.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? base.purpose : override.purpose,
            outcome: override.outcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? base.outcome : override.outcome,
            ballGames: override.ballGames.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? base.ballGames : override.ballGames,
            activities: override.activities.isEmpty ? base.activities : override.activities
        )
    }

    private static func session(
        week: Int,
        title: String,
        purpose: String,
        outcome: String,
        ballGames: String,
        rows: [(String, String, String)]
    ) -> TrainingSession {
        TrainingSession(
            week: week,
            title: title,
            purpose: purpose,
            outcome: outcome,
            ballGames: ballGames,
            activities: rows.enumerated().map { index, row in
                SessionActivity(
                    id: "week-\(week)-activity-\(index + 1)",
                    time: row.0,
                    activity: row.1,
                    detail: row.2
                )
            }
        )
    }
}

extension Array where Element == UUID {
    mutating func moveToFront(_ id: UUID) {
        guard let index = firstIndex(of: id), index != startIndex else { return }
        remove(at: index)
        insert(id, at: startIndex)
    }
}
