import XCTest
@testable import AppModule

final class StudentCSVImporterTests: XCTestCase {
    func testParsesExcelStyleCSVWithAliasesAndQuotedName() throws {
        let csv = """
        Student Name,Year Group,Gender,Class,House
        "Lee, Mia",Year 4,Girls,4A,Red
        Noah Brown,2,M,2B,Blue
        """

        let imported = try StudentCSVImporter.parse(csv)

        XCTAssertEqual(imported.athletes.count, 2)
        XCTAssertEqual(imported.athletes[0].name, "Lee, Mia")
        XCTAssertEqual(imported.athletes[0].division, .intermediate)
        XCTAssertEqual(imported.athletes[1].gender, .boys)
        XCTAssertEqual(imported.athletes[1].division, .junior)
        XCTAssertTrue(imported.rejectedRows.isEmpty)
    }

    func testRejectsMalformedRowsWithoutDiscardingValidStudents() throws {
        let csv = """
        Name,Year,Gender,Class,Faction
        Mia,4,Girls,4A,Red
        Missing year,,Boys,4A,Blue
        Too old,8,Girls,8A,Green
        """

        let imported = try StudentCSVImporter.parse(csv)

        XCTAssertEqual(imported.athletes.map(\.name), ["Mia"])
        XCTAssertEqual(imported.rejectedRows, [3, 4])
    }

    func testMissingRequiredHeaderFailsClearly() {
        XCTAssertThrowsError(try StudentCSVImporter.parse("Name,Class\nMia,4A")) { error in
            XCTAssertTrue(error.localizedDescription.contains("Year"))
        }
    }
}
