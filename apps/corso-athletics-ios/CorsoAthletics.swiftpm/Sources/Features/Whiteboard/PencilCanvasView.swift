import Observation
import PencilKit
import SwiftUI
import UIKit

enum WhiteboardCanvasMetrics {
    static let pageSize = CGSize(width: 1_400, height: 1_000)
}

@MainActor
@Observable
final class PencilCanvasController {
    private(set) var canUndo = false
    private(set) var canRedo = false

    @ObservationIgnored weak var canvasView: PKCanvasView?

    func register(_ canvasView: PKCanvasView) {
        self.canvasView = canvasView
        refreshUndoState()
    }

    func unregister(_ canvasView: PKCanvasView) {
        guard self.canvasView === canvasView else { return }
        self.canvasView = nil
        canUndo = false
        canRedo = false
    }

    func undo() {
        canvasView?.undoManager?.undo()
        refreshUndoState()
    }

    func redo() {
        canvasView?.undoManager?.redo()
        refreshUndoState()
    }

    func refreshUndoState() {
        canUndo = canvasView?.undoManager?.canUndo == true
        canRedo = canvasView?.undoManager?.canRedo == true
    }
}

struct PencilCanvasView: UIViewRepresentable {
    let boardID: UUID
    let drawing: PKDrawing
    let canvasRevision: Int
    let paper: WhiteboardPaper
    let allowsFingerDrawing: Bool
    let showsToolPicker: Bool
    let controller: PencilCanvasController
    let onDrawingChanged: (PKDrawing) -> Void
    let onSqueeze: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            controller: controller,
            onDrawingChanged: onDrawingChanged,
            onSqueeze: onSqueeze
        )
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView(frame: .zero)
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: UIColor(CorsoTheme.ink), width: 5)
        canvas.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.contentSize = WhiteboardCanvasMetrics.pageSize
        canvas.minimumZoomScale = 0.45
        canvas.maximumZoomScale = 3
        canvas.bouncesZoom = true
        canvas.alwaysBounceHorizontal = true
        canvas.alwaysBounceVertical = true
        canvas.keyboardDismissMode = .onDrag

        context.coordinator.attach(to: canvas, boardID: boardID, revision: canvasRevision)
        context.coordinator.applyPaper(paper, to: canvas)
        context.coordinator.setToolPickerVisible(showsToolPicker, for: canvas)
        controller.register(canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.onDrawingChanged = onDrawingChanged
        context.coordinator.onSqueeze = onSqueeze
        canvas.drawingPolicy = allowsFingerDrawing ? .anyInput : .pencilOnly
        context.coordinator.applyPaper(paper, to: canvas)
        context.coordinator.setToolPickerVisible(showsToolPicker, for: canvas)

        if context.coordinator.loadedBoardID != boardID
            || context.coordinator.loadedRevision != canvasRevision {
            context.coordinator.isLoadingDrawing = true
            canvas.drawing = drawing
            canvas.undoManager?.removeAllActions()
            context.coordinator.loadedBoardID = boardID
            context.coordinator.loadedRevision = canvasRevision
            context.coordinator.isLoadingDrawing = false
            controller.refreshUndoState()
        }
    }

    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        coordinator.detach(from: canvas)
    }

    @MainActor
    final class Coordinator: NSObject, PKCanvasViewDelegate, UIPencilInteractionDelegate {
        let toolPicker = PKToolPicker()
        let pencilInteraction = UIPencilInteraction()
        let controller: PencilCanvasController
        var onDrawingChanged: (PKDrawing) -> Void
        var onSqueeze: () -> Void
        var loadedBoardID: UUID?
        var loadedRevision = -1
        var isLoadingDrawing = false
        private var appliedPaper: WhiteboardPaper?
        private let defaultInkingTool = PKInkingTool(
            .pen,
            color: UIColor(CorsoTheme.ink),
            width: 5
        )

        init(
            controller: PencilCanvasController,
            onDrawingChanged: @escaping (PKDrawing) -> Void,
            onSqueeze: @escaping () -> Void
        ) {
            self.controller = controller
            self.onDrawingChanged = onDrawingChanged
            self.onSqueeze = onSqueeze
            super.init()
        }

        func attach(to canvas: PKCanvasView, boardID: UUID, revision: Int) {
            loadedBoardID = boardID
            loadedRevision = revision
            toolPicker.addObserver(canvas)
            pencilInteraction.delegate = self
            canvas.addInteraction(pencilInteraction)
        }

        func detach(from canvas: PKCanvasView) {
            toolPicker.setVisible(false, forFirstResponder: canvas)
            toolPicker.removeObserver(canvas)
            canvas.removeInteraction(pencilInteraction)
            controller.unregister(canvas)
        }

        func setToolPickerVisible(_ isVisible: Bool, for canvas: PKCanvasView) {
            toolPicker.setVisible(isVisible, forFirstResponder: canvas)
            if isVisible, !canvas.isFirstResponder {
                Task { @MainActor in
                    canvas.becomeFirstResponder()
                }
            }
        }

        func applyPaper(_ paper: WhiteboardPaper, to canvas: PKCanvasView) {
            guard appliedPaper != paper else { return }
            canvas.backgroundColor = UIColor(patternImage: WhiteboardPaperRenderer.tile(for: paper))
            appliedPaper = paper
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isLoadingDrawing else { return }
            onDrawingChanged(canvasView.drawing)
            controller.refreshUndoState()
        }

        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            guard let canvas = interaction.view as? PKCanvasView else { return }
            if canvas.tool is PKEraserTool {
                canvas.tool = defaultInkingTool
            } else {
                canvas.tool = PKEraserTool(.vector)
            }
        }

        @available(iOS 17.5, *)
        func pencilInteraction(
            _ interaction: UIPencilInteraction,
            didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze
        ) {
            guard squeeze.phase == .ended,
                  let canvas = interaction.view as? PKCanvasView else { return }
            onSqueeze()
            toolPicker.setVisible(true, forFirstResponder: canvas)
            canvas.becomeFirstResponder()
        }
    }
}

@MainActor
enum WhiteboardPaperRenderer {
    static func tile(for paper: WhiteboardPaper) -> UIImage {
        switch paper {
        case .plain:
            return solidTile(color: .white)
        case .grid:
            return gridTile()
        case .athleticsField:
            return fieldTile()
        }
    }

    static func draw(_ paper: WhiteboardPaper, in rect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        context.setLineWidth(1)
        switch paper {
        case .plain:
            break
        case .grid:
            context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.12).cgColor)
            stride(from: rect.minX, through: rect.maxX, by: 36).forEach { x in
                context.move(to: CGPoint(x: x, y: rect.minY))
                context.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            stride(from: rect.minY, through: rect.maxY, by: 36).forEach { y in
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.strokePath()
        case .athleticsField:
            context.setStrokeColor(UIColor.systemGreen.withAlphaComponent(0.18).cgColor)
            stride(from: rect.minY, through: rect.maxY, by: 72).forEach { y in
                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            context.strokePath()
            context.setStrokeColor(UIColor.systemOrange.withAlphaComponent(0.35).cgColor)
            context.setLineWidth(5)
            let inset = rect.insetBy(dx: 72, dy: 72)
            context.strokeEllipse(in: inset)
            context.strokeEllipse(in: inset.insetBy(dx: 32, dy: 32))
        }
        context.restoreGState()
    }

    private static func solidTile(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 2, height: 2)))
        }
    }

    private static func gridTile() -> UIImage {
        let size = CGSize(width: 36, height: 36)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.12).cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: 35.5, y: 0))
            context.cgContext.addLine(to: CGPoint(x: 35.5, y: 36))
            context.cgContext.move(to: CGPoint(x: 0, y: 35.5))
            context.cgContext.addLine(to: CGPoint(x: 36, y: 35.5))
            context.cgContext.strokePath()
        }
    }

    private static func fieldTile() -> UIImage {
        let size = CGSize(width: 144, height: 144)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(red: 0.97, green: 0.99, blue: 0.97, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.setStrokeColor(UIColor.systemGreen.withAlphaComponent(0.16).cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: 0, y: 71.5))
            context.cgContext.addLine(to: CGPoint(x: 144, y: 71.5))
            context.cgContext.strokePath()
        }
    }
}
