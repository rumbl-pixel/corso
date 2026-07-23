import Foundation

struct StudentCSVImport: Sendable {
    let athletes: [Athlete]
    let rejectedRows: [Int]
}

enum StudentCSVImportError: LocalizedError, Sendable {
    case emptyFile
    case missingColumns([String])
    case noValidStudents

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .missingColumns(let columns):
            return "The CSV is missing required column(s): \(columns.joined(separator: ", "))."
        case .noValidStudents:
            return "No valid student rows were found. Check that names and Year 1–6 values are present."
        }
    }
}

enum StudentCSVImporter {
    static func parse(_ text: String) throws -> StudentCSVImport {
        let rows = CSVRows.parse(text)
        guard let first = rows.first, !first.allSatisfy({ $0.trimmed.isEmpty }) else {
            throw StudentCSVImportError.emptyFile
        }

        let headers = first.enumerated().reduce(into: [String: Int]()) { output, item in
            let key = normaliseHeader(item.element)
            if output[key] == nil { output[key] = item.offset }
        }
        let nameIndex = index(in: headers, aliases: ["name", "student", "studentname", "fullname"])
        let yearIndex = index(in: headers, aliases: ["year", "yeargroup", "grade"])
        var missing: [String] = []
        if nameIndex == nil { missing.append("Name") }
        if yearIndex == nil { missing.append("Year") }
        guard let nameIndex, let yearIndex, missing.isEmpty else {
            throw StudentCSVImportError.missingColumns(missing)
        }

        let genderIndex = index(in: headers, aliases: ["gender", "gendergroup", "sex"])
        let classIndex = index(in: headers, aliases: ["class", "classname", "homeroom"])
        let factionIndex = index(in: headers, aliases: ["faction", "house", "team"])

        var athletes: [Athlete] = []
        var rejectedRows: [Int] = []
        for (offset, row) in rows.dropFirst().enumerated() {
            let rowNumber = offset + 2
            let name = value(at: nameIndex, in: row).trimmed
            guard !name.isEmpty,
                  let year = parseYear(value(at: yearIndex, in: row)),
                  (1...6).contains(year)
            else {
                if !row.allSatisfy({ $0.trimmed.isEmpty }) { rejectedRows.append(rowNumber) }
                continue
            }

            athletes.append(
                Athlete(
                    name: name,
                    year: year,
                    gender: parseGender(genderIndex.map { value(at: $0, in: row) } ?? ""),
                    faction: factionIndex.map { value(at: $0, in: row) } ?? "Unassigned",
                    className: classIndex.map { value(at: $0, in: row) } ?? "Unassigned"
                )
            )
        }

        guard !athletes.isEmpty else { throw StudentCSVImportError.noValidStudents }
        return StudentCSVImport(athletes: athletes, rejectedRows: rejectedRows)
    }

    private static func value(at index: Int, in row: [String]) -> String {
        row.indices.contains(index) ? row[index] : ""
    }

    private static func parseYear(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        return Int(digits)
    }

    private static func parseGender(_ raw: String) -> AthleteGender {
        switch raw.trimmed.lowercased() {
        case "boy", "boys", "male", "m":
            return .boys
        case "girl", "girls", "female", "f":
            return .girls
        default:
            return .unspecified
        }
    }

    private static func index(in headers: [String: Int], aliases: [String]) -> Int? {
        aliases.lazy.compactMap { headers[$0] }.first
    }

    private static func normaliseHeader(_ raw: String) -> String {
        raw.lowercased().filter(\.isLetter)
    }
}

private enum CSVRows {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)

            if character == "\"" {
                if quoted, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = text.index(after: next)
                    continue
                }
                quoted.toggle()
            } else if character == ",", !quoted {
                row.append(field)
                field = ""
            } else if (character == "\n" || character == "\r"), !quoted {
                if character == "\r", next < text.endIndex, text[next] == "\n" {
                    index = next
                }
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }
            index = text.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
