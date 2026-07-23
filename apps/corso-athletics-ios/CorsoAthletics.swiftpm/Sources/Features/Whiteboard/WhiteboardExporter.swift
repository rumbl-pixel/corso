import PencilKit
import SwiftUI
import UIKit

enum WhiteboardExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG image"
    case pdf = "PDF document"

    var id: Self { self }
}

struct WhiteboardExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
enum WhiteboardExporter {
    static func export(_ board: WhiteboardBoard, as format: WhiteboardExportFormat) throws -> URL {
        let safeName = board.title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .prefix(60)
        let baseName = safeName.isEmpty ? "Corso-Whiteboard" : String(safeName)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corso-Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        switch format {
        case .png:
            let url = directory.appendingPathComponent("\(baseName)-\(UUID().uuidString.prefix(6)).png")
            let data = try pngData(for: board)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        case .pdf:
            let url = directory.appendingPathComponent("\(baseName)-\(UUID().uuidString.prefix(6)).pdf")
            let data = pdfData(for: board)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return url
        }
    }

    private static func pngData(for board: WhiteboardBoard) throws -> Data {
        let size = WhiteboardCanvasMetrics.pageSize
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 2
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            WhiteboardPaperRenderer.draw(board.paper, in: rect)
            if let data = board.backgroundImageData, let background = UIImage(data: data) {
                background.draw(in: rect)
            }
            board.drawing.image(from: rect, scale: 2).draw(in: rect)
        }
        guard let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }

    private static func pdfData(for board: WhiteboardBoard) -> Data {
        let pageRect = CGRect(origin: .zero, size: WhiteboardCanvasMetrics.pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            WhiteboardPaperRenderer.draw(board.paper, in: pageRect)
            if let data = board.backgroundImageData, let background = UIImage(data: data) {
                background.draw(in: pageRect)
            }
            board.drawing.image(from: pageRect, scale: 1).draw(in: pageRect)
        }
    }
}

struct WhiteboardShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
