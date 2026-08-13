import PencilKit
import XCTest
@testable import AppModule

@MainActor
final class WhiteboardLibraryTests: XCTestCase {
    func testNewLibraryCreatesAndPersistsFirstBoard() throws {
        let directory = temporaryDirectory()
        let store = try WhiteboardDiskStore(directoryURL: directory)
        let library = WhiteboardLibrary(store: store)

        XCTAssertEqual(library.boards.count, 1)
        XCTAssertEqual(library.selectedBoard.title, "Training board")

        library.renameSelectedBoard(to: "  Thursday sprints  ")
        library.createBoard(title: "Relay order", paper: .athleticsField)
        library.saveNow()

        let reloaded = WhiteboardLibrary(store: store)
        XCTAssertEqual(reloaded.boards.count, 2)
        XCTAssertEqual(reloaded.selectedBoard.title, "Relay order")
        XCTAssertEqual(reloaded.selectedBoard.paper, .athleticsField)
        XCTAssertTrue(reloaded.boards.contains(where: { $0.title == "Thursday sprints" }))
    }

    func testDeletingOnlyBoardProvidesSafeReplacement() throws {
        let library = WhiteboardLibrary(store: try WhiteboardDiskStore(directoryURL: temporaryDirectory()))
        let originalID = library.selectedBoardID

        library.deleteSelectedBoard()

        XCTAssertEqual(library.boards.count, 1)
        XCTAssertNotEqual(library.selectedBoardID, originalID)
    }

    func testClearDrawingBumpsRevisionAndRemovesInk() throws {
        let library = WhiteboardLibrary(store: try WhiteboardDiskStore(directoryURL: temporaryDirectory()))
        let startingRevision = library.canvasRevision
        library.replaceSelectedDrawing(PKDrawing())

        library.clearSelectedDrawing()

        XCTAssertEqual(library.canvasRevision, startingRevision + 1)
        XCTAssertTrue(library.selectedBoard.drawing.strokes.isEmpty)
    }

    func testTeamLayoutBackgroundPersistsAndDuplicates() throws {
        let store = try WhiteboardDiskStore(directoryURL: temporaryDirectory())
        let library = WhiteboardLibrary(store: store)
        let background = Data([0x43, 0x4F, 0x52, 0x53, 0x4F])

        library.createBoard(
            title: "Pass Ball workshop",
            backgroundImageData: background
        )
        library.duplicateSelectedBoard()
        library.saveNow()

        let reloaded = WhiteboardLibrary(store: store)
        XCTAssertEqual(reloaded.boards.count, 3)
        XCTAssertEqual(reloaded.selectedBoard.backgroundImageData, background)
        XCTAssertEqual(
            reloaded.boards.filter { $0.backgroundImageData == background }.count,
            2
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("WhiteboardTests-\(UUID().uuidString)", isDirectory: true)
    }
}
