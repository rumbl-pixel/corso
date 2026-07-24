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

    @discardableResult
    func updateSelection(for athleteID: UUID, to selection: SquadSelection) -> Bool {
        guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }) else { return false }
        guard state.athletes[index].selection != selection else { return true }
        let currentCount = state.athletes.filter { $0.selection == selection }.count
        switch selection {
        case .provisional where currentCount >= state.settings.provisionalAthleteLimit:
            return false
        case .interschool where currentCount >= state.settings.interschoolAthleteLimit:
            return false
        default:
            break
        }
        // Selection is an enum, so assigning a new state atomically removes the old one.
        state.athletes[index].selection = selection
        persist()
        return true
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
              let index = state.athletes.firstIndex(where: { $0.id == athleteID }),
              state.athletes[index].selection == .provisional
                || state.athletes[index].selection == .interschool
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
        let programsWereShared = state.settings.coachProgramsAreShared
        if programsWereShared, !settings.coachProgramsAreShared {
            for coach in settings.coaches {
                state.coachSessionOverrides[coach.id] = state.sessionOverrides
            }
        } else if !programsWereShared, settings.coachProgramsAreShared {
            let sourceCoachID = selectedCoachID ?? settings.coaches.first?.id
            if let sourceCoachID,
               let currentCoachProgram = state.coachSessionOverrides[sourceCoachID] {
                state.sessionOverrides = currentCoachProgram
            }
        }
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
        coachID: UUID? = nil,
        title: String? = nil,
        purpose: String? = nil,
        outcome: String? = nil,
        ballGames: String? = nil,
        activities: [SessionActivity]? = nil
    ) {
        guard let base = TrainingProgram.sessions.first(where: { $0.week == week }) else { return }
        let targetCoachID = state.settings.coachProgramsAreShared ? nil : (coachID ?? selectedCoachID)
        let currentOverrides = overrides(for: targetCoachID)
        let existing = currentOverrides[week]
            ?? SessionOverride(
                title: base.title,
                purpose: base.purpose,
                outcome: base.outcome,
                ballGames: base.ballGames,
                activities: base.activities
            )
        var nextOverrides = currentOverrides
        nextOverrides[week] = SessionOverride(
            title: title ?? existing.title,
            purpose: purpose ?? existing.purpose,
            outcome: outcome ?? existing.outcome,
            ballGames: ballGames ?? existing.ballGames,
            activities: activities ?? existing.activities
        )
        setOverrides(nextOverrides, for: targetCoachID)
        persist()
    }

    /// Saves a coach-created activity as a reusable template without bringing
    /// its completion state into another week's session.
    @discardableResult
    func saveSessionActivityForReuse(_ activity: SessionActivity) -> Bool {
        let saved = SavedSessionActivity(sessionActivity: activity)
        guard saved.isUsable else { return false }
        let duplicate = state.savedSessionActivities.contains {
            $0.time.caseInsensitiveCompare(saved.time) == .orderedSame
                && $0.activity.caseInsensitiveCompare(saved.activity) == .orderedSame
                && $0.detail.caseInsensitiveCompare(saved.detail) == .orderedSame
        }
        guard !duplicate else { return false }
        state.savedSessionActivities.insert(saved, at: 0)
        persist()
        return true
    }

    func deleteSavedSessionActivity(id: UUID) {
        guard state.savedSessionActivities.contains(where: { $0.id == id }) else { return }
        state.savedSessionActivities.removeAll { $0.id == id }
        persist()
    }

    func resetSession(week: Int, coachID: UUID? = nil) {
        let targetCoachID = state.settings.coachProgramsAreShared ? nil : (coachID ?? selectedCoachID)
        var current = overrides(for: targetCoachID)
        current.removeValue(forKey: week)
        setOverrides(current, for: targetCoachID)
        persist()
    }

    func resolvedSession(week: Int, coachID: UUID? = nil) -> TrainingSession? {
        let targetCoachID = state.settings.coachProgramsAreShared ? nil : (coachID ?? selectedCoachID)
        return TrainingProgram.session(for: week, overrides: overrides(for: targetCoachID))
    }

    func sessionIsCustom(week: Int, coachID: UUID? = nil) -> Bool {
        let targetCoachID = state.settings.coachProgramsAreShared ? nil : (coachID ?? selectedCoachID)
        return overrides(for: targetCoachID)[week] != nil
    }

    func copyProgram(from sourceCoachID: UUID?, to destinationCoachID: UUID) {
        guard !state.settings.coachProgramsAreShared,
              state.settings.coaches.contains(where: { $0.id == destinationCoachID })
        else { return }
        let source = overrides(for: sourceCoachID)
        state.coachSessionOverrides[destinationCoachID] = source
        persist()
    }

    @discardableResult
    func replaceProgram(
        with payload: CoachProgramSharePayload,
        destinationCoachID: UUID?
    ) -> Bool {
        let validWeeks = Set(TrainingProgram.sessions.map(\.week))
        let sessions = payload.sessions.filter { week, session in
            validWeeks.contains(week) && session.isUsable
        }
        guard !sessions.isEmpty else { return false }

        if state.settings.coachProgramsAreShared {
            state.sessionOverrides = sessions
        } else {
            guard let destinationCoachID,
                  state.settings.coaches.contains(where: { $0.id == destinationCoachID })
            else { return false }
            state.coachSessionOverrides[destinationCoachID] = sessions
        }
        persist()
        return true
    }

    func teamBoard(for scope: TeamBoardScope) -> TeamBoard {
        var board = state.teamBoards[scope.id] ?? TeamBoard()
        let limit = state.settings.teamRule(for: scope.event).teamSize
        board.teamA = Array(board.teamA.prefix(limit))
        board.teamB = Array(board.teamB.prefix(limit))
        board.normalize(validAthleteIDs: Set(state.athletes.map(\.id)))
        return board
    }

    func teamSkillProfile(for athleteID: UUID) -> TeamSkillProfile {
        state.teamSkillProfiles[athleteID] ?? TeamSkillProfile()
    }

    func updateTeamSkillProfile(_ profile: TeamSkillProfile, for athleteID: UUID) {
        guard state.athletes.contains(where: { $0.id == athleteID }) else { return }
        var profile = profile
        profile.normalize()
        if profile.ratings.isEmpty {
            state.teamSkillProfiles.removeValue(forKey: athleteID)
        } else {
            state.teamSkillProfiles[athleteID] = profile
        }
        persist()
    }

    func placeAthlete(
        _ athleteID: UUID,
        in destination: TeamPlacement,
        scope: TeamBoardScope
    ) {
        guard let athlete = state.athletes.first(where: { $0.id == athleteID }),
              athlete.division == scope.division,
              scope.gender.map({ athlete.gender == $0 }) ?? true,
              scope.stage.includes(athlete.selection)
        else { return }

        var board = teamBoard(for: scope)
        board.teamA.removeAll { $0 == athleteID }
        board.teamB.removeAll { $0 == athleteID }

        switch destination {
        case .available:
            break
        case .teamA:
            guard board.teamA.count < state.settings.teamRule(for: scope.event).teamSize else { return }
            board.teamA.append(athleteID)
        case .teamB:
            guard board.teamB.count < state.settings.teamRule(for: scope.event).teamSize else { return }
            board.teamB.append(athleteID)
        }

        if destination != .teamA, board.teamALeader == athleteID { board.teamALeader = nil }
        if destination != .teamB, board.teamBLeader == athleteID { board.teamBLeader = nil }
        state.teamBoards[scope.id] = board
        persist()
    }

    func placeAthlete(
        _ athleteID: UUID,
        in destination: TeamPlacement,
        at requestedIndex: Int,
        scope: TeamBoardScope
    ) {
        guard destination != .available,
              let athlete = state.athletes.first(where: { $0.id == athleteID }),
              athlete.division == scope.division,
              scope.gender.map({ athlete.gender == $0 }) ?? true,
              scope.stage.includes(athlete.selection)
        else {
            if destination == .available {
                placeAthlete(athleteID, in: .available, scope: scope)
            }
            return
        }

        var board = teamBoard(for: scope)
        board.teamA.removeAll { $0 == athleteID }
        board.teamB.removeAll { $0 == athleteID }
        if board.teamALeader == athleteID { board.teamALeader = nil }
        if board.teamBLeader == athleteID { board.teamBLeader = nil }

        if destination == .teamA {
            guard board.teamA.count < state.settings.teamRule(for: scope.event).teamSize else { return }
            board.teamA.insert(athleteID, at: min(max(requestedIndex, 0), board.teamA.count))
        } else {
            guard board.teamB.count < state.settings.teamRule(for: scope.event).teamSize else { return }
            board.teamB.insert(athleteID, at: min(max(requestedIndex, 0), board.teamB.count))
        }
        state.teamBoards[scope.id] = board
        persist()
    }

    @discardableResult
    func autoArrangeTeams(scope: TeamBoardScope) -> TeamArrangement {
        let eligible = state.athletes.filter { athlete in
            athlete.division == scope.division
                && (scope.gender.map { athlete.gender == $0 } ?? true)
                && scope.stage.includes(athlete.selection)
        }
        let arrangement = TeamOptimizer.arrange(
            scope: scope,
            eligible: eligible,
            results: state.results,
            skillProfiles: state.teamSkillProfiles,
            rule: state.settings.teamRule(for: scope.event)
        )
        guard arrangement.assignedCount > 0 else { return arrangement }
        state.teamBoards[scope.id] = arrangement.board
        persist()
        return arrangement
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

    private func overrides(for coachID: UUID?) -> [Int: SessionOverride] {
        guard let coachID else { return state.sessionOverrides }
        return state.coachSessionOverrides[coachID] ?? [:]
    }

    private func setOverrides(_ overrides: [Int: SessionOverride], for coachID: UUID?) {
        if let coachID {
            state.coachSessionOverrides[coachID] = overrides
        } else {
            state.sessionOverrides = overrides
        }
    }

}
