import Foundation

protocol AthleticsPersisting: Sendable {
    func load() throws -> AthleticsState
    func save(_ state: AthleticsState) throws
    func reset(to state: AthleticsState) throws
}

enum AthleticsPersistenceError: LocalizedError, Sendable {
    case unsupportedSchema(found: Int, supported: Int)
    case corruptArchive(primary: String, backup: String?)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchema(found, supported):
            return "This Corso file was created by a newer app (schema \(found); this app supports \(supported)). Update Corso before opening it."
        case let .corruptArchive(primary, backup):
            if let backup {
                return "The athletics file and its backup could not be read. Main: \(primary). Backup: \(backup)."
            } else {
                return "The athletics file could not be read and no valid backup exists: \(primary)."
            }
        }
    }
}

private struct AthleticsArchive: Codable, Sendable {
    static let currentSchemaVersion = 6

    var schemaVersion: Int
    var savedAt: Date
    var state: AthleticsState
}

private struct ArchiveSchemaHeader: Decodable {
    var schemaVersion: Int
}

struct FileAthleticsPersistence: AthleticsPersisting {
    private let fileURL: URL
    private var backupURL: URL { fileURL.appendingPathExtension("backup") }

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseURL.appendingPathComponent("CorsoAthletics", isDirectory: true)
        fileURL = directory.appendingPathComponent("athletics-state.json")
    }

    /// Test/support initializer that avoids depending on global app folders.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> AthleticsState {
        let manager = FileManager.default
        guard manager.fileExists(atPath: fileURL.path) else {
            if manager.fileExists(atPath: backupURL.path) {
                return try decode(Data(contentsOf: backupURL))
            }
            return .empty
        }

        do {
            return try decode(Data(contentsOf: fileURL))
        } catch let primaryError as AthleticsPersistenceError {
            // A newer-schema error must not be obscured by an older backup.
            if case .unsupportedSchema = primaryError { throw primaryError }
            return try recoverFromBackup(primaryError: primaryError)
        } catch {
            return try recoverFromBackup(primaryError: error)
        }
    }

    func save(_ state: AthleticsState) throws {
        let manager = FileManager.default
        try manager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // Student data stays local to the protected app container. Excluding
        // this directory from device-cloud backups avoids silently copying a
        // pilot roster to a personal backup service; staff export backups only
        // through an approved school process.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = fileURL.deletingLastPathComponent()
        try directory.setResourceValues(values)

        var state = state
        state.normalize()
        let archive = AthleticsArchive(
            schemaVersion: AthleticsArchive.currentSchemaVersion,
            savedAt: .now,
            state: state
        )
        let data = try Self.makeEncoder().encode(archive)

        // Keep the last readable generation. A corrupt primary is never copied
        // over a valid backup.
        if manager.fileExists(atPath: fileURL.path),
           let previous = try? Data(contentsOf: fileURL),
           (try? decode(previous)) != nil {
            try previous.write(to: backupURL, options: [.atomic, .completeFileProtection])
        }

        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        var primary = fileURL
        try primary.setResourceValues(values)
        if FileManager.default.fileExists(atPath: backupURL.path) {
            var backup = backupURL
            try backup.setResourceValues(values)
        }
    }

    func reset(to state: AthleticsState) throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: fileURL.path) { try manager.removeItem(at: fileURL) }
        if manager.fileExists(atPath: backupURL.path) { try manager.removeItem(at: backupURL) }
        try save(state)
    }

    private func recoverFromBackup(primaryError: Error) throws -> AthleticsState {
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw AthleticsPersistenceError.corruptArchive(
                primary: primaryError.localizedDescription,
                backup: nil
            )
        }
        do {
            return try decode(Data(contentsOf: backupURL))
        } catch {
            throw AthleticsPersistenceError.corruptArchive(
                primary: primaryError.localizedDescription,
                backup: error.localizedDescription
            )
        }
    }

    private func decode(_ data: Data) throws -> AthleticsState {
        // Read the small header independently so a future, incompatible state
        // still produces a clear "update the app" error rather than corruption.
        if let header = try? Self.makeDecoder().decode(ArchiveSchemaHeader.self, from: data),
           header.schemaVersion > AthleticsArchive.currentSchemaVersion {
            throw AthleticsPersistenceError.unsupportedSchema(
                found: header.schemaVersion,
                supported: AthleticsArchive.currentSchemaVersion
            )
        }

        // Current/versioned storage.
        if let archive = try? Self.makeDecoder().decode(AthleticsArchive.self, from: data) {
            guard archive.schemaVersion <= AthleticsArchive.currentSchemaVersion else {
                throw AthleticsPersistenceError.unsupportedSchema(
                    found: archive.schemaVersion,
                    supported: AthleticsArchive.currentSchemaVersion
                )
            }
            var state = archive.state
            state.normalize()
            return state
        }

        // Version 0/1 native files stored AthleticsState as the JSON root.
        do {
            var legacy = try Self.makeDecoder().decode(AthleticsState.self, from: data)
            legacy.normalize()
            return legacy
        } catch {
            throw AthleticsPersistenceError.corruptArchive(
                primary: error.localizedDescription,
                backup: nil
            )
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
