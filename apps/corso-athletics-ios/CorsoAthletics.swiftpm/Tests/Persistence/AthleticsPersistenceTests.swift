import Foundation
import XCTest
@testable import AppModule

final class AthleticsPersistenceTests: XCTestCase {
    func testVersionedRoundTripAndBackupRecovery() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }

        let persistence = FileAthleticsPersistence(fileURL: fileURL)
        let first = Athlete(
            name: "A Student",
            year: 1,
            gender: .boys,
            faction: "Green",
            className: "1A"
        )
        var state = AthleticsState()
        state.athletes = [first]
        try persistence.save(state)

        state.athletes.append(
            Athlete(name: "B Student", year: 6, gender: .girls, faction: "Red", className: "6A")
        )
        try persistence.save(state)
        XCTAssertEqual(try persistence.load().athletes.count, 2)

        // The valid previous generation survives a damaged current write.
        try Data("not json".utf8).write(to: fileURL, options: .atomic)
        let recovered = try persistence.load()
        XCTAssertEqual(recovered.athletes.map(\.name), ["A Student"])
    }

    func testCorruptionWithoutBackupThrowsInsteadOfSilentlyReturningEmpty() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: fileURL)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }

        XCTAssertThrowsError(try FileAthleticsPersistence(fileURL: fileURL).load()) { error in
            XCTAssertTrue(error is AthleticsPersistenceError)
        }
    }

    @MainActor
    func testStoreUpdatesStudentAndSettingsWithoutLosingResults() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoStoreTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let store = AthleticsStore(persistence: FileAthleticsPersistence(fileURL: fileURL))

        var settings = ProgramSettings()
        let coach = Coach(name: "Coach Patel")
        settings.coaches = [Coach(name: ""), coach]
        store.updateSettings(settings)
        XCTAssertEqual(store.selectedCoachID, coach.id)

        let student = Athlete(
            name: "Taylor Student",
            year: 3,
            gender: .girls,
            faction: "Red",
            className: "3A"
        )
        store.addAthlete(student)
        XCTAssertNotNil(store.recordResult(athleteID: student.id, event: .sprint100, value: 15.1))

        var edited = student
        edited.className = "3B"
        edited.selection = .interschool
        XCTAssertTrue(store.updateAthlete(edited))
        XCTAssertEqual(store.state.athletes.first?.className, "3B")
        XCTAssertEqual(store.state.athletes.first?.selection, .interschool)
        XCTAssertEqual(store.state.results.count, 1)
        XCTAssertEqual(store.state.results.first?.coachID, coach.id)
    }

    @MainActor
    func testBulkImportSkipsDuplicatesAndMergesGroups() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoImportTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let store = AthleticsStore(persistence: FileAthleticsPersistence(fileURL: fileURL))
        let mia = Athlete(name: "Mia Lee", year: 4, gender: .girls, faction: "Gold", className: "4Z")

        XCTAssertEqual(store.importAthletes([mia, mia]), 1)
        XCTAssertEqual(store.state.athletes.count, 1)
        XCTAssertTrue(store.state.settings.factions.contains("Gold"))
        XCTAssertTrue(store.state.settings.classes.contains("4Z"))
    }

    func testPilotReadinessDefaultsSafelyAndSurvivesSettingsCoding() throws {
        var settings = ProgramSettings()
        XCTAssertFalse(settings.pilotReadiness.isStudentDataReady)
        XCTAssertFalse(settings.pilotReadiness.isVideoReady)

        settings.pilotReadiness.localPilotApprovalConfirmed = true
        settings.pilotReadiness.schoolDeviceConfirmed = true
        settings.pilotReadiness.recordkeepingProcessConfirmed = true
        XCTAssertTrue(settings.pilotReadiness.isStudentDataReady)
        XCTAssertFalse(settings.pilotReadiness.isVideoReady)

        settings.pilotReadiness.videoPermissionConfirmed = true
        let decoded = try JSONDecoder().decode(
            ProgramSettings.self,
            from: JSONEncoder().encode(settings)
        )
        XCTAssertTrue(decoded.pilotReadiness.isVideoReady)
    }

    @MainActor
    func testResetRemovesPreviousWorkspaceAndBackupGeneration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorsoResetTests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("state.json")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let persistence = FileAthleticsPersistence(fileURL: fileURL)
        let store = AthleticsStore(persistence: persistence)
        store.addAthlete(Athlete(name: "Delete Me", year: 3, gender: .boys, faction: "Red", className: "3A"))
        store.setCurrentWeek(4)

        store.resetWorkspace()

        let reloaded = try persistence.load()
        XCTAssertTrue(reloaded.athletes.isEmpty)
        XCTAssertTrue(reloaded.results.isEmpty)
        XCTAssertEqual(reloaded.currentWeek, 1)
        XCTAssertNil(store.lastSaveError)
    }
}
