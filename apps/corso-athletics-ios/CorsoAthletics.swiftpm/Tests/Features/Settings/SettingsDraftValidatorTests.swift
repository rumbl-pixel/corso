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

    func testTeamRuleNormalizationMatchesConfiguredTeamSize() {
        var settings = ProgramSettings()
        settings.teamEventRules[TeamEvent.leaderBall.rawValue] = TeamEventRule(
            teamSize: 5,
            positionLabels: ["Leader", "Receiver"],
            ruleNote: ""
        )

        settings.normalize()

        let rule = settings.teamRule(for: .leaderBall)
        XCTAssertEqual(rule.teamSize, 5)
        XCTAssertEqual(rule.positionLabels.count, 5)
        XCTAssertFalse(rule.ruleNote.isEmpty)
    }
}
