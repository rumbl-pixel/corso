import SwiftUI
import UIKit

enum TeamBoardWhiteboardError: LocalizedError {
    case couldNotRender
    case couldNotSave(String)

    var errorDescription: String? {
        switch self {
        case .couldNotRender:
            return "The team layout could not be prepared for the whiteboard."
        case .couldNotSave(let message):
            return message
        }
    }
}

@MainActor
enum TeamBoardWhiteboardService {
    static func createBoard(
        scope: TeamBoardScope,
        board: TeamBoard,
        athletes: [Athlete]
    ) throws -> String {
        let title = "\(scope.event.rawValue) · \(scope.division.rawValue) \(scope.gender?.rawValue ?? "")"
            .trimmingCharacters(in: .whitespaces)
        guard let imageData = render(scope: scope, board: board, athletes: athletes).pngData() else {
            throw TeamBoardWhiteboardError.couldNotRender
        }

        let library = WhiteboardLibrary()
        _ = library.createBoard(
            title: title,
            paper: .plain,
            backgroundImageData: imageData
        )
        if let error = library.persistenceError {
            throw TeamBoardWhiteboardError.couldNotSave(error)
        }
        return title
    }

    private static func render(
        scope: TeamBoardScope,
        board: TeamBoard,
        athletes: [Athlete]
    ) -> UIImage {
        let size = WhiteboardCanvasMetrics.pageSize
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1).setFill()
            context.fill(bounds)

            drawText(
                "\(scope.event.rawValue) COACHES WORKSHOP",
                in: CGRect(x: 60, y: 48, width: 1_280, height: 54),
                font: .systemFont(ofSize: 32, weight: .black),
                color: UIColor(CorsoTheme.navy)
            )
            drawText(
                "\(scope.stage.rawValue) · \(scope.division.rawValue) · \(scope.gender?.rawValue ?? "All groups")",
                in: CGRect(x: 60, y: 106, width: 1_280, height: 34),
                font: .systemFont(ofSize: 18, weight: .semibold),
                color: UIColor(CorsoTheme.muted)
            )
            drawText(
                scope.event.guidance,
                in: CGRect(x: 60, y: 148, width: 1_280, height: 54),
                font: .systemFont(ofSize: 16, weight: .medium),
                color: UIColor(CorsoTheme.navy)
            )

            let lookup = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0) })
            let teamA = board.teamA.compactMap { lookup[$0] }
            let teamB = board.teamB.compactMap { lookup[$0] }
            drawTeam(
                "TEAM A",
                athletes: teamA,
                leaderID: board.teamALeader,
                event: scope.event,
                frame: CGRect(x: 60, y: 230, width: 615, height: 700)
            )
            drawTeam(
                "TEAM B",
                athletes: teamB,
                leaderID: board.teamBLeader,
                event: scope.event,
                frame: CGRect(x: 725, y: 230, width: 615, height: 700)
            )
        }
    }

    private static func drawTeam(
        _ title: String,
        athletes: [Athlete],
        leaderID: UUID?,
        event: TeamEvent,
        frame: CGRect
    ) {
        let path = UIBezierPath(roundedRect: frame, cornerRadius: 24)
        UIColor.white.setFill()
        path.fill()
        UIColor(CorsoTheme.sand).setStroke()
        path.lineWidth = 2
        path.stroke()

        drawText(
            title,
            in: CGRect(x: frame.minX + 24, y: frame.minY + 22, width: frame.width - 48, height: 38),
            font: .systemFont(ofSize: 23, weight: .black),
            color: UIColor(CorsoTheme.navy)
        )

        var y = frame.minY + 78
        for (index, athlete) in athletes.prefix(12).enumerated() {
            let isLeader = leaderID == athlete.id
            let row = CGRect(x: frame.minX + 20, y: y, width: frame.width - 40, height: 46)
            let rowPath = UIBezierPath(roundedRect: row, cornerRadius: 12)
            (isLeader ? UIColor(CorsoTheme.orange).withAlphaComponent(0.13) : UIColor(CorsoTheme.navy).withAlphaComponent(0.045)).setFill()
            rowPath.fill()

            drawText(
                "\(index + 1)",
                in: CGRect(x: row.minX + 10, y: row.minY + 10, width: 34, height: 25),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .black),
                color: UIColor(CorsoTheme.orange)
            )
            drawText(
                athlete.name,
                in: CGRect(x: row.minX + 48, y: row.minY + 6, width: 290, height: 22),
                font: .systemFont(ofSize: 16, weight: .bold),
                color: UIColor(CorsoTheme.navy)
            )
            drawText(
                event.positionLabel(at: index, count: athletes.count, isLeader: isLeader),
                in: CGRect(x: row.minX + 48, y: row.minY + 26, width: 290, height: 16),
                font: .systemFont(ofSize: 11, weight: .semibold),
                color: UIColor(CorsoTheme.muted)
            )
            drawText(
                "Yr \(athlete.year) · \(athlete.className)",
                in: CGRect(x: row.maxX - 160, y: row.minY + 14, width: 145, height: 20),
                font: .systemFont(ofSize: 12, weight: .medium),
                color: UIColor(CorsoTheme.muted),
                alignment: .right
            )
            y += 52
        }
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        ).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
