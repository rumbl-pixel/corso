import Foundation
import XCTest
@testable import AppModule

final class AthleticsModelsTests: XCTestCase {
    func testDivisionIsDerivedFromYear() {
        XCTAssertEqual(CompetitionDivision.forYear(1), .junior)
        XCTAssertEqual(CompetitionDivision.forYear(2), .junior)
        XCTAssertEqual(CompetitionDivision.forYear(3), .intermediate)
        XCTAssertEqual(CompetitionDivision.forYear(4), .intermediate)
        XCTAssertEqual(CompetitionDivision.forYear(5), .senior)
        XCTAssertEqual(CompetitionDivision.forYear(6), .senior)
    }

    func testAthleteNormalizesRequiredFieldsAndAttendance() {
        let athlete = Athlete(
            name: "   ",
            year: 9,
            gender: .unspecified,
            faction: " ",
            className: "",
            attendance: [
                "2026-07-21": .present,
                "not-a-date": .absent,
                "2026-07-22": .unmarked
            ]
        )

        XCTAssertEqual(athlete.name, "Unnamed Student")
        XCTAssertEqual(athlete.year, 6)
        XCTAssertEqual(athlete.division, .senior)
        XCTAssertEqual(athlete.faction, "Unassigned")
        XCTAssertEqual(athlete.className, "Unassigned")
        XCTAssertEqual(athlete.attendance, ["2026-07-21": .present])
    }

    func testLegacyStudentAndResultDecodeWithSafeDefaults() throws {
        let studentID = UUID()
        let resultID = UUID()
        let json = """
        {
          "students": [{
            "id": "\(studentID.uuidString)",
            "name": "Alex Example",
            "year": 2,
            "gender": "Boys",
            "faction": "Red",
            "class": "2A"
          }],
          "results": [{
            "id": "\(resultID.uuidString)",
            "athleteID": "\(studentID.uuidString)",
            "event": "100m",
            "value": 15.2,
            "date": "2026-07-20T03:00:00Z",
            "addedBy": "Coach Lee"
          }]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(AthleticsState.self, from: Data(json.utf8))

        XCTAssertEqual(state.athletes.first?.className, "2A")
        XCTAssertEqual(state.athletes.first?.division, .junior)
        XCTAssertEqual(state.athletes.first?.selection, .classOnly)
        XCTAssertEqual(state.results.first?.unit, .seconds)
        XCTAssertEqual(state.results.first?.source, .unknown)
        XCTAssertEqual(state.results.first?.addedAt, state.results.first?.date)
    }

    func testAttendancePastDateLocksUntilExplicitlyUnlocked() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21))!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var state = AthleticsState()
        XCTAssertTrue(state.isAttendanceLocked(on: yesterday, now: today, calendar: calendar))
        state.unlockedAttendanceDates.insert(yesterday.attendanceKey)
        XCTAssertFalse(state.isAttendanceLocked(on: yesterday, now: today, calendar: calendar))
        XCTAssertFalse(state.isAttendanceLocked(on: today, now: today, calendar: calendar))
    }

    func testSettingsDropsBlankCoachesAndOnlyFallsBackWhenAllBlank() {
        var settings = ProgramSettings()
        let valid = Coach(name: "  Coach Lee  ")
        settings.coaches = [Coach(name: ""), valid]
        settings.normalize()

        XCTAssertEqual(settings.coaches.count, 1)
        XCTAssertEqual(settings.coaches.first?.id, valid.id)
        XCTAssertEqual(settings.coaches.first?.name, "Coach Lee")

        settings.coaches = [Coach(name: "   ")]
        settings.normalize()
        XCTAssertEqual(settings.coaches.count, 1)
        XCTAssertEqual(settings.coaches.first?.name, "Coach 1")
    }

    func testNormalizationRemovesOrphanAndInvalidResults() {
        let athlete = Athlete(
            name: "Sam",
            year: 4,
            gender: .girls,
            faction: "Blue",
            className: "4A"
        )
        var state = AthleticsState()
        state.athletes = [athlete]
        state.results = [
            ResultRecord(athleteID: athlete.id, event: .sprint100, value: 14, addedBy: "Coach"),
            ResultRecord(athleteID: UUID(), event: .sprint100, value: 13, addedBy: "Coach"),
            ResultRecord(athleteID: athlete.id, event: .sprint100, value: .nan, addedBy: "Coach")
        ]
        state.normalize()
        XCTAssertEqual(state.results.count, 1)
    }
}
