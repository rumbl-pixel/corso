import Foundation

struct StudentCSVImportOptions: Equatable, Sendable {
    var destinationClass: String?
    var defaultYear: Int?
    var requiresClassColumn: Bool

    init(
        destinationClass: String? = nil,
        defaultYear: Int? = nil,
        requiresClassColumn: Bool = false
    ) {
        self.destinationClass = destinationClass
        self.defaultYear = defaultYear
        self.requiresClassColumn = requiresClassColumn
    }
}

struct StudentCSVImport: Sendable {
    let athletes: [Athlete]
    let rejectedRows: [Int]
}

struct StudentImportReview: Sendable {
    let studentsToImport: [Athlete]
    let duplicates: [Athlete]
}

enum StudentImportReviewer {
    static func review(_ athletes: [Athlete], against existingAthletes: [Athlete]) -> StudentImportReview {
        var identities = Set(existingAthletes.map(identity))
        var studentsToImport: [Athlete] = []
        var duplicates: [Athlete] = []

        for rawAthlete in athletes {
            var athlete = rawAthlete
            athlete.normalize()
            if identities.insert(identity(athlete)).inserted {
                studentsToImport.append(athlete)
            } else {
                duplicates.append(athlete)
            }
        }

        return StudentImportReview(
            studentsToImport: studentsToImport,
            duplicates: duplicates
        )
    }

    private static func identity(_ athlete: Athlete) -> String {
        [athlete.name, String(athlete.year), athlete.className]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")
    }
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
    static func parse(
        _ text: String,
        options: StudentCSVImportOptions = StudentCSVImportOptions()
    ) throws -> StudentCSVImport {
        let rows = CSVRows.parse(text)
        guard let first = rows.first, !first.allSatisfy({ $0.trimmed.isEmpty }) else {
            throw StudentCSVImportError.emptyFile
        }

        let headers = first.enumerated().reduce(into: [String: Int]()) { output, item in
            let key = normaliseHeader(item.element)
            if output[key] == nil { output[key] = item.offset }
        }
        let nameIndex = index(
            in: headers,
            aliases: ["name", "student", "studentname", "fullname", "displayname"]
        )
        let givenNameIndex = index(
            in: headers,
            aliases: ["firstname", "givenname", "preferredname"]
        )
        let surnameIndex = index(
            in: headers,
            aliases: ["lastname", "surname", "familyname"]
        )
        let yearIndex = index(
            in: headers,
            aliases: ["year", "yeargroup", "grade", "yearlevel"]
        )
        let classIndex = index(
            in: headers,
            aliases: ["class", "classname", "homeroom", "form", "formclass"]
        )
        let destinationClass = options.destinationClass?.trimmed.nonEmpty
        let defaultYear = options.defaultYear.flatMap { (1...6).contains($0) ? $0 : nil }
        let hasSplitName = givenNameIndex != nil && surnameIndex != nil

        var missing: [String] = []
        if nameIndex == nil && !hasSplitName { missing.append("Name (or First Name + Surname)") }
        if yearIndex == nil && defaultYear == nil { missing.append("Year") }
        if destinationClass == nil && options.requiresClassColumn && classIndex == nil {
            missing.append("Class")
        }
        guard missing.isEmpty else {
            throw StudentCSVImportError.missingColumns(missing)
        }

        let genderIndex = index(in: headers, aliases: ["gender", "gendergroup", "sex"])
        let factionIndex = index(in: headers, aliases: ["faction", "house", "team", "schoolhouse"])

        var athletes: [Athlete] = []
        var rejectedRows: [Int] = []
        for (offset, row) in rows.dropFirst().enumerated() {
            let rowNumber = offset + 2
            let name: String
            if let nameIndex {
                name = value(at: nameIndex, in: row).trimmed
            } else {
                name = [
                    givenNameIndex.map { value(at: $0, in: row).trimmed } ?? "",
                    surnameIndex.map { value(at: $0, in: row).trimmed } ?? ""
                ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            }
            let rawYear = yearIndex.map { value(at: $0, in: row).trimmed } ?? ""
            let year = rawYear.isEmpty ? defaultYear : parseYear(rawYear)
            let rawClass = classIndex.map { value(at: $0, in: row).trimmed } ?? ""
            let className = destinationClass ?? rawClass.nonEmpty ?? "Unassigned"
            let hasRequiredClass = !options.requiresClassColumn
                || destinationClass != nil
                || !rawClass.isEmpty

            guard !name.isEmpty,
                  let year,
                  (1...6).contains(year),
                  hasRequiredClass
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
                    className: className
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
    var nonEmpty: String? { isEmpty ? nil : self }
}
