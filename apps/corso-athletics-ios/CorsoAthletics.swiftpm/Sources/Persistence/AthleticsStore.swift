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
        let review = StudentImportReviewer.review(athletes, against: state.athletes)

        for athlete in review.studentsToImport {
            state.athletes.append(athlete)

            if !state.settings.classes.contains(where: { $0.caseInsensitiveCompare(athlete.className) == .orderedSame }) {
                state.settings.classes.append(athlete.className)
            }
            if !state.settings.factions.contains(where: { $0.caseInsensitiveCompare(athlete.faction) == .orderedSame }) {
                state.settings.factions.append(athlete.faction)
            }
        }

        guard !review.studentsToImport.isEmpty else { return 0 }
        state.athletes.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        persist()
        return review.studentsToImport.count
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
        state.teamBoards = state.teamBoards.reduce(into: [:]) { output, entry in
            var board = entry.value
            board.teamA.removeAll { $0 == id }
            board.teamB.removeAll { $0 == id }
            if board.teamALeader == id { board.teamALeader = nil }
            if board.teamBLeader == id { board.teamBLeader = nil }
            output[entry.key] = board
        }
        persist()
    }

    func updateSelection(for athleteID: UUID, to selection: SquadSelection) {
        guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }) else { return }
        // Selection is an enum, so assigning a new state atomically removes the old one.
        state.athletes[index].selection = selection
        persist()
    }

    func setEvent(_ event: AthleticsEvent, assigned: Bool, for athleteID: UUID) {
        guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }) else { return }
        if assigned {
            if !state.athletes[index].events.contains(event) {
                state.athletes[index].events.append(event)
            }
        } else {
            state.athletes[index].events.removeAll { $0 == event }
        }
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

    func updateSession(
        week: Int,
        ballGames: String? = nil,
        activities: [SessionActivity]? = nil
    ) {
        guard let base = TrainingProgram.sessions.first(where: { $0.week == week }) else { return }
        let existing = state.sessionOverrides[week]
            ?? SessionOverride(ballGames: base.ballGames, activities: base.activities)
        state.sessionOverrides[week] = SessionOverride(
            ballGames: ballGames ?? existing.ballGames,
            activities: activities ?? existing.activities
        )
        persist()
    }

    func resetSession(week: Int) {
        state.sessionOverrides.removeValue(forKey: week)
        persist()
    }

    func resolvedSession(week: Int) -> TrainingSession? {
        TrainingProgram.session(for: week, overrides: state.sessionOverrides)
    }

    func teamBoard(for scope: TeamBoardScope) -> TeamBoard {
        state.teamBoards[scope.id] ?? TeamBoard()
    }

    func placeAthlete(
        _ athleteID: UUID,
        in destination: TeamPlacement,
        scope: TeamBoardScope
    ) {
        guard let athlete = state.athletes.first(where: { $0.id == athleteID }),
              athlete.division == scope.division,
              scope.stage.includes(athlete.selection)
        else { return }

        var board = teamBoard(for: scope)
        board.teamA.removeAll { $0 == athleteID }
        board.teamB.removeAll { $0 == athleteID }

        switch destination {
        case .available:
            break
        case .teamA:
            board.teamA.append(athleteID)
        case .teamB:
            board.teamB.append(athleteID)
        }

        if destination != .teamA, board.teamALeader == athleteID { board.teamALeader = nil }
        if destination != .teamB, board.teamBLeader == athleteID { board.teamBLeader = nil }
        state.teamBoards[scope.id] = board
        persist()
    }

    func moveAthlete(
        _ athleteID: UUID,
        in team: TeamPlacement,
        direction: Int,
        scope: TeamBoardScope
    ) {
        guard team != .available, direction == -1 || direction == 1 else { return }
        var board = teamBoard(for: scope)
        var athletes = team == .teamA ? board.teamA : board.teamB
        guard let index = athletes.firstIndex(of: athleteID) else { return }
        let target = index + direction
        guard athletes.indices.contains(target) else { return }

        let leader = team == .teamA ? board.teamALeader : board.teamBLeader
        if athleteID == leader && direction > 0 { return }
        if target == 0, leader != nil, athleteID != leader { return }
        athletes.swapAt(index, target)

        if team == .teamA {
            board.teamA = athletes
        } else {
            board.teamB = athletes
        }
        state.teamBoards[scope.id] = board
        persist()
    }

    func makeLeader(_ athleteID: UUID, in team: TeamPlacement, scope: TeamBoardScope) {
        guard team != .available else { return }
        var board = teamBoard(for: scope)
        let containsAthlete = team == .teamA
            ? board.teamA.contains(athleteID)
            : board.teamB.contains(athleteID)
        guard containsAthlete else { return }

        if team == .teamA {
            board.teamALeader = athleteID
            board.teamA.moveToFront(athleteID)
        } else {
            board.teamBLeader = athleteID
            board.teamB.moveToFront(athleteID)
        }
        state.teamBoards[scope.id] = board
        persist()
    }

    func updatePermissionSlipSettings(_ settings: PermissionSlipSettings) {
        state.permissionSlips = settings
        persist()
    }

    func commitAssistantChange(state nextState: AthleticsState) {
        state = nextState
        persist()
    }

    func restoreWorkspace(_ restoredState: AthleticsState) {
        state = restoredState
        state.normalize()
        if !state.settings.coaches.contains(where: { $0.id == selectedCoachID }) {
            selectedCoachID = state.settings.coaches.first?.id
        }
        persistenceIsWriteBlocked = false
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

}
