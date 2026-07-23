import PencilKit
import SwiftUI

struct WhiteboardView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var library = WhiteboardLibrary()
    @State private var canvasController = PencilCanvasController()
    @State private var showsToolPicker = true
    @State private var allowsFingerDrawing = false
    @State private var renameText = ""
    @State private var isRenaming = false
    @State private var isConfirmingClear = false
    @State private var isConfirmingDelete = false
    @State private var exportItem: WhiteboardExportItem?
    @State private var exportError: String?

    var body: some View {
        GeometryReader { proxy in
            Group {
                if proxy.size.width >= 1_020 {
                    HStack(spacing: 18) {
                        boardSidebar
                            .frame(width: 230)
                        workspace(showsCompactBoardPicker: false)
                    }
                } else {
                    workspace(showsCompactBoardPicker: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(22)
        .background(CorsoTheme.cream.ignoresSafeArea())
        .alert("Rename board", isPresented: $isRenaming) {
            TextField("Board name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") { library.renameSelectedBoard(to: renameText) }
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .confirmationDialog(
            "Clear every mark from this board?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear board", role: .destructive) { library.clearSelectedDrawing() }
        } message: {
            Text("This cannot be undone after you leave the board.")
        }
        .confirmationDialog(
            "Delete “\(library.selectedBoard.title)”?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete board", role: .destructive) { library.deleteSelectedBoard() }
        } message: {
            Text("The board and its handwriting will be removed from this iPad.")
        }
        .sheet(item: $exportItem) { item in
            WhiteboardShareSheet(url: item.url)
        }
        .alert("Export failed", isPresented: exportErrorBinding) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "The board could not be exported.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { library.flushPendingSave() }
        }
    }

    private func workspace(showsCompactBoardPicker: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if showsCompactBoardPicker {
                compactBoardPicker
            }
            drawingToolbar
            canvas
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var boardSidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("BOARDS")
                    .font(.caption.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(CorsoTheme.muted)
                Spacer()
                Button {
                    library.createBoard()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(CorsoTheme.orange)
                .accessibilityLabel("New whiteboard")
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(library.boards) { board in
                        BoardRow(board: board, isSelected: board.id == library.selectedBoardID) {
                            library.select(board.id)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Label("Saved on this iPad", systemImage: "lock.iphone")
                    .font(.caption.weight(.semibold))
                Text("Export important boards to Files or your school drive.")
                    .font(.caption2)
                    .foregroundStyle(CorsoTheme.muted)
            }

            if let error = library.persistenceError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity)
        .corsoCard()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            CorsoSectionTitle(eyebrow: "Apple Pencil", title: library.selectedBoard.title)
            Spacer()
            HStack(spacing: 6) {
                if library.isSaving {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CorsoTheme.green)
                }
                Text(library.isSaving ? "Saving" : "Saved")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CorsoTheme.muted)
            }
        }
    }

    private var drawingToolbar: some View {
        ViewThatFits(in: .horizontal) {
            fullDrawingToolbar
                .fixedSize(horizontal: true, vertical: false)
            compactDrawingToolbar
        }
    }

    private var fullDrawingToolbar: some View {
        HStack(spacing: 10) {
            Button {
                canvasController.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canvasController.canUndo)

            Button {
                canvasController.redo()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!canvasController.canRedo)

            Divider().frame(height: 24)

            Toggle(isOn: $showsToolPicker) {
                Label("Tools", systemImage: "pencil.tip.crop.circle")
            }
            .toggleStyle(.button)
            .tint(CorsoTheme.orange)

            Toggle(isOn: $allowsFingerDrawing) {
                Label("Finger ink", systemImage: "hand.draw")
            }
            .toggleStyle(.button)
            .tint(CorsoTheme.orange)
            .accessibilityHint("When off, one finger pans and only Apple Pencil writes")

            Picker("Paper", selection: paperBinding) {
                ForEach(WhiteboardPaper.allCases) { paper in
                    Text(paper.rawValue).tag(paper)
                }
            }
            .frame(maxWidth: 180)

            Spacer()

            exportMenu(showsTitle: true)
            .buttonStyle(.bordered)

            boardActionsMenu
        }
        .buttonStyle(.bordered)
        .labelStyle(.titleAndIcon)
    }

    private var compactDrawingToolbar: some View {
        HStack(spacing: 8) {
            Button {
                canvasController.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 30, height: 30)
            }
            .disabled(!canvasController.canUndo)
            .accessibilityLabel("Undo")

            Button {
                canvasController.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 30, height: 30)
            }
            .disabled(!canvasController.canRedo)
            .accessibilityLabel("Redo")

            Toggle(isOn: $showsToolPicker) {
                Image(systemName: "pencil.tip.crop.circle")
                    .frame(width: 30, height: 30)
            }
            .toggleStyle(.button)
            .tint(CorsoTheme.orange)
            .accessibilityLabel("Drawing tools")

            Menu {
                Toggle("Allow finger drawing", isOn: $allowsFingerDrawing)
                Picker("Paper", selection: paperBinding) {
                    ForEach(WhiteboardPaper.allCases) { paper in
                        Text(paper.rawValue).tag(paper)
                    }
                }
            } label: {
                Image(systemName: allowsFingerDrawing ? "hand.draw.fill" : "hand.draw")
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Input and paper options")

            Spacer(minLength: 4)

            exportMenu(showsTitle: false)
            boardActionsMenu
        }
        .buttonStyle(.bordered)
    }

    private func exportMenu(showsTitle: Bool) -> some View {
        Menu {
            ForEach(WhiteboardExportFormat.allCases) { format in
                Button(format.rawValue) { export(format) }
            }
        } label: {
            if showsTitle {
                Label("Export", systemImage: "square.and.arrow.up")
            } else {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 30, height: 30)
            }
        }
        .accessibilityLabel("Export board")
    }

    private var boardActionsMenu: some View {
        Menu {
            Button("Rename", systemImage: "pencil") {
                renameText = library.selectedBoard.title
                isRenaming = true
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                library.duplicateSelectedBoard()
            }
            Divider()
            Button("Clear board", systemImage: "eraser", role: .destructive) {
                isConfirmingClear = true
            }
            Button("Delete board", systemImage: "trash", role: .destructive) {
                isConfirmingDelete = true
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel("Board actions")
    }

    private var compactBoardPicker: some View {
        Menu {
            ForEach(library.boards) { board in
                Button {
                    library.select(board.id)
                } label: {
                    if board.id == library.selectedBoardID {
                        Label(board.title, systemImage: "checkmark")
                    } else {
                        Text(board.title)
                    }
                }
            }
            Divider()
            Button("New board", systemImage: "plus") { library.createBoard() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack")
                Text(library.selectedBoard.title)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CorsoTheme.ink)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(CorsoTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(CorsoTheme.sand, lineWidth: 1)
            }
        }
        .accessibilityLabel("Select whiteboard")
    }

    private var canvas: some View {
        ZStack(alignment: .bottomLeading) {
            PencilCanvasView(
                boardID: library.selectedBoard.id,
                drawing: library.selectedBoard.drawing,
                canvasRevision: library.canvasRevision,
                paper: library.selectedBoard.paper,
                allowsFingerDrawing: allowsFingerDrawing,
                showsToolPicker: showsToolPicker,
                controller: canvasController,
                onDrawingChanged: { library.replaceSelectedDrawing($0) },
                onSqueeze: { showsToolPicker = true }
            )

            if !allowsFingerDrawing {
                Label("Pencil writes · finger pans and zooms", systemImage: "applepencil")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CorsoTheme.sand, lineWidth: 1)
        }
        .shadow(color: CorsoTheme.navy.opacity(0.08), radius: 15, y: 6)
        .accessibilityLabel("Whiteboard canvas")
    }

    private var paperBinding: Binding<WhiteboardPaper> {
        Binding(
            get: { library.selectedBoard.paper },
            set: { library.setPaper($0) }
        )
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )
    }

    private func export(_ format: WhiteboardExportFormat) {
        library.flushPendingSave()
        do {
            exportItem = WhiteboardExportItem(
                url: try WhiteboardExporter.export(library.selectedBoard, as: format)
            )
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct BoardRow: View {
    let board: WhiteboardBoard
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: board.paper == .athleticsField ? "figure.run" : "doc.text")
                    .foregroundStyle(isSelected ? .white : CorsoTheme.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(board.title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    Text(board.updatedAt, format: .dateTime.day().month().hour().minute())
                        .font(.caption2)
                        .opacity(0.72)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? .white : CorsoTheme.ink)
            .padding(11)
            .background(isSelected ? CorsoTheme.navyRaised : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(board.title), updated \(board.updatedAt.formatted())")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
