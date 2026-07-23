import Foundation
import XCTest
@testable import AppModule

final class ParityFeatureTests: XCTestCase {
    @MainActor
    func testSquadLimitsAndAttendanceScopeAreEnforced() throws {
        let persistence = MemoryAthleticsPersistence()
        let store = AthleticsStore(persistence: persistence)
        var settings = store.state.settings
        settings.provisionalAthleteLimit = 1
        settings.interschoolAthleteLimit = 1
        store.updateSettings(settings)

        let first = Athlete(
            name: "First Athlete",
            year: 4,
            gender: .boys,
            faction: "Red",
            className: "4A"
        )
        let second = Athlete(
            name: "Second Athlete",
            year: 4,
            gender: .girls,
            faction: "Blue",
            className: "4B"
        )
        store.addAthlete(first)
        store.addAthlete(second)

        XCTAssertFalse(store.markAttendance(for: first.id, on: .now, as: .present))
        XCTAssertTrue(store.updateSelection(for: first.id, to: .provisional))
        XCTAssertFalse(store.updateSelection(for: second.id, to: .provisional))
        XCTAssertTrue(store.markAttendance(for: first.id, on: .now, as: .present))
        XCTAssertTrue(store.updateSelection(for: second.id, to: .reserve))
        XCTAssertFalse(store.markAttendance(for: second.id, on: .now, as: .present))
    }

    @MainActor
    func testCoachProgramsCanBeSeparateThenShared() throws {
        let store = AthleticsStore(persistence: MemoryAthleticsPersistence())
        let first = Coach(name: "Coach One")
        let second = Coach(name: "Coach Two")
        var settings = store.state.settings
        settings.coaches = [first, second]
        settings.coachProgramsAreShared = false
        store.updateSettings(settings)

        store.updateSession(
            week: 1,
            coachID: first.id,
            title: "Starts and speed",
            purpose: "Coach One focus",
            ballGames: "Pass Ball",
            activities: [
                SessionActivity(
                    id: "custom-one",
                    time: "0–12",
                    activity: "Custom starts",
                    detail: "Coach-written detail"
                )
            ]
        )
        XCTAssertEqual(store.resolvedSession(week: 1, coachID: first.id)?.title, "Starts and speed")
        XCTAssertNotEqual(store.resolvedSession(week: 1, coachID: second.id)?.title, "Starts and speed")

        store.copyProgram(from: first.id, to: second.id)
        XCTAssertEqual(store.resolvedSession(week: 1, coachID: second.id)?.purpose, "Coach One focus")

        settings = store.state.settings
        store.selectedCoachID = second.id
        settings.coachProgramsAreShared = true
        store.updateSettings(settings)
        XCTAssertEqual(store.resolvedSession(week: 1)?.title, "Starts and speed")
    }

    @MainActor
    func testTeamBoardsAreSeparatedByGenderAndSupportDropPosition() throws {
        let store = AthleticsStore(persistence: MemoryAthleticsPersistence())
        let boy = Athlete(
            name: "Boy Runner",
            year: 4,
            gender: .boys,
            faction: "Red",
            className: "4A",
            selection: .provisional
        )
        let girl = Athlete(
            name: "Girl Runner",
            year: 4,
            gender: .girls,
            faction: "Blue",
            className: "4B",
            selection: .provisional
        )
        store.addAthlete(boy)
        store.addAthlete(girl)
        let boysScope = TeamBoardScope(
            event: .passBall,
            stage: .provisional,
            division: .intermediate,
            gender: .boys
        )
        let girlsScope = TeamBoardScope(
            event: .passBall,
            stage: .provisional,
            division: .intermediate,
            gender: .girls
        )

        store.placeAthlete(boy.id, in: .teamA, at: 0, scope: boysScope)
        store.placeAthlete(girl.id, in: .teamA, at: 0, scope: boysScope)
        store.placeAthlete(girl.id, in: .teamB, at: 0, scope: girlsScope)

        XCTAssertEqual(store.teamBoard(for: boysScope).teamA, [boy.id])
        XCTAssertEqual(store.teamBoard(for: girlsScope).teamB, [girl.id])
    }

    @MainActor
    func testEventAssignmentsSessionOverridesAndTeamBoardsPersist() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoParityTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let persistence = FileAthleticsPersistence(fileURL: fileURL)
        let store = AthleticsStore(persistence: persistence)
        let athlete = Athlete(
            name: "Jordan Lane",
            year: 4,
            gender: .girls,
            faction: "Blue",
            className: "4A",
            selection: .provisional
        )
        store.addAthlete(athlete)

        store.setEvent(.sprint100, assigned: true, for: athlete.id)
        store.setEvent(.longJump, assigned: true, for: athlete.id)
        store.updateSession(
            week: 1,
            ballGames: "Leader Ball",
            activities: [
                SessionActivity(
                    id: "custom",
                    time: "0–10",
                    activity: "Warm-up",
                    detail: "Custom warm-up",
                    completed: true
                )
            ]
        )
        let scope = TeamBoardScope(
            event: .passBall,
            stage: .provisional,
            division: .intermediate
        )
        store.placeAthlete(athlete.id, in: .teamA, scope: scope)
        store.makeLeader(athlete.id, in: .teamA, scope: scope)

        let reloaded = AthleticsStore(persistence: persistence)
        XCTAssertEqual(Set(reloaded.state.athletes[0].events), [.sprint100, .longJump])
        XCTAssertEqual(reloaded.resolvedSession(week: 1)?.ballGames, "Leader Ball")
        XCTAssertEqual(reloaded.resolvedSession(week: 1)?.activities.first?.completed, true)
        XCTAssertEqual(reloaded.teamBoard(for: scope).teamA, [athlete.id])
        XCTAssertEqual(reloaded.teamBoard(for: scope).teamALeader, athlete.id)
    }

    func testRaceDivisionBuilderBalancesAndLeavesUntimedVisible() {
        let athletes = (1...10).map {
            Athlete(
                name: "Runner \($0)",
                year: 5,
                gender: .boys,
                faction: "Red",
                className: "5A"
            )
        }
        let results = athletes.prefix(9).enumerated().map { index, athlete in
            ResultRecord(
                athleteID: athlete.id,
                event: .sprint100,
                value: 12 + Double(index) / 10,
                addedBy: "Coach"
            )
        }

        let plan = RaceDivisionBuilder.build(
            athletes: athletes,
            results: results,
            event: .sprint100,
            maximumSize: 8
        )

        XCTAssertEqual(plan.divisions.map { $0.lanes.count }, [5, 4])
        XCTAssertEqual(plan.divisions.first?.lanes.first?.athlete.id, athletes.first?.id)
        XCTAssertEqual(plan.untimed.map(\.id), [athletes.last!.id])
    }

    func testSchemaTwoStateMigratesWithParityDefaults() throws {
        let athleteID = UUID()
        let json = """
        {
          "schemaVersion": 2,
          "savedAt": "2026-07-23T08:00:00Z",
          "state": {
            "athletes": [{
              "id": "\(athleteID.uuidString)",
              "name": "Legacy Athlete",
              "year": 5,
              "gender": "Boys",
              "faction": "Green",
              "className": "5A",
              "selection": "Provisional",
              "attendance": {}
            }],
            "results": [],
            "settings": {},
            "currentWeek": 3,
            "unlockedAttendanceDates": []
          }
        }
        """
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoSchemaMigration-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(json.utf8).write(to: fileURL)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }

        let state = try FileAthleticsPersistence(fileURL: fileURL).load()
        XCTAssertEqual(state.athletes.first?.events, [])
        XCTAssertTrue(state.sessionOverrides.isEmpty)
        XCTAssertTrue(state.teamBoards.isEmpty)
        XCTAssertTrue(state.assistantAudit.isEmpty)
        XCTAssertEqual(state.permissionSlips, PermissionSlipSettings())
    }

    @MainActor
    func testBackupRoundTripIncludesParityData() throws {
        let athlete = Athlete(
            name: "Backup Athlete",
            year: 6,
            gender: .girls,
            faction: "Gold",
            className: "6A",
            selection: .interschool,
            events: [.sprint100, .sprintRelay]
        )
        var state = AthleticsState()
        state.athletes = [athlete]
        state.sessionOverrides[1] = SessionOverride(
            ballGames: "Pass Ball",
            activities: [
                SessionActivity(
                    id: "backup",
                    time: "0–5",
                    activity: "Briefing",
                    detail: "Backup detail"
                )
            ]
        )
        state.permissionSlips.contactName = "Coach Lee"

        let url = try AthleticsBackupService.export(state)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let restored = try AthleticsBackupService.restore(from: url).state

        XCTAssertEqual(restored.athletes.first?.events, [.sprint100, .sprintRelay])
        XCTAssertEqual(restored.sessionOverrides[1]?.activities.first?.detail, "Backup detail")
        XCTAssertEqual(restored.permissionSlips.contactName, "Coach Lee")
    }

    func testAssistantRequiresProposalBeforeApplyingWrite() {
        let athlete = Athlete(
            name: "Alex Student",
            year: 5,
            gender: .boys,
            faction: "Red",
            className: "5A"
        )
        var state = AthleticsState()
        state.athletes = [athlete]

        let interpretation = CorsoAssistantEngine.interpret(
            "Record Alex Student 100m 12.34 seconds",
            state: state
        )
        guard case .proposal(let proposal) = interpretation else {
            return XCTFail("Expected a confirmation proposal")
        }
        XCTAssertTrue(state.results.isEmpty)

        XCTAssertTrue(CorsoAssistantEngine.apply(
            proposal,
            to: &state,
            coachID: nil,
            coachName: "Coach Lee"
        ))
        XCTAssertEqual(state.results.first?.value, 12.34)
        XCTAssertEqual(state.assistantAudit.first?.action, .result)
    }

    func testVersion15WebBackupImportsIntoNativeWorkspace() throws {
        let athleteID = UUID()
        let resultID = UUID()
        let json = """
        {
          "exportedAt": "2026-07-23T08:00:00Z",
          "data": {
            "athletes": [{
              "id": "\(athleteID.uuidString)",
              "name": "Web Athlete",
              "year": 4,
              "faction": "Blue",
              "className": "4A",
              "events": ["100m", "Sprint Relay"],
              "selection": "confirmed",
              "gender": "Girls",
              "division": "Intermediate",
              "attendance": {"date-2026-07-23": "present"}
            }],
            "results": [{
              "id": "\(resultID.uuidString)",
              "athleteId": "\(athleteID.uuidString)",
              "event": "100m",
              "result": "14.21s",
              "date": "2026-07-23",
              "note": "Imported from web",
              "addedAt": "2026-07-23T08:00:00Z",
              "addedBy": "Coach Lee",
              "effort": 4
            }],
            "assistantAudit": [],
            "currentWeek": 5,
            "sessionOverrides": {},
            "teamBoards": {},
            "settings": {
              "coaches": [{"id": "coach-1", "name": "Coach Lee"}],
              "factions": ["Unassigned", "Blue"],
              "classes": ["Unassigned", "4A"],
              "schoolName": "Example Primary",
              "termLabel": "Term 3",
              "trainingDay": "Thursday",
              "sessionStartTime": "15:10",
              "sessionEndTime": "16:05"
            }
          }
        }
        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoWebBackup-\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        let restored = try AthleticsBackupService.restore(from: url).state
        XCTAssertEqual(restored.settings.schoolName, "Example Primary")
        XCTAssertEqual(restored.currentWeek, 5)
        XCTAssertEqual(restored.athletes.first?.selection, .interschool)
        XCTAssertEqual(restored.athletes.first?.events, [.sprint100, .sprintRelay])
        XCTAssertEqual(restored.athletes.first?.attendance["2026-07-23"], .present)
        XCTAssertEqual(restored.results.first?.value, 14.21)
    }
}

private final class MemoryAthleticsPersistence: AthleticsPersisting, @unchecked Sendable {
    private var value = AthleticsState()

    func load() throws -> AthleticsState { value }
    func save(_ state: AthleticsState) throws { value = state }
    func reset(to state: AthleticsState) throws { value = state }
}
