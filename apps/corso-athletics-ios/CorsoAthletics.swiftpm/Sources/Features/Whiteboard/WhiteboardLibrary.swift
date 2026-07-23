import Foundation
import Observation
import PencilKit

enum WhiteboardPaper: String, Codable, CaseIterable, Identifiable, Sendable {
    case plain = "Plain"
    case grid = "Grid"
    case athleticsField = "Athletics field"

    var id: Self { self }
}

struct WhiteboardBoard: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var paper: WhiteboardPaper
    var drawingData: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        paper: WhiteboardPaper = .plain,
        drawingData: Data = PKDrawing().dataRepresentation(),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.paper = paper
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var drawing: PKDrawing {
        (try? PKDrawing(data: drawingData)) ?? PKDrawing()
    }
}

struct WhiteboardArchive: Codable, Equatable, Sendable {
    var boards: [WhiteboardBoard]
    var selectedBoardID: UUID
}

struct WhiteboardDiskStore: Sendable {
    let fileURL: URL

    init(fileManager: FileManager = .default) {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = root.appendingPathComponent("CorsoAthletics/Whiteboards", isDirectory: true)
        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        fileURL = directory.appendingPathComponent("whiteboards.json")
    }

    init(directoryURL: URL, fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        fileURL = directoryURL.appendingPathComponent("whiteboards.json")
    }

    func load() throws -> WhiteboardArchive? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try Self.makeDecoder().decode(WhiteboardArchive.self, from: data)
    }

    func save(_ archive: WhiteboardArchive) throws {
        let data = try Self.makeEncoder().encode(archive)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

@MainActor
@Observable
final class WhiteboardLibrary {
    private(set) var boards: [WhiteboardBoard]
    private(set) var selectedBoardID: UUID
    private(set) var canvasRevision = 0
    private(set) var persistenceError: String?
    private(set) var isSaving = false

    @ObservationIgnored private let store: WhiteboardDiskStore
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    init(store: WhiteboardDiskStore = WhiteboardDiskStore()) {
        self.store = store

        do {
            if let archive = try store.load(), !archive.boards.isEmpty {
                boards = archive.boards
                selectedBoardID = archive.boards.contains(where: { $0.id == archive.selectedBoardID })
                    ? archive.selectedBoardID
                    : archive.boards[0].id
            } else {
                let board = WhiteboardBoard(title: "Training board")
                boards = [board]
                selectedBoardID = board.id
            }
        } catch {
            let board = WhiteboardBoard(title: "Training board")
            boards = [board]
            selectedBoardID = board.id
            persistenceError = "Saved boards could not be opened. They have not been overwritten."
        }
    }

    var selectedBoard: WhiteboardBoard {
        boards.first(where: { $0.id == selectedBoardID }) ?? boards[0]
    }

    func select(_ boardID: UUID) {
        guard boards.contains(where: { $0.id == boardID }), selectedBoardID != boardID else { return }
        flushPendingSave()
        selectedBoardID = boardID
        canvasRevision += 1
        saveNow()
    }

    @discardableResult
    func createBoard(title: String? = nil, paper: WhiteboardPaper = .plain) -> UUID {
        let baseTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let board = WhiteboardBoard(
            title: (baseTitle?.isEmpty == false ? baseTitle! : nextUntitledName()),
            paper: paper
        )
        boards.insert(board, at: 0)
        selectedBoardID = board.id
        canvasRevision += 1
        saveNow()
        return board.id
    }

    func duplicateSelectedBoard() {
        let source = selectedBoard
        let copy = WhiteboardBoard(
            title: uniqueName(for: "\(source.title) copy"),
            paper: source.paper,
            drawingData: source.drawingData
        )
        boards.insert(copy, at: 0)
        selectedBoardID = copy.id
        canvasRevision += 1
        saveNow()
    }

    func renameSelectedBoard(to proposedName: String) {
        let trimmed = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = boards.firstIndex(where: { $0.id == selectedBoardID }) else { return }
        boards[index].title = String(trimmed.prefix(80))
        boards[index].updatedAt = .now
        saveNow()
    }

    func setPaper(_ paper: WhiteboardPaper) {
        guard let index = boards.firstIndex(where: { $0.id == selectedBoardID }) else { return }
        boards[index].paper = paper
        boards[index].updatedAt = .now
        saveNow()
    }

    func deleteSelectedBoard() {
        guard let index = boards.firstIndex(where: { $0.id == selectedBoardID }) else { return }
        boards.remove(at: index)
        if boards.isEmpty {
            let replacement = WhiteboardBoard(title: "Training board")
            boards = [replacement]
        }
        selectedBoardID = boards[min(index, boards.count - 1)].id
        canvasRevision += 1
        saveNow()
    }

    func replaceSelectedDrawing(_ drawing: PKDrawing) {
        guard let index = boards.firstIndex(where: { $0.id == selectedBoardID }) else { return }
        boards[index].drawingData = drawing.dataRepresentation()
        boards[index].updatedAt = .now
        scheduleSave()
    }

    func clearSelectedDrawing() {
        guard let index = boards.firstIndex(where: { $0.id == selectedBoardID }) else { return }
        boards[index].drawingData = PKDrawing().dataRepresentation()
        boards[index].updatedAt = .now
        canvasRevision += 1
        saveNow()
    }

    func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        isSaving = true
        defer { isSaving = false }

        do {
            try store.save(WhiteboardArchive(boards: boards, selectedBoardID: selectedBoardID))
            persistenceError = nil
        } catch {
            persistenceError = "Whiteboard changes could not be saved: \(error.localizedDescription)"
        }
    }

    func flushPendingSave() {
        guard pendingSave != nil else { return }
        saveNow()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        isSaving = true
        pendingSave = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    private func nextUntitledName() -> String {
        uniqueName(for: "New board")
    }

    private func uniqueName(for base: String) -> String {
        let existing = Set(boards.map { $0.title.lowercased() })
        guard existing.contains(base.lowercased()) else { return base }
        var suffix = 2
        while existing.contains("\(base) \(suffix)".lowercased()) {
            suffix += 1
        }
        return "\(base) \(suffix)"
    }
}
