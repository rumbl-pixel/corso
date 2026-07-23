import XCTest
@testable import AppModule

final class SettingsDraftValidatorTests: XCTestCase {
    func testRequiresAtLeastOneNonblankCoachFactionAndClass() {
        var settings = ProgramSettings()
        XCTAssertTrue(SettingsDraftValidator.isValid(settings))

        settings.coaches = [Coach(name: "   ")]
        XCTAssertFalse(SettingsDraftValidator.isValid(settings))

        settings.coaches = [Coach(name: "Jeremy")]
        settings.factions = [" "]
        XCTAssertFalse(SettingsDraftValidator.isValid(settings))

        settings.factions = ["Red"]
        settings.classes = [""]
        XCTAssertFalse(SettingsDraftValidator.isValid(settings))
    }
}
