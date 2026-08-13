import XCTest
@testable import AppModule

final class SquadFilterTests: XCTestCase {
    func testStudentAppearsInOnlyCurrentSelectionFilter() {
        var athlete = Athlete(
            name: "Mia Lee",
            year: 4,
            gender: .girls,
            faction: "Red",
            className: "4A",
            selection: .provisional
        )

        XCTAssertEqual(filtered([athlete], selection: .provisional).map(\.id), [athlete.id])
        XCTAssertTrue(filtered([athlete], selection: .interschool).isEmpty)

        athlete.selection = .interschool

        XCTAssertTrue(filtered([athlete], selection: .provisional).isEmpty)
        XCTAssertEqual(filtered([athlete], selection: .interschool).map(\.id), [athlete.id])
    }

    func testDivisionAndGenderFiltersWorkTogether() {
        let juniorGirl = Athlete(
            name: "Ava", year: 2, gender: .girls, faction: "Blue", className: "2A"
        )
        let juniorBoy = Athlete(
            name: "Noah", year: 2, gender: .boys, faction: "Blue", className: "2A"
        )

        let output = SquadFilter.apply(
            [juniorGirl, juniorBoy],
            query: "",
            selection: nil,
            division: .junior,
            gender: .girls
        )

        XCTAssertEqual(output.map(\.id), [juniorGirl.id])
    }

    private func filtered(_ athletes: [Athlete], selection: SquadSelection) -> [Athlete] {
        SquadFilter.apply(
            athletes,
            query: "",
            selection: selection,
            division: nil,
            gender: nil
        )
    }
}
