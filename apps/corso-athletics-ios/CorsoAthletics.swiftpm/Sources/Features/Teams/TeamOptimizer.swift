import Foundation

struct TeamArrangement: Equatable, Sendable {
    var board: TeamBoard
    var assignedCount: Int
    var evidenceCount: Int
    var eligibleCount: Int
    var summary: String
}

enum TeamOptimizer {
    static func arrange(
        scope: TeamBoardScope,
        eligible: [Athlete],
        results: [ResultRecord],
        skillProfiles: [UUID: TeamSkillProfile],
        rule: TeamEventRule
    ) -> TeamArrangement {
        switch scope.event {
        case .sprintRelay:
            return arrangeRelay(
                eligible: eligible,
                results: results,
                rule: rule
            )
        case .passBall, .tunnelBall, .leaderBall:
            return arrangeBallGame(
                event: scope.event,
                eligible: eligible,
                profiles: skillProfiles,
                rule: rule
            )
        }
    }

    static func relayEvidence(
        for athleteID: UUID,
        results: [ResultRecord]
    ) -> (event: AthleticsEvent, time: Double, secondsPer100m: Double)? {
        let candidates: [(AthleticsEvent, Double)] = [
            (.sprint75, 75),
            (.sprint100, 100)
        ]
        return candidates.compactMap { event, distance -> (
            event: AthleticsEvent,
            time: Double,
            secondsPer100m: Double
        )? in
            guard let result = ResultRanking.bestResult(
                for: athleteID,
                event: event,
                results: results
            ) else { return nil }
            return (
                event: event,
                time: result.value,
                secondsPer100m: result.value / distance * 100
            )
        }.min { $0.secondsPer100m < $1.secondsPer100m }
    }

    static func relevantSkills(for event: TeamEvent) -> [TeamSkill] {
        switch event {
        case .passBall:
            return [.handling, .passing, .reliability, .movement]
        case .tunnelBall:
            return [.rolling, .movement, .reliability]
        case .leaderBall:
            return [.leadership, .passing, .handling, .reliability, .movement]
        case .sprintRelay:
            return [.movement, .reliability]
        }
    }

    private static func arrangeRelay(
        eligible: [Athlete],
        results: [ResultRecord],
        rule: TeamEventRule
    ) -> TeamArrangement {
        let ranked = eligible.compactMap { athlete -> (Athlete, Double)? in
            guard let evidence = relayEvidence(for: athlete.id, results: results) else { return nil }
            return (athlete, evidence.secondsPer100m)
        }.sorted { left, right in
            left.1 == right.1
                ? left.0.name.localizedStandardCompare(right.0.name) == .orderedAscending
                : left.1 < right.1
        }

        let selected = Array(ranked.prefix(rule.teamSize * 2))
        var split = snakeSplit(selected)
        split.teamA = relayOrder(split.teamA)
        split.teamB = relayOrder(split.teamB)
        let assigned = split.teamA.count + split.teamB.count
        let missingEvidence = max(eligible.count - ranked.count, 0)
        let outsideCapacity = max(ranked.count - selected.count, 0)
        let summary: String
        if assigned == 0 {
            summary = "No team was changed. Add a 75m or 100m time before asking Corso to suggest relay teams."
        } else {
            var details = ["Suggested \(assigned) relay positions from 75m/100m pace."]
            if missingEvidence > 0 {
                details.append("\(missingEvidence) athlete\(missingEvidence == 1 ? "" : "s") stayed available because no sprint time is recorded.")
            }
            if outsideCapacity > 0 {
                details.append("\(outsideCapacity) timed athlete\(outsideCapacity == 1 ? "" : "s") stayed available outside the configured team capacity.")
            }
            details.append("Fastest runners anchor; review starts, bends and handovers before confirming.")
            summary = details.joined(separator: " ")
        }
        return TeamArrangement(
            board: TeamBoard(
                teamA: split.teamA.map(\.0.id),
                teamB: split.teamB.map(\.0.id)
            ),
            assignedCount: assigned,
            evidenceCount: ranked.count,
            eligibleCount: eligible.count,
            summary: summary
        )
    }

    private static func arrangeBallGame(
        event: TeamEvent,
        eligible: [Athlete],
        profiles: [UUID: TeamSkillProfile],
        rule: TeamEventRule
    ) -> TeamArrangement {
        let skills = relevantSkills(for: event)
        let ranked = eligible.compactMap { athlete -> (Athlete, Double)? in
            guard let profile = profiles[athlete.id],
                  skills.filter({ profile[$0] != nil }).count >= min(2, skills.count),
                  let score = profile.average(for: skills)
            else { return nil }
            return (athlete, score)
        }.sorted { left, right in
            left.1 == right.1
                ? left.0.name.localizedStandardCompare(right.0.name) == .orderedAscending
                : left.1 > right.1
        }

        let selected = Array(ranked.prefix(rule.teamSize * 2))
        var split = snakeSplit(selected)
        split.teamA = roleOrder(split.teamA, event: event, profiles: profiles)
        split.teamB = roleOrder(split.teamB, event: event, profiles: profiles)

        let teamAIDs = split.teamA.map(\.0.id)
        let teamBIDs = split.teamB.map(\.0.id)
        let missingEvidence = max(eligible.count - ranked.count, 0)
        let outsideCapacity = max(ranked.count - selected.count, 0)
        let assigned = teamAIDs.count + teamBIDs.count
        let summary: String
        if assigned == 0 {
            summary = "No team was changed. Rate the relevant ball-game skills for athletes before asking Corso to suggest teams."
        } else {
            var details = ["Suggested \(assigned) positions from coach skill ratings."]
            if missingEvidence > 0 {
                details.append("\(missingEvidence) athlete\(missingEvidence == 1 ? "" : "s") stayed available until relevant skills are rated.")
            }
            if outsideCapacity > 0 {
                details.append("\(outsideCapacity) rated athlete\(outsideCapacity == 1 ? "" : "s") stayed available outside the configured team capacity.")
            }
            details.append("Treat this as a starting point and confirm the order during timed practice.")
            summary = details.joined(separator: " ")
        }
        return TeamArrangement(
            board: TeamBoard(
                teamA: teamAIDs,
                teamB: teamBIDs,
                teamALeader: event == .leaderBall ? teamAIDs.first : nil,
                teamBLeader: event == .leaderBall ? teamBIDs.first : nil
            ),
            assignedCount: assigned,
            evidenceCount: ranked.count,
            eligibleCount: eligible.count,
            summary: summary
        )
    }

    private static func snakeSplit<T>(_ ranked: [T]) -> (teamA: [T], teamB: [T]) {
        var teamA: [T] = []
        var teamB: [T] = []
        for (index, item) in ranked.enumerated() {
            switch index % 4 {
            case 0, 3:
                teamA.append(item)
            default:
                teamB.append(item)
            }
        }
        return (teamA, teamB)
    }

    private static func relayOrder(
        _ athletes: [(Athlete, Double)]
    ) -> [(Athlete, Double)] {
        guard athletes.count >= 2 else { return athletes }
        let fastestFirst = athletes.sorted { $0.1 < $1.1 }
        let anchor = fastestFirst[0]
        let starter = fastestFirst[1]
        let middle = Array(fastestFirst.dropFirst(2).reversed())
        return [starter] + middle + [anchor]
    }

    private static func roleOrder(
        _ athletes: [(Athlete, Double)],
        event: TeamEvent,
        profiles: [UUID: TeamSkillProfile]
    ) -> [(Athlete, Double)] {
        guard athletes.count >= 2 else { return athletes }
        switch event {
        case .leaderBall:
            return moveBestRoleAthlete(
                in: athletes,
                skills: [.leadership, .passing, .reliability],
                profiles: profiles,
                toFront: true
            )
        case .passBall:
            return moveBestRoleAthlete(
                in: athletes,
                skills: [.handling, .reliability],
                profiles: profiles,
                toFront: false
            )
        case .tunnelBall:
            return moveBestRoleAthlete(
                in: athletes,
                skills: [.rolling, .reliability],
                profiles: profiles,
                toFront: false
            )
        case .sprintRelay:
            return athletes
        }
    }

    private static func moveBestRoleAthlete(
        in athletes: [(Athlete, Double)],
        skills: [TeamSkill],
        profiles: [UUID: TeamSkillProfile],
        toFront: Bool
    ) -> [(Athlete, Double)] {
        guard let bestIndex = athletes.indices.max(by: { left, right in
            let leftScore = profiles[athletes[left].0.id]?.average(for: skills) ?? 0
            let rightScore = profiles[athletes[right].0.id]?.average(for: skills) ?? 0
            return leftScore < rightScore
        }) else { return athletes }
        var ordered = athletes
        let best = ordered.remove(at: bestIndex)
        if toFront {
            ordered.insert(best, at: 0)
        } else {
            ordered.append(best)
        }
        return ordered
    }
}
