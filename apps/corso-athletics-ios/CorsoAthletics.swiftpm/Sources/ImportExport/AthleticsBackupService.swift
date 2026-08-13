import Foundation
import SwiftUI
import UIKit

struct AthleticsBackupPayload: Codable, Sendable {
    static let currentSchemaVersion = 6

    var schemaVersion: Int
    var exportedAt: Date
    var state: AthleticsState
}

enum AthleticsBackupError: LocalizedError {
    case unsupportedSchema(Int)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            return "This backup was made by a newer Corso version (schema \(version)). Update the app before restoring it."
        case .unreadable:
            return "That file is not a readable Corso Athletics backup."
        }
    }
}

enum AthleticsBackupService {
    static func export(_ state: AthleticsState) throws -> URL {
        var normalized = state
        normalized.normalize()
        let payload = AthleticsBackupPayload(
            schemaVersion: AthleticsBackupPayload.currentSchemaVersion,
            exportedAt: .now,
            state: normalized
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corso-Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(
            "corso-athletics-backup-\(Date.now.attendanceKey).json"
        )
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func restore(from url: URL) throws -> AthleticsBackupPayload {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let payload = try? decoder.decode(AthleticsBackupPayload.self, from: data) {
            guard payload.schemaVersion <= AthleticsBackupPayload.currentSchemaVersion else {
                throw AthleticsBackupError.unsupportedSchema(payload.schemaVersion)
            }
            var payload = payload
            payload.state.normalize()
            return payload
        }

        // Version 15 of the web app exported { exportedAt, data }. Convert that
        // document before trying the permissive legacy-state decoder. A web
        // envelope has no root-level AthleticsState fields, so that decoder can
        // otherwise accept it as an empty workspace and silently discard data.
        if let web = try? decoder.decode(WebBackupEnvelope.self, from: data) {
            return AthleticsBackupPayload(
                schemaVersion: 2,
                exportedAt: web.exportedAt ?? .now,
                state: web.data.nativeState
            )
        }

        // The original web/native pilot exported the state as the JSON root.
        if var legacy = try? decoder.decode(AthleticsState.self, from: data) {
            legacy.normalize()
            return AthleticsBackupPayload(
                schemaVersion: 1,
                exportedAt: .now,
                state: legacy
            )
        }

        throw AthleticsBackupError.unreadable
    }
}

private struct WebBackupEnvelope: Decodable {
    var exportedAt: Date?
    var data: WebAthleticsState
}

private struct WebAthleticsState: Decodable {
    var athletes: [WebAthlete] = []
    var results: [WebResult] = []
    var assistantAudit: [WebAudit] = []
    var currentWeek = 1
    var sessionOverrides: [String: WebSessionOverride] = [:]
    var teamBoards: [String: WebTeamBoard] = [:]
    var settings = WebSettings()

    var nativeState: AthleticsState {
        let nativeAthletes = athletes.map(\.native)
        let validIDs = Set(nativeAthletes.map(\.id))
        var state = AthleticsState()
        state.athletes = nativeAthletes
        state.results = results.compactMap { $0.native(validAthleteIDs: validIDs) }
        state.assistantAudit = assistantAudit.map(\.native)
        state.currentWeek = currentWeek
        state.sessionOverrides = sessionOverrides.reduce(into: [:]) { output, entry in
            guard let week = Int(entry.key) else { return }
            output[week] = entry.value.native(week: week)
        }
        state.teamBoards = teamBoards.mapValues(\.native)
        state.settings = settings.native
        state.normalize()
        return state
    }
}

private struct WebAthlete: Decodable {
    var id: UUID
    var name: String
    var year: Int
    var faction: String
    var className: String
    var events: [AthleticsEvent]?
    var selection: String
    var gender: AthleteGender
    var attendance: [String: AttendanceStatus]

    var native: Athlete {
        Athlete(
            id: id,
            name: name,
            year: year,
            gender: gender,
            faction: faction,
            className: className,
            selection: {
                switch selection.lowercased() {
                case "confirmed", "interschool": return .interschool
                case "reserve": return .reserve
                case "provisional": return .provisional
                default: return .classOnly
                }
            }(),
            events: events ?? [],
            attendance: Dictionary(uniqueKeysWithValues: attendance.compactMap { key, value in
                let nativeKey = key.hasPrefix("date-") ? String(key.dropFirst(5)) : key
                return Date.isAttendanceKey(nativeKey) ? (nativeKey, value) : nil
            })
        )
    }
}

private struct WebResult: Decodable {
    var id: UUID
    var athleteId: UUID
    var event: AthleticsEvent
    var result: String
    var date: String
    var note: String
    var addedAt: Date
    var addedBy: String
    var effort: Int?

    func native(validAthleteIDs: Set<UUID>) -> ResultRecord? {
        guard validAthleteIDs.contains(athleteId),
              let range = result.range(of: #"\d+(?:[.,]\d+)?"#, options: .regularExpression),
              let value = Double(result[range].replacingOccurrences(of: ",", with: "."))
        else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return ResultRecord(
            id: id,
            athleteID: athleteId,
            event: event,
            value: value,
            date: formatter.date(from: date) ?? addedAt,
            effort: effort,
            note: note,
            addedAt: addedAt,
            addedBy: addedBy,
            source: .importFile
        )
    }
}

private struct WebSessionActivity: Decodable {
    var time: String
    var activity: String
    var detail: String
    var completed: Bool?
}

private struct WebSessionOverride: Decodable {
    var ballGames: String
    var activities: [WebSessionActivity]

    func native(week: Int) -> SessionOverride {
        SessionOverride(
            title: "",
            purpose: "",
            ballGames: ballGames,
            activities: activities.enumerated().map { index, activity in
                SessionActivity(
                    id: "week-\(week)-activity-\(index + 1)",
                    time: activity.time,
                    activity: activity.activity,
                    detail: activity.detail,
                    completed: activity.completed ?? false
                )
            }
        )
    }
}

private struct WebTeamBoard: Decodable {
    var teamA: [UUID] = []
    var teamB: [UUID] = []
    var teamALeader: UUID?
    var teamBLeader: UUID?

    var native: TeamBoard {
        TeamBoard(
            teamA: teamA,
            teamB: teamB,
            teamALeader: teamALeader,
            teamBLeader: teamBLeader
        )
    }
}

private struct WebAudit: Decodable {
    var id: UUID
    var command: String
    var summary: String
    var action: AssistantAuditAction
    var targetIds: [UUID]
    var addedAt: Date
    var addedBy: String
    var undoneAt: Date?
    var undoneBy: String?

    var native: AssistantAuditRecord {
        AssistantAuditRecord(
            id: id,
            command: command,
            summary: summary,
            action: action,
            targetIDs: targetIds,
            addedAt: addedAt,
            addedBy: addedBy,
            undoneAt: undoneAt,
            undoneBy: undoneBy
        )
    }
}

private struct WebCoach: Decodable {
    var name: String
}

private struct WebSettings: Decodable {
    var coaches: [WebCoach] = [WebCoach(name: "Coach 1")]
    var factions = ["Unassigned", "Red", "Blue", "Yellow", "Green"]
    var classes = ["Unassigned"]
    var schoolName = "Corso Athletics"
    var termLabel = "Term 3"
    var trainingDay = "Thursday"
    var sessionStartTime = "15:10"
    var sessionEndTime = "16:05"

    var native: ProgramSettings {
        var settings = ProgramSettings()
        settings.coaches = coaches.map { Coach(name: $0.name) }
        settings.factions = factions
        settings.classes = classes
        settings.schoolName = schoolName
        settings.termLabel = termLabel
        settings.trainingDay = trainingDay
        settings.sessionStart = sessionStartTime
        settings.sessionEnd = sessionEndTime
        settings.normalize()
        return settings
    }
}

struct CorsoShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    init(url: URL) {
        items = [url]
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
