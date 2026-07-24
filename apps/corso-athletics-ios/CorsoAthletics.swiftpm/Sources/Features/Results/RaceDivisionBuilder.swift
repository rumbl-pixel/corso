import Foundation

struct RaceDivisionLane: Equatable, Identifiable {
    var athlete: Athlete
    var lane: Int
    var bestSeconds: Double

    var id: UUID { athlete.id }
}

struct RaceDivision: Equatable, Identifiable {
    var number: Int
    var lanes: [RaceDivisionLane]

    var id: Int { number }
    var name: String { "Division \(number)" }
}

struct RaceDivisionPlan: Equatable {
    var divisions: [RaceDivision]
    var untimed: [Athlete]
}

enum RaceDivisionBuilder {
    static func build(
        athletes: [Athlete],
        results: [ResultRecord],
        event: AthleticsEvent,
        maximumSize: Int = 8
    ) -> RaceDivisionPlan {
        let athleteIDs = Set(athletes.map(\.id))
        let bestTimes = Dictionary(grouping: results.filter {
            $0.event == event
                && $0.isValid
                && athleteIDs.contains($0.athleteID)
        }, by: \.athleteID).compactMapValues { records in
            records.map(\.value).min()
        }

        let ranked = athletes.filter { bestTimes[$0.id] != nil }.sorted {
            let left = bestTimes[$0.id] ?? .infinity
            let right = bestTimes[$1.id] ?? .infinity
            if left != right { return left < right }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        let untimed = athletes.filter { bestTimes[$0.id] == nil }.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        guard !ranked.isEmpty else {
            return RaceDivisionPlan(divisions: [], untimed: untimed)
        }

        let safeMaximum = max(2, maximumSize)
        let divisionCount = Int(ceil(Double(ranked.count) / Double(safeMaximum)))
        let baseSize = ranked.count / divisionCount
        let largerDivisions = ranked.count % divisionCount
        var cursor = 0
        var divisions: [RaceDivision] = []

        for index in 0..<divisionCount {
            let size = baseSize + (index < largerDivisions ? 1 : 0)
            let athletesInDivision = Array(ranked[cursor..<(cursor + size)])
            divisions.append(
                RaceDivision(
                    number: index + 1,
                    lanes: athletesInDivision.enumerated().map { lane, athlete in
                        RaceDivisionLane(
                            athlete: athlete,
                            lane: lane + 1,
                            bestSeconds: bestTimes[athlete.id] ?? .infinity
                        )
                    }
                )
            )
            cursor += size
        }

        return RaceDivisionPlan(divisions: divisions, untimed: untimed)
    }
}
