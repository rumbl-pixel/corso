import XCTest
@testable import AppModule

final class StudentFilterTests: XCTestCase {
    func testFiltersAcrossSearchAndSchoolGroups() {
        let mia = athlete("Mia Lee", year: 4, faction: "Red", className: "4A")
        let noah = athlete("Noah Brown", year: 4, faction: "Blue", className: "4B")
        let ava = athlete("Ava Wilson", year: 5, faction: "Red", className: "5A")

        XCTAssertEqual(
            StudentFilter.apply(
                [mia, noah, ava], query: "red", year: 4, faction: "Red", className: "4A"
            ).map(\.id),
            [mia.id]
        )
    }

    func testBlankFiltersReturnAllStudents() {
        let athletes = [athlete("Mia", year: 1), athlete("Noah", year: 6)]

        XCTAssertEqual(
            StudentFilter.apply(
                athletes, query: "  ", year: nil, faction: nil, className: nil
            ).count,
            2
        )
    }

    private func athlete(
        _ name: String,
        year: Int,
        faction: String = "Red",
        className: String = "1A"
    ) -> Athlete {
        Athlete(
            name: name,
            year: year,
            gender: .girls,
            faction: faction,
            className: className
        )
    }
}
