import Foundation
import UIKit

@MainActor
enum PermissionSlipExporter {
    static func export(
        schoolName: String,
        kind: PermissionSlipKind,
        settings: PermissionSlipSettings,
        athletes: [Athlete]
    ) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            for athlete in athletes {
                context.beginPage()
                drawSlip(
                    in: context.cgContext,
                    page: page,
                    schoolName: schoolName,
                    kind: kind,
                    settings: settings,
                    athlete: athlete
                )
            }
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Corso-Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(
            "corso-\(kind == .provisionalTraining ? "training" : "interschool")-permission-\(Date.now.attendanceKey).pdf"
        )
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func render(
        _ text: String,
        athlete: Athlete,
        kind: PermissionSlipKind,
        settings: PermissionSlipSettings
    ) -> String {
        let values = [
            "studentName": athlete.name,
            "studentYear": String(athlete.year),
            "studentClass": athlete.className,
            "studentFaction": athlete.faction,
            "studentEvents": athlete.events.isEmpty
                ? "To be confirmed"
                : athlete.events.map(\.rawValue).joined(separator: ", "),
            "trainingDetails": settings.trainingDetails,
            "carnivalDetails": settings.carnivalDetails,
            "contactName": settings.contactName,
            "contactDetails": settings.contactDetails
        ]
        return values.reduce(text) { output, value in
            output.replacingOccurrences(of: "{{\(value.key)}}", with: value.value)
        }
    }

    private static func drawSlip(
        in context: CGContext,
        page: CGRect,
        schoolName: String,
        kind: PermissionSlipKind,
        settings: PermissionSlipSettings,
        athlete: Athlete
    ) {
        UIColor.white.setFill()
        context.fill(page)

        let margin: CGFloat = 52
        let contentWidth = page.width - margin * 2
        let template = settings[kind]
        var cursor: CGFloat = 48

        cursor += draw(
            schoolName,
            rect: CGRect(x: margin, y: cursor, width: contentWidth, height: 24),
            font: .systemFont(ofSize: 12, weight: .semibold),
            color: UIColor(red: 0.29, green: 0.35, blue: 0.43, alpha: 1)
        ) + 10

        let title = render(template.title, athlete: athlete, kind: kind, settings: settings)
        cursor += draw(
            title,
            rect: CGRect(x: margin, y: cursor, width: contentWidth, height: 80),
            font: .systemFont(ofSize: 24, weight: .bold),
            color: UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 1)
        ) + 12

        context.setStrokeColor(UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 1).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: margin, y: cursor))
        context.addLine(to: CGPoint(x: page.width - margin, y: cursor))
        context.strokePath()
        cursor += 22

        let detailsRect = CGRect(x: margin, y: cursor, width: contentWidth, height: 72)
        UIColor(red: 0.92, green: 0.95, blue: 0.97, alpha: 1).setFill()
        UIBezierPath(roundedRect: detailsRect, cornerRadius: 8).fill()
        _ = draw(
            "Student: \(athlete.name)\nYear / class: Year \(athlete.year) · \(athlete.className)",
            rect: detailsRect.insetBy(dx: 14, dy: 12),
            font: .systemFont(ofSize: 12.5, weight: .semibold),
            color: UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 1)
        )
        cursor = detailsRect.maxY + 24

        let body = render(template.body, athlete: athlete, kind: kind, settings: settings)
        cursor += draw(
            body,
            rect: CGRect(x: margin, y: cursor, width: contentWidth, height: 340),
            font: .systemFont(ofSize: 12.5),
            color: UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 1),
            lineSpacing: 4
        )

        let acknowledgement = render(
            template.acknowledgement,
            athlete: athlete,
            kind: kind,
            settings: settings
        )
        let signatureTop = max(cursor + 42, page.height - 180)
        _ = draw(
            "☐ \(acknowledgement)",
            rect: CGRect(x: margin, y: signatureTop, width: contentWidth, height: 54),
            font: .systemFont(ofSize: 11.5, weight: .semibold),
            color: UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 1)
        )

        let lineY = page.height - 77
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: lineY))
        context.addLine(to: CGPoint(x: margin + 220, y: lineY))
        context.move(to: CGPoint(x: margin + 280, y: lineY))
        context.addLine(to: CGPoint(x: page.width - margin, y: lineY))
        context.strokePath()
        _ = draw(
            "Parent/carer signature",
            rect: CGRect(x: margin, y: lineY + 5, width: 220, height: 18),
            font: .systemFont(ofSize: 9.5),
            color: .darkGray
        )
        _ = draw(
            "Date",
            rect: CGRect(x: margin + 280, y: lineY + 5, width: 100, height: 18),
            font: .systemFont(ofSize: 9.5),
            color: .darkGray
        )
    }

    @discardableResult
    private static func draw(
        _ text: String,
        rect: CGRect,
        font: UIFont,
        color: UIColor,
        lineSpacing: CGFloat = 2
    ) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let measured = attributed.boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return min(ceil(measured.height), rect.height)
    }
}
