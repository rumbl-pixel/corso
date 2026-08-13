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

    func testOneClassImportAcceptsNameOnlyCSVWithSelectedDefaults() throws {
        let csv = """
        Name
        Mia Lee
        Noah Brown
        """

        let imported = try StudentCSVImporter.parse(
            csv,
            options: StudentCSVImportOptions(
                destinationClass: "4A",
                defaultYear: 4
            )
        )

        XCTAssertEqual(imported.athletes.map(\.name), ["Mia Lee", "Noah Brown"])
        XCTAssertEqual(imported.athletes.map(\.year), [4, 4])
        XCTAssertEqual(imported.athletes.map(\.className), ["4A", "4A"])
    }

    func testCSVYearOverridesDefaultAndBlankYearUsesDefault() throws {
        let csv = """
        Name,Year
        Mia Lee,5
        Noah Brown,
        """

        let imported = try StudentCSVImporter.parse(
            csv,
            options: StudentCSVImportOptions(
                destinationClass: "5A",
                defaultYear: 4
            )
        )

        XCTAssertEqual(imported.athletes.map(\.year), [5, 4])
    }

    func testSelectedClassOverridesClassColumn() throws {
        let csv = """
        Name,Year,Class
        Mia Lee,4,Wrong Class
        """

        let imported = try StudentCSVImporter.parse(
            csv,
            options: StudentCSVImportOptions(
                destinationClass: "4A",
                defaultYear: 4
            )
        )

        XCTAssertEqual(imported.athletes.first?.className, "4A")
    }

    func testAcceptsCommonSchoolExportHeadingsAndSplitNames() throws {
        let csv = """
        Preferred Name,Surname,Year Level,Form,School House
        Mia,Lee,4,4A,Red
        """

        let imported = try StudentCSVImporter.parse(csv)

        XCTAssertEqual(imported.athletes.first?.name, "Mia Lee")
        XCTAssertEqual(imported.athletes.first?.year, 4)
        XCTAssertEqual(imported.athletes.first?.className, "4A")
        XCTAssertEqual(imported.athletes.first?.faction, "Red")
    }

    func testExplicitInvalidYearIsRejectedInsteadOfUsingDefault() throws {
        let csv = """
        Name,Year
        Mia Lee,8
        Noah Brown,
        """

        let imported = try StudentCSVImporter.parse(
            csv,
            options: StudentCSVImportOptions(
                destinationClass: "4A",
                defaultYear: 4
            )
        )

        XCTAssertEqual(imported.athletes.map(\.name), ["Noah Brown"])
        XCTAssertEqual(imported.rejectedRows, [2])
    }

    func testWholeSchoolModeRequiresClassColumnAndRejectsBlankClasses() throws {
        XCTAssertThrowsError(
            try StudentCSVImporter.parse(
                "Name,Year\nMia Lee,4",
                options: StudentCSVImportOptions(requiresClassColumn: true)
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("Class"))
        }

        let imported = try StudentCSVImporter.parse(
            "Name,Year,Class\nMia Lee,4,\nNoah Brown,5,5B",
            options: StudentCSVImportOptions(requiresClassColumn: true)
        )

        XCTAssertEqual(imported.athletes.map(\.name), ["Noah Brown"])
        XCTAssertEqual(imported.rejectedRows, [2])
    }

    func testReviewSeparatesExistingAndWithinFileDuplicates() {
        let existing = Athlete(
            name: "Mia Lee",
            year: 4,
            gender: .girls,
            faction: "Red",
            className: "4A"
        )
        let duplicateWithDifferentCapitalisation = Athlete(
            name: "mia lee",
            year: 4,
            gender: .unspecified,
            faction: "Blue",
            className: "4a"
        )
        let newStudent = Athlete(
            name: "Noah Brown",
            year: 4,
            gender: .boys,
            faction: "Blue",
            className: "4A"
        )

        let review = StudentImportReviewer.review(
            [duplicateWithDifferentCapitalisation, newStudent, newStudent],
            against: [existing]
        )

        XCTAssertEqual(review.studentsToImport.map(\.name), ["Noah Brown"])
        XCTAssertEqual(review.duplicates.count, 2)
    }
}
