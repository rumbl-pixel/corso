import Foundation

struct CoachProgramSharePayload: Codable, Equatable, Identifiable, Sendable {
    static let currentSchemaVersion = 2

    var id: UUID
    var schemaVersion: Int
    var exportedAt: Date
    var schoolName: String
    var termLabel: String
    var sourceCoachName: String
    var sessions: [Int: SessionOverride]

    init(
        id: UUID = UUID(),
        schemaVersion: Int = currentSchemaVersion,
        exportedAt: Date = .now,
        schoolName: String,
        termLabel: String,
        sourceCoachName: String,
        sessions: [Int: SessionOverride]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.schoolName = schoolName
        self.termLabel = termLabel
        self.sourceCoachName = sourceCoachName
        self.sessions = sessions
    }
}

enum CoachProgramSharingError: LocalizedError {
    case noProgram
    case unreadable
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .noProgram:
            return "That file does not contain a usable Corso training program."
        case .unreadable:
            return "That file is not a readable Corso coach-program file."
        case .unsupportedSchema(let schema):
            return "This coach program was made by a newer Corso version (schema \(schema)). Update Corso before importing it."
        }
    }
}

enum CoachProgramSharing {
    static func export(
        state: AthleticsState,
        coachID: UUID?
    ) throws -> URL {
        let sourceOverrides: [Int: SessionOverride]
        let sourceCoachName: String
        if state.settings.coachProgramsAreShared {
            sourceOverrides = state.sessionOverrides
            sourceCoachName = "Shared program"
        } else {
            guard let coachID,
                  let coach = state.settings.coaches.first(where: { $0.id == coachID })
            else { throw CoachProgramSharingError.noProgram }
            sourceOverrides = state.coachSessionOverrides[coachID] ?? [:]
            sourceCoachName = coach.name
        }

        let sessions = TrainingProgram.sessions.reduce(into: [Int: SessionOverride]()) { output, base in
            guard let resolved = TrainingProgram.session(for: base.week, overrides: sourceOverrides) else { return }
            output[base.week] = SessionOverride(
                title: resolved.title,
                purpose: resolved.purpose,
                outcome: resolved.outcome,
                ballGames: resolved.ballGames,
                activities: resolved.activities
            )
        }
        guard !sessions.isEmpty else { throw CoachProgramSharingError.noProgram }

        let payload = CoachProgramSharePayload(
            schoolName: state.settings.schoolName,
            termLabel: state.settings.termLabel,
            sourceCoachName: sourceCoachName,
            sessions: sessions
        )
        let data = try makeEncoder().encode(payload)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corso-Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeCoach = sourceCoachName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .prefix(40)
        let name = safeCoach.isEmpty ? "coach" : String(safeCoach)
        let url = directory.appendingPathComponent(
            "corso-program-\(name)-\(Date.now.attendanceKey).json"
        )
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func read(from url: URL) throws -> CoachProgramSharePayload {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        guard var payload = try? makeDecoder().decode(CoachProgramSharePayload.self, from: data) else {
            throw CoachProgramSharingError.unreadable
        }
        guard payload.schemaVersion <= CoachProgramSharePayload.currentSchemaVersion else {
            throw CoachProgramSharingError.unsupportedSchema(payload.schemaVersion)
        }
        let validWeeks = Set(TrainingProgram.sessions.map(\.week))
        payload.sessions = payload.sessions.filter { week, session in
            validWeeks.contains(week) && session.isUsable
        }
        guard !payload.sessions.isEmpty else { throw CoachProgramSharingError.noProgram }
        return payload
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

struct CoachProgramShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}
