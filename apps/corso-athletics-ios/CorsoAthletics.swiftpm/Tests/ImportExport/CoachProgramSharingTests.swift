import XCTest
@testable import AppModule

final class CoachProgramSharingTests: XCTestCase {
    func testSharedProgramFileContainsSessionsButNoStudentData() throws {
        let coach = Coach(name: "Coach Lee")
        var state = AthleticsState()
        state.settings.schoolName = "Example Primary"
        state.settings.termLabel = "Term 3"
        state.settings.coaches = [coach]
        state.settings.coachProgramsAreShared = false
        state.athletes = [
            Athlete(
                name: "Private Student Name",
                year: 5,
                gender: .girls,
                faction: "Blue",
                className: "5A"
            )
        ]
        state.coachSessionOverrides[coach.id] = [
            1: SessionOverride(
                title: "Starts",
                purpose: "Acceleration",
                outcome: "Use a strong first three steps",
                ballGames: "Pass Ball",
                activities: [
                    SessionActivity(
                        id: "shared-activity",
                        time: "0–10",
                        activity: "Starts",
                        detail: "Four quality starts"
                    )
                ]
            )
        ]

        let url = try CoachProgramSharing.export(state: state, coachID: coach.id)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let text = String(decoding: try Data(contentsOf: url), as: UTF8.self)
        let imported = try CoachProgramSharing.read(from: url)

        XCTAssertFalse(text.contains("Private Student Name"))
        XCTAssertEqual(imported.sourceCoachName, "Coach Lee")
        XCTAssertEqual(imported.sessions.count, TrainingProgram.sessions.count)
        XCTAssertEqual(imported.sessions[1]?.title, "Starts")
        XCTAssertEqual(imported.sessions[1]?.outcome, "Use a strong first three steps")
    }

    @MainActor
    func testImportedProgramReplacesOnlyChosenCoach() {
        let first = Coach(name: "Coach One")
        let second = Coach(name: "Coach Two")
        let store = AthleticsStore(persistence: CoachProgramMemoryPersistence())
        var settings = store.state.settings
        settings.coaches = [first, second]
        settings.coachProgramsAreShared = false
        store.updateSettings(settings)
        store.updateSession(
            week: 1,
            coachID: first.id,
            title: "Keep this",
            purpose: "First coach",
            ballGames: "Pass Ball",
            activities: []
        )
        let payload = CoachProgramSharePayload(
            schoolName: "Another School",
            termLabel: "Term 3",
            sourceCoachName: "Visiting Coach",
            sessions: [
                1: SessionOverride(
                    title: "Imported session",
                    purpose: "Second coach",
                    ballGames: "Leader Ball",
                    activities: []
                )
            ]
        )

        XCTAssertTrue(store.replaceProgram(with: payload, destinationCoachID: second.id))
        XCTAssertEqual(store.resolvedSession(week: 1, coachID: first.id)?.title, "Keep this")
        XCTAssertEqual(store.resolvedSession(week: 1, coachID: second.id)?.title, "Imported session")
    }
}

private final class CoachProgramMemoryPersistence: AthleticsPersisting, @unchecked Sendable {
    private var value = AthleticsState()

    func load() throws -> AthleticsState { value }
    func save(_ state: AthleticsState) throws { value = state }
    func reset(to state: AthleticsState) throws { value = state }
}
