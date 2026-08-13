import XCTest
@testable import AppModule

final class ResultRankingTests: XCTestCase {
    func testFastestTimedAndLongestJumpAreBest() {
        let athlete = makeAthlete("Mia", year: 5)
        let timed = [
            result(athlete, event: .sprint100, value: 14.2),
            result(athlete, event: .sprint100, value: 13.8)
        ]
        let jumps = [
            result(athlete, event: .longJump, value: 3.1),
            result(athlete, event: .longJump, value: 3.45)
        ]

        XCTAssertEqual(ResultRanking.bestResult(for: athlete.id, event: .sprint100, results: timed)?.value, 13.8)
        XCTAssertEqual(ResultRanking.bestResult(for: athlete.id, event: .longJump, results: jumps)?.value, 3.45)
    }

    func testStarsAreRankedWithinYearAndGenderCohorts() {
        let yearFourGirl = makeAthlete("Mia", year: 4, gender: .girls)
        let yearFiveGirl = makeAthlete("Ava", year: 5, gender: .girls)
        let yearFourBoy = makeAthlete("Noah", year: 4, gender: .boys)
        let athletes = [yearFourGirl, yearFiveGirl, yearFourBoy]
        let results = [
            result(yearFourGirl, event: .sprint100, value: 15),
            result(yearFiveGirl, event: .sprint100, value: 14),
            result(yearFourBoy, event: .sprint100, value: 13)
        ]

        let starred = ResultRanking.topAthleteIDs(
            athletes: athletes,
            results: results,
            event: .sprint100,
            limit: 1
        )

        XCTAssertEqual(starred, Set(athletes.map(\.id)))
    }

    private func makeAthlete(
        _ name: String,
        year: Int,
        gender: AthleteGender = .girls
    ) -> Athlete {
        Athlete(name: name, year: year, gender: gender, faction: "Red", className: "\(year)A")
    }

    private func result(_ athlete: Athlete, event: AthleticsEvent, value: Double) -> ResultRecord {
        ResultRecord(athleteID: athlete.id, event: event, value: value, addedBy: "Coach")
    }
}
