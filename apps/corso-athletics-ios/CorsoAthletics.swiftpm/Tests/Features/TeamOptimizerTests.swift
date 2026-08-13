import XCTest
@testable import AppModule

final class TeamOptimizerTests: XCTestCase {
    func testRelayUses75And100EvidenceAndLeavesUntimedAthletesAvailable() {
        let athletes = (1...9).map {
            Athlete(
                name: "Runner \($0)",
                year: 4,
                gender: .boys,
                faction: "Red",
                className: "4A",
                selection: .provisional
            )
        }
        let results = athletes.prefix(8).enumerated().map { index, athlete in
            ResultRecord(
                athleteID: athlete.id,
                event: index.isMultiple(of: 2) ? .sprint75 : .sprint100,
                value: index.isMultiple(of: 2)
                    ? 10.5 + Double(index) / 10
                    : 14.2 + Double(index) / 10,
                addedBy: "Coach"
            )
        }
        let scope = TeamBoardScope(
            event: .sprintRelay,
            stage: .provisional,
            division: .intermediate,
            gender: .boys
        )

        let arrangement = TeamOptimizer.arrange(
            scope: scope,
            eligible: athletes,
            results: results,
            skillProfiles: [:],
            rule: TeamEventRule.defaultRule(for: .sprintRelay)
        )

        XCTAssertEqual(arrangement.assignedCount, 8)
        XCTAssertEqual(arrangement.evidenceCount, 8)
        XCTAssertFalse(arrangement.board.teamA.contains(athletes[8].id))
        XCTAssertFalse(arrangement.board.teamB.contains(athletes[8].id))
        XCTAssertEqual(arrangement.board.teamA.last, athletes[0].id)
        XCTAssertTrue(arrangement.summary.contains("stayed available"))
    }

    func testBallGameSuggestionRequiresRatingsAndPlacesBestFinisherLast() {
        let athletes = (1...5).map {
            Athlete(
                name: "Player \($0)",
                year: 5,
                gender: .girls,
                faction: "Blue",
                className: "5A",
                selection: .interschool
            )
        }
        var profiles: [UUID: TeamSkillProfile] = [:]
        for (index, athlete) in athletes.prefix(4).enumerated() {
            var profile = TeamSkillProfile()
            profile[.handling] = 5 - index
            profile[.passing] = 5 - index
            profile[.reliability] = 5 - index
            profile[.movement] = 3
            profiles[athlete.id] = profile
        }
        var rule = TeamEventRule.defaultRule(for: .passBall)
        rule.teamSize = 2
        rule.normalize(for: .passBall)

        let arrangement = TeamOptimizer.arrange(
            scope: TeamBoardScope(
                event: .passBall,
                stage: .interschool,
                division: .senior,
                gender: .girls
            ),
            eligible: athletes,
            results: [],
            skillProfiles: profiles,
            rule: rule
        )

        XCTAssertEqual(arrangement.assignedCount, 4)
        XCTAssertEqual(arrangement.board.teamA.last, athletes[0].id)
        XCTAssertFalse(arrangement.board.teamA.contains(athletes[4].id))
        XCTAssertFalse(arrangement.board.teamB.contains(athletes[4].id))
        XCTAssertTrue(arrangement.summary.contains("stayed available"))
    }

    @MainActor
    func testNoEvidenceDoesNotEraseAnExistingBoard() {
        let store = AthleticsStore(persistence: TeamOptimizerMemoryPersistence())
        let athlete = Athlete(
            name: "Existing Player",
            year: 4,
            gender: .boys,
            faction: "Green",
            className: "4A",
            selection: .provisional
        )
        store.addAthlete(athlete)
        let scope = TeamBoardScope(
            event: .passBall,
            stage: .provisional,
            division: .intermediate,
            gender: .boys
        )
        store.placeAthlete(athlete.id, in: .teamA, scope: scope)

        let arrangement = store.autoArrangeTeams(scope: scope)

        XCTAssertEqual(arrangement.assignedCount, 0)
        XCTAssertEqual(store.teamBoard(for: scope).teamA, [athlete.id])
    }
}

private final class TeamOptimizerMemoryPersistence: AthleticsPersisting, @unchecked Sendable {
    private var value = AthleticsState()

    func load() throws -> AthleticsState { value }
    func save(_ state: AthleticsState) throws { value = state }
    func reset(to state: AthleticsState) throws { value = state }
}
