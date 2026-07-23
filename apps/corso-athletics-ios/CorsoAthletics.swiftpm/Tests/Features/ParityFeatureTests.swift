import Foundation
import XCTest
@testable import AppModule

final class ParityFeatureTests: XCTestCase {
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
