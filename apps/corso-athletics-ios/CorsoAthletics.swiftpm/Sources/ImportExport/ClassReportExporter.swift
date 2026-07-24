import SwiftUI
import UIKit

struct ClassReportExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
enum ClassReportExporter {
    static func export(
        schoolName: String,
        athletes: [Athlete],
        results: [ResultRecord],
        event: AthleticsEvent
    ) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 42
        let rowHeight: CGFloat = 25
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            var y: CGFloat = 0

            func draw(
                _ text: String,
                x: CGFloat = 42,
                at yPosition: CGFloat,
                width: CGFloat = 511,
                font: UIFont,
                color: UIColor = .black
            ) {
                NSString(string: text).draw(
                    in: CGRect(x: x, y: yPosition, width: width, height: rowHeight),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
            }

            func beginPage() {
                context.beginPage()
                UIColor.white.setFill()
                context.cgContext.fill(page)
                y = margin
                draw("\(schoolName) · \(event.rawValue) class report", at: y, font: .boldSystemFont(ofSize: 17))
                y += 25
                draw("Generated \(Date.now.formatted(date: .abbreviated, time: .shortened))", at: y, font: .systemFont(ofSize: 9), color: .darkGray)
                y += 25
                draw("Student", at: y, width: 220, font: .boldSystemFont(ofSize: 9))
                draw("Year / Class", x: 270, at: y, width: 90, font: .boldSystemFont(ofSize: 9))
                draw("Faction", x: 365, at: y, width: 80, font: .boldSystemFont(ofSize: 9))
                draw("Best", x: 450, at: y, width: 95, font: .boldSystemFont(ofSize: 9))
                y += 18
            }

            beginPage()
            for athlete in athletes {
                if y + rowHeight > page.height - margin { beginPage() }
                let best = ResultRanking.bestResult(for: athlete.id, event: event, results: results)
                let bestText = best.map {
                    $0.value.formatted(.number.precision(.fractionLength(2))) + (event.isTimed ? " s" : " m")
                } ?? "—"
                draw(athlete.name, at: y, width: 220, font: .systemFont(ofSize: 10))
                draw("Y\(athlete.year) · \(athlete.className)", x: 270, at: y, width: 90, font: .systemFont(ofSize: 9))
                draw(athlete.faction, x: 365, at: y, width: 80, font: .systemFont(ofSize: 9))
                draw(bestText, x: 450, at: y, width: 95, font: .monospacedDigitSystemFont(ofSize: 9, weight: .semibold))
                y += rowHeight
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: y - 5))
                line.addLine(to: CGPoint(x: page.width - margin, y: y - 5))
                UIColor.lightGray.setStroke()
                line.lineWidth = 0.5
                line.stroke()
            }
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corso-Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Corso-\(event.rawValue)-Class-Report.pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}

struct ClassReportShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
