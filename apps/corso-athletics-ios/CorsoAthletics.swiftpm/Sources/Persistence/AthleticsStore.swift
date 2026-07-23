import Foundation
import Observation

@MainActor
@Observable
final class AthleticsStore {
    private(set) var state: AthleticsState
    private(set) var lastSaveError: String?
    private(set) var persistenceIsWriteBlocked = false
    var selectedCoachID: UUID?

    private let persistence: any AthleticsPersisting

    init(persistence: any AthleticsPersisting = FileAthleticsPersistence()) {
        self.persistence = persistence
        do {
            var loaded = try persistence.load()
            loaded.normalize()
            state = loaded
        } catch {
            state = .empty
            lastSaveError = error.localizedDescription
            // Never overwrite an unreadable archive with an apparently empty one.
            // Recovery must be an explicit user/admin action.
            persistenceIsWriteBlocked = true
        }
        selectedCoachID = state.settings.coaches.first?.id
    }

    var selectedCoachName: String {
        state.settings.coaches.first(where: { $0.id == selectedCoachID })?.name
            ?? state.settings.coaches.first?.name
            ?? "Coach"
    }

    func addAthlete(_ athlete: Athlete) {
        var athlete = athlete
        athlete.normalize()
        guard !state.athletes.contains(where: { $0.id == athlete.id }) else { return }
        state.athletes.append(athlete)
        state.athletes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
    }

    /// Adds a validated batch with one disk write. A duplicate is the same
    /// normalised name, year and class, regardless of capitalisation.
    @discardableResult
    func importAthletes(_ athletes: [Athlete]) -> Int {
        var identities = Set(state.athletes.map(Self.studentIdentity))
        var inserted = 0

        for rawAthlete in athletes {
            var athlete = rawAthlete
            athlete.normalize()
            guard identities.insert(Self.studentIdentity(athlete)).inserted else { continue }
            state.athletes.append(athlete)
            inserted += 1

            if !state.settings.classes.contains(where: { $0.caseInsensitiveCompare(athlete.className) == .orderedSame }) {
                state.settings.classes.append(athlete.className)
            }
            if !state.settings.factions.contains(where: { $0.caseInsensitiveCompare(athlete.faction) == .orderedSame }) {
                state.settings.factions.append(athlete.faction)
            }
        }

        guard inserted > 0 else { return 0 }
        state.athletes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
        return inserted
    }

    /// Replaces student details without touching their results or stable ID.
    @discardableResult
    func updateAthlete(_ athlete: Athlete) -> Bool {
        guard let index = state.athletes.firstIndex(where: { $0.id == athlete.id }) else { return false }
        var athlete = athlete
        athlete.normalize()
        state.athletes[index] = athlete
        state.athletes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
        return true
    }

    func deleteAthlete(id: UUID) {
        state.athletes.removeAll { $0.id == id }
        state.results.removeAll { $0.athleteID == id }
        persist()
    }

    func updateSelection(for athleteID: UUID, to selection: SquadSelection) {
        guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }) else { return }
        // Selection is an enum, so assigning a new state atomically removes the old one.
        state.athletes[index].selection = selection
        persist()
    }

    @discardableResult
    func markAttendance(
        for athleteID: UUID,
        on date: Date,
        as status: AttendanceStatus,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard !state.isAttendanceLocked(on: date, now: now, calendar: calendar),
              let index = state.athletes.firstIndex(where: { $0.id == athleteID })
        else { return false }
        let key = date.attendanceKey(calendar: calendar)
        if status == .unmarked {
            state.athletes[index].attendance.removeValue(forKey: key)
        } else {
            state.athletes[index].attendance[key] = status
        }
        persist()
        return true
    }

    func unlockAttendance(on date: Date, calendar: Calendar = .current) {
        state.unlockedAttendanceDates.insert(date.attendanceKey(calendar: calendar))
        persist()
    }

    func lockAttendance(on date: Date, calendar: Calendar = .current) {
        state.unlockedAttendanceDates.remove(date.attendanceKey(calendar: calendar))
        persist()
    }

    @discardableResult
    func recordResult(
        athleteID: UUID,
        event: AthleticsEvent,
        value: Double,
        effort: Int? = nil,
        note: String = "",
        date: Date = .now,
        source: ResultSource = .unknown
    ) -> ResultRecord? {
        guard state.athletes.contains(where: { $0.id == athleteID }), value.isFinite, value > 0 else {
            return nil
        }
        let result = ResultRecord(
            athleteID: athleteID,
            event: event,
            value: value,
            date: date,
            effort: effort,
            note: note,
            addedBy: selectedCoachName,
            coachID: selectedCoachID,
            source: source
        )
        state.results.append(result)
        persist()
        return result
    }

    @discardableResult
    func updateResult(_ result: ResultRecord) -> Bool {
        guard result.isValid,
              state.athletes.contains(where: { $0.id == result.athleteID }),
              let index = state.results.firstIndex(where: { $0.id == result.id })
        else { return false }
        var result = result
        result.updatedAt = .now
        state.results[index] = result
        persist()
        return true
    }

    func deleteResult(id: UUID) {
        state.results.removeAll { $0.id == id }
        persist()
    }

    func updateSettings(_ settings: ProgramSettings) {
        var settings = settings
        settings.normalize()
        state.settings = settings
        if !settings.coaches.contains(where: { $0.id == selectedCoachID }) {
            selectedCoachID = settings.coaches.first?.id
        }
        persist()
    }

    func setCurrentWeek(_ week: Int) {
        state.currentWeek = min(max(week, 1), 9)
        persist()
    }

    /// Allows a caller to replace an unreadable archive only after it has
    /// explicitly confirmed data recovery/reset. This is intentionally not
    /// called automatically.
    func allowReplacingUnreadableArchive() {
        persistenceIsWriteBlocked = false
        persist()
    }

    /// Permanently starts a new local workspace. The UI protects this behind a
    /// typed RESET confirmation; callers should never invoke it implicitly.
    func resetWorkspace() {
        state = .empty
        selectedCoachID = state.settings.coaches.first?.id
        persistenceIsWriteBlocked = false
        lastSaveError = nil
        do {
            try persistence.reset(to: state)
        } catch {
            lastSaveError = error.localizedDescription
        }
    }

    private func persist() {
        guard !persistenceIsWriteBlocked else { return }
        do {
            state.normalize()
            try persistence.save(state)
            lastSaveError = nil
        } catch {
            lastSaveError = error.localizedDescription
        }
    }

    private static func studentIdentity(_ athlete: Athlete) -> String {
        [athlete.name, String(athlete.year), athlete.className]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")
    }
}
