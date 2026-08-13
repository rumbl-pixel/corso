import SwiftUI

enum CorsoTheme {
    static let navy = Color(red: 0.04, green: 0.12, blue: 0.23)
    static let navyRaised = Color(red: 0.06, green: 0.20, blue: 0.35)
    static let orange = Color(red: 0.96, green: 0.32, blue: 0.08)
    static let orangeDark = Color(red: 0.78, green: 0.22, blue: 0.03)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let ink = Color(red: 0.05, green: 0.13, blue: 0.24)
    static let muted = Color(red: 0.39, green: 0.45, blue: 0.55)
    static let green = Color(red: 0.12, green: 0.49, blue: 0.35)
    static let sand = Color(red: 0.87, green: 0.83, blue: 0.76)
}

struct CorsoCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CorsoTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CorsoTheme.sand.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: CorsoTheme.navy.opacity(0.08), radius: 18, y: 8)
    }
}

extension View {
    func corsoCard() -> some View {
        modifier(CorsoCardModifier())
    }
}

struct CorsoSectionTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.4)
                .foregroundStyle(CorsoTheme.orange)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CorsoTheme.ink)
        }
    }
}
