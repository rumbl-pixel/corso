import Foundation

enum AttendanceStatus: String, Codable, CaseIterable, Sendable {
    case present
    case late
    case absent
    case unmarked
}

enum AthleteGender: String, Codable, CaseIterable, Identifiable, Sendable {
    case boys = "Boys"
    case girls = "Girls"
    case unspecified = "Unspecified"

    var id: Self { self }
}

enum CompetitionDivision: String, Codable, CaseIterable, Identifiable, Sendable {
    case junior = "Junior"
    case intermediate = "Intermediate"
    case senior = "Senior"

    var id: Self { self }

    static func forYear(_ year: Int) -> Self {
        switch year {
        case ...2:
            return .junior
        case 3...4:
            return .intermediate
        default:
            return .senior
        }
    }
}

/// A student has exactly one selection state. This deliberately prevents a
/// student being in both the provisional and interschool squads.
enum SquadSelection: String, Codable, CaseIterable, Identifiable, Sendable {
    case classOnly = "Class only"
    case provisional = "Provisional"
    case interschool = "Interschool"
    case reserve = "Reserve"

    var id: Self { self }
}

enum AthleticsEvent: String, Codable, CaseIterable, Identifiable, Sendable {
    case sprint75 = "75m"
    case sprint100 = "100m"
    case sprint200 = "200m"
    case sprint400 = "400m"
    case longJump = "Long Jump"
    case passBall = "Pass Ball"
    case tunnelBall = "Tunnel Ball"
    case leaderBall = "Leader Ball"
    case sprintRelay = "Sprint Relay"

    var id: Self { self }
    var isTimed: Bool { self != .longJump }
    var resultUnit: ResultUnit { isTimed ? .seconds : .metres }
    var isTeamEvent: Bool {
        switch self {
        case .passBall, .tunnelBall, .leaderBall, .sprintRelay:
            return true
        default:
            return false
        }
    }

    static let individualEvents: [Self] = [
        .sprint75, .sprint100, .sprint200, .sprint400, .longJump
    ]
}

enum ResultUnit: String, Codable, CaseIterable, Sendable {
    case seconds
    case metres
}

enum ResultSource: String, Codable, CaseIterable, Sendable {
    case classLesson
    case training
    case carnival
    case videoReview
    case importFile
    case unknown
}

struct Athlete: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var year: Int
    var gender: AthleteGender
    var faction: String
    var className: String
    var selection: SquadSelection
    var events: [AthleticsEvent]
    /// Keys are stable local calendar dates in yyyy-MM-dd format.
    var attendance: [String: AttendanceStatus]

    var division: CompetitionDivision { .forYear(year) }

    init(
        id: UUID = UUID(),
        name: String,
        year: Int,
        gender: AthleteGender,
        faction: String,
        className: String,
        selection: SquadSelection = .classOnly,
        events: [AthleticsEvent] = [],
        attendance: [String: AttendanceStatus] = [:]
    ) {
        self.id = id
        self.name = name.studentField(or: "Unnamed Student")
        self.year = min(max(year, 1), 6)
        self.gender = gender
        self.faction = faction.studentField(or: "Unassigned")
        self.className = className.studentField(or: "Unassigned")
        self.selection = selection
        self.events = Array(Set(events)).sorted { $0.rawValue < $1.rawValue }
        self.attendance = attendance.filter { Date.isAttendanceKey($0.key) && $0.value != .unmarked }
    }

    mutating func normalize() {
        name = name.studentField(or: "Unnamed Student")
        year = min(max(year, 1), 6)
        faction = faction.studentField(or: "Unassigned")
        className = className.studentField(or: "Unassigned")
        events = Array(Set(events)).sorted { $0.rawValue < $1.rawValue }
        attendance = attendance.filter { Date.isAttendanceKey($0.key) && $0.value != .unmarked }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, year, yearGroup, gender, division, faction, className
        case legacyClass = "class"
        case selection, squadStatus, events, attendance
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "Unnamed Student"
        if let numericYear = try? values.decode(Int.self, forKey: .year) {
            year = numericYear
        } else if let numericYear = try? values.decode(Int.self, forKey: .yearGroup) {
            year = numericYear
        } else {
            let text = (try? values.decode(String.self, forKey: .year))
                ?? (try? values.decode(String.self, forKey: .yearGroup))
            year = text?.firstMatchInteger ?? 1
        }
        gender = (try? values.decode(AthleteGender.self, forKey: .gender))
            ?? (try? values.decode(AthleteGender.self, forKey: .division))
            ?? .unspecified
        faction = try values.decodeIfPresent(String.self, forKey: .faction) ?? "Unassigned"
        let currentClass = try values.decodeIfPresent(String.self, forKey: .className)
        let legacyClass = try values.decodeIfPresent(String.self, forKey: .legacyClass)
        className = currentClass ?? legacyClass ?? "Unassigned"
        selection = (try? values.decode(SquadSelection.self, forKey: .selection))
            ?? (try? values.decode(SquadSelection.self, forKey: .squadStatus))
            ?? .classOnly
        events = try values.decodeIfPresent([AthleticsEvent].self, forKey: .events) ?? []
        attendance = try values.decodeIfPresent([String: AttendanceStatus].self, forKey: .attendance) ?? [:]
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(year, forKey: .year)
        try values.encode(gender, forKey: .gender)
        try values.encode(faction, forKey: .faction)
        try values.encode(className, forKey: .className)
        try values.encode(selection, forKey: .selection)
        try values.encode(events, forKey: .events)
        try values.encode(attendance, forKey: .attendance)
    }
}

struct ResultRecord: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var athleteID: UUID
    var event: AthleticsEvent
    var value: Double
    var date: Date
    var effort: Int?
    var note: String
    var addedAt: Date
    var updatedAt: Date
    var addedBy: String
    var coachID: UUID?
    var unit: ResultUnit
    var source: ResultSource

    var isValid: Bool { value.isFinite && value > 0 }

    init(
        id: UUID = UUID(),
        athleteID: UUID,
        event: AthleticsEvent,
        value: Double,
        date: Date = .now,
        effort: Int? = nil,
        note: String = "",
        addedAt: Date = .now,
        updatedAt: Date? = nil,
        addedBy: String,
        coachID: UUID? = nil,
        unit: ResultUnit? = nil,
        source: ResultSource = .unknown
    ) {
        self.id = id
        self.athleteID = athleteID
        self.event = event
        self.value = value
        self.date = date
        self.effort = effort.map { min(max($0, 1), 5) }
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.addedAt = addedAt
        self.updatedAt = updatedAt ?? addedAt
        self.addedBy = addedBy.studentField(or: "Unknown coach")
        self.coachID = coachID
        self.unit = unit ?? event.resultUnit
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, athleteID, event, value, date, effort, note, addedAt, updatedAt
        case addedBy, coachID, unit, source
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        athleteID = try values.decode(UUID.self, forKey: .athleteID)
        event = try values.decode(AthleticsEvent.self, forKey: .event)
        value = try values.decode(Double.self, forKey: .value)
        date = try values.decodeIfPresent(Date.self, forKey: .date) ?? .now
        effort = try values.decodeIfPresent(Int.self, forKey: .effort).map { min(max($0, 1), 5) }
        note = try values.decodeIfPresent(String.self, forKey: .note) ?? ""
        addedAt = try values.decodeIfPresent(Date.self, forKey: .addedAt) ?? date
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? addedAt
        addedBy = (try values.decodeIfPresent(String.self, forKey: .addedBy) ?? "Unknown coach")
            .studentField(or: "Unknown coach")
        coachID = try values.decodeIfPresent(UUID.self, forKey: .coachID)
        unit = try values.decodeIfPresent(ResultUnit.self, forKey: .unit) ?? event.resultUnit
        source = try values.decodeIfPresent(ResultSource.self, forKey: .source) ?? .unknown
    }
}

struct Coach: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        // Draft settings must be allowed to remain blank while the user types.
        // ProgramSettings.normalize() removes blank coaches at commit time.
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ProgramSettings: Codable, Equatable, Sendable {
    var schoolName = "Corso Athletics"
    var termLabel = "Term 3"
    var trainingDay = "Thursday"
    var sessionStart = "15:10"
    var sessionEnd = "16:05"
    var factions = ["Unassigned", "Red", "Blue", "Yellow", "Green"]
    var classes = ["Unassigned"]
    var coaches = [Coach(name: "Coach 1")]

    mutating func normalize() {
        schoolName = schoolName.studentField(or: "Corso Athletics")
        termLabel = termLabel.studentField(or: "Term 3")
        trainingDay = trainingDay.studentField(or: "Thursday")
        sessionStart = Self.validTime(sessionStart) ? sessionStart : "15:10"
        sessionEnd = Self.validTime(sessionEnd) ? sessionEnd : "16:05"
        factions = Self.uniqueFields(factions, fallback: ["Unassigned", "Red", "Blue", "Yellow", "Green"])
        classes = Self.uniqueFields(classes, fallback: ["Unassigned"])

        var seen = Set<UUID>()
        coaches = coaches.compactMap { coach in
            let name = coach.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(coach.id).inserted else { return nil }
            return Coach(id: coach.id, name: name)
        }
        if coaches.isEmpty { coaches = [Coach(name: "Coach 1")] }
    }

    private static func validTime(_ value: String) -> Bool {
        let parts = value.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return false }
        return (0...23).contains(hour) && (0...59).contains(minute)
    }

    private static func uniqueFields(_ values: [String], fallback: [String]) -> [String] {
        var seen = Set<String>()
        let cleaned = values.compactMap { raw -> String? in
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, seen.insert(value.lowercased()).inserted else { return nil }
            return value
        }
        return cleaned.isEmpty ? fallback : cleaned
    }

    private enum CodingKeys: String, CodingKey {
        case schoolName, termLabel, trainingDay, sessionStart, sessionEnd, factions, classes, coaches
        case trainingTime
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName) ?? "Corso Athletics"
        termLabel = try values.decodeIfPresent(String.self, forKey: .termLabel) ?? "Term 3"
        trainingDay = try values.decodeIfPresent(String.self, forKey: .trainingDay) ?? "Thursday"
        sessionStart = try values.decodeIfPresent(String.self, forKey: .sessionStart) ?? "15:10"
        sessionEnd = try values.decodeIfPresent(String.self, forKey: .sessionEnd) ?? "16:05"

        // Early web/native prototypes stored the schedule as "15:10–16:05".
        if let legacyTime = try values.decodeIfPresent(String.self, forKey: .trainingTime) {
            let parts = legacyTime.components(separatedBy: CharacterSet(charactersIn: "-–—"))
            if parts.count >= 2 {
                sessionStart = parts[0].trimmingCharacters(in: .whitespaces)
                sessionEnd = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        factions = try values.decodeIfPresent([String].self, forKey: .factions)
            ?? ["Unassigned", "Red", "Blue", "Yellow", "Green"]
        classes = try values.decodeIfPresent([String].self, forKey: .classes) ?? ["Unassigned"]
        coaches = try values.decodeIfPresent([Coach].self, forKey: .coaches) ?? [Coach(name: "Coach 1")]
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolName, forKey: .schoolName)
        try values.encode(termLabel, forKey: .termLabel)
        try values.encode(trainingDay, forKey: .trainingDay)
        try values.encode(sessionStart, forKey: .sessionStart)
        try values.encode(sessionEnd, forKey: .sessionEnd)
        try values.encode(factions, forKey: .factions)
        try values.encode(classes, forKey: .classes)
        try values.encode(coaches, forKey: .coaches)
    }
}

struct AthleticsState: Codable, Equatable, Sendable {
    var athletes: [Athlete] = []
    var results: [ResultRecord] = []
    var settings = ProgramSettings()
    var currentWeek = 1
    var sessionOverrides: [Int: SessionOverride] = [:]
    var teamBoards: [String: TeamBoard] = [:]
    var assistantAudit: [AssistantAuditRecord] = []
    var permissionSlips = PermissionSlipSettings()
    /// Past dates are locked by default. Only explicitly unlocked keys appear here.
    var unlockedAttendanceDates: Set<String> = []

    static let empty = AthleticsState()

    mutating func normalize() {
        settings.normalize()
        currentWeek = min(max(currentWeek, 1), 9)
        unlockedAttendanceDates = Set(unlockedAttendanceDates.filter(Date.isAttendanceKey))

        var studentIDs = Set<UUID>()
        athletes = athletes.compactMap { athlete in
            guard studentIDs.insert(athlete.id).inserted else { return nil }
            var copy = athlete
            copy.normalize()
            return copy
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        var resultIDs = Set<UUID>()
        results = results.filter {
            studentIDs.contains($0.athleteID) && $0.isValid && resultIDs.insert($0.id).inserted
        }

        let validSessionWeeks = Set(TrainingProgram.sessions.map(\.week))
        sessionOverrides = sessionOverrides.filter { week, value in
            validSessionWeeks.contains(week)
                && !value.ballGames.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !value.activities.isEmpty
        }

        teamBoards = teamBoards.reduce(into: [:]) { output, entry in
            var board = entry.value
            board.normalize(validAthleteIDs: studentIDs)
            output[entry.key] = board
        }
    }

    func isAttendanceLocked(on date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        return day < today && !unlockedAttendanceDates.contains(date.attendanceKey(calendar: calendar))
    }

    private enum CodingKeys: String, CodingKey {
        case athletes, students, results, settings, currentWeek, sessionOverrides
        case teamBoards, assistantAudit, permissionSlips, unlockedAttendanceDates
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let currentAthletes = try values.decodeIfPresent([Athlete].self, forKey: .athletes)
        let legacyStudents = try values.decodeIfPresent([Athlete].self, forKey: .students)
        athletes = currentAthletes ?? legacyStudents ?? []
        results = try values.decodeIfPresent([ResultRecord].self, forKey: .results) ?? []
        settings = try values.decodeIfPresent(ProgramSettings.self, forKey: .settings) ?? ProgramSettings()
        currentWeek = try values.decodeIfPresent(Int.self, forKey: .currentWeek) ?? 1
        sessionOverrides = try values.decodeIfPresent([Int: SessionOverride].self, forKey: .sessionOverrides) ?? [:]
        teamBoards = try values.decodeIfPresent([String: TeamBoard].self, forKey: .teamBoards) ?? [:]
        assistantAudit = try values.decodeIfPresent([AssistantAuditRecord].self, forKey: .assistantAudit) ?? []
        permissionSlips = try values.decodeIfPresent(PermissionSlipSettings.self, forKey: .permissionSlips)
            ?? PermissionSlipSettings()
        unlockedAttendanceDates = try values.decodeIfPresent(Set<String>.self, forKey: .unlockedAttendanceDates) ?? []
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(athletes, forKey: .athletes)
        try values.encode(results, forKey: .results)
        try values.encode(settings, forKey: .settings)
        try values.encode(currentWeek, forKey: .currentWeek)
        try values.encode(sessionOverrides, forKey: .sessionOverrides)
        try values.encode(teamBoards, forKey: .teamBoards)
        try values.encode(assistantAudit, forKey: .assistantAudit)
        try values.encode(permissionSlips, forKey: .permissionSlips)
        try values.encode(unlockedAttendanceDates, forKey: .unlockedAttendanceDates)
    }
}

extension Date {
    var attendanceKey: String { attendanceKey(calendar: .current) }

    func attendanceKey(calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func isAttendanceKey(_ value: String) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return false }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        return roundTrip.year == year && roundTrip.month == month && roundTrip.day == day
    }
}

private extension String {
    func studentField(or fallback: String) -> String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? fallback : cleaned
    }

    var firstMatchInteger: Int? {
        split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.first
    }
}
