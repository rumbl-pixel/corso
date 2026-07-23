import SwiftUI

struct TodayView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var attendancePresented = false

    private var presentCount: Int {
        store.state.athletes.filter { $0.attendance[Date.now.attendanceKey] == .present }.count
    }

    private var attendancePercentage: Int {
        guard !store.state.athletes.isEmpty else { return 0 }
        return Int((Double(presentCount) / Double(store.state.athletes.count) * 100).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if let saveError = store.lastSaveError {
                    SaveErrorBanner(message: saveError)
                }

                dashboardCards

                CorsoSectionTitle(
                    eyebrow: "Event workspaces",
                    title: "Train, record and select"
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 16)], spacing: 16) {
                    EventTile(title: "75m / 100m", subtitle: "Sprints", symbol: "speedometer")
                    EventTile(title: "200m / 400m", subtitle: "Race rhythm", symbol: "stopwatch")
                    EventTile(title: "Long Jump", subtitle: "Approach & landing", symbol: "circle.dotted")
                    EventTile(title: "Team Games", subtitle: "Build positions", symbol: "person.3")
                    EventTile(title: "Relays", subtitle: "Set runner order", symbol: "medal")
                }
            }
            .padding(28)
        }
        .navigationTitle("Today")
        .sheet(isPresented: $attendancePresented) {
            AttendanceSheet()
                .environment(store)
        }
    }

    @ViewBuilder
    private var dashboardCards: some View {
        let settings = store.state.settings
        let hero = SessionHeroCard(
            week: store.state.currentWeek,
            trainingDay: settings.trainingDay,
            sessionStart: settings.sessionStart,
            sessionEnd: settings.sessionEnd
        )
        let metrics = VStack(spacing: 18) {
            SquadMetricCard(count: store.state.athletes.count)
            AttendanceCard(percentage: attendancePercentage) {
                attendancePresented = true
            }
        }

        if horizontalSizeClass == .compact {
            VStack(spacing: 18) {
                hero.frame(minHeight: 390)
                metrics.frame(minHeight: 310)
            }
        } else {
            HStack(alignment: .stretch, spacing: 18) {
                hero.frame(maxWidth: .infinity)
                metrics.frame(width: 285)
            }
            .frame(minHeight: 390)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.state.settings.schoolName)
                    .font(.title2.weight(.black))
                    .foregroundStyle(CorsoTheme.ink)
                Text("\(store.state.settings.termLabel) · Week \(store.state.currentWeek)")
                    .foregroundStyle(CorsoTheme.muted)
            }
            Spacer()
            Label("Saved on this iPad", systemImage: "checkmark.shield")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CorsoTheme.green)
        }
    }
}

private struct SessionHeroCard: View {
    let week: Int
    let trainingDay: String
    let sessionStart: String
    let sessionEnd: String

    private var title: String {
        switch week {
        case 6:
            return "School athletics carnival"
        case 9:
            return "Interschool athletics carnival"
        default:
            return "Week \(week): Build speed with purpose"
        }
    }

    private var eyebrow: String {
        switch week {
        case 6, 9:
            return "CARNIVAL DAY"
        default:
            return "\(trainingDay.uppercased()) ATHLETICS TRAINING"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [CorsoTheme.navy, CorsoTheme.navyRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(CorsoTheme.orange, lineWidth: 56)
                .frame(width: 440, height: 310)
                .offset(x: 120, y: 145)

            VStack(alignment: .leading, spacing: 16) {
                Text(eyebrow)
                    .font(.caption.weight(.heavy))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.67))
                Text(title)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Use class evidence, deliberate practice and clean records to select the strongest fair team.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                Label("\(sessionStart)–\(sessionEnd)", systemImage: "clock")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(36)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: CorsoTheme.navy.opacity(0.16), radius: 18, y: 10)
    }
}

private struct SaveErrorBanner: View {
    let message: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("Changes are not saved")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(Color.red)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

private struct SquadMetricCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(count)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                Spacer()
                Image(systemName: "person.3")
                    .font(.title)
                    .foregroundStyle(CorsoTheme.muted)
            }
            Text("Squad athletes")
                .font(.title3.weight(.bold))
            Text("Target 30–40")
                .foregroundStyle(CorsoTheme.muted)
        }
        .foregroundStyle(CorsoTheme.ink)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .corsoCard()
    }
}

private struct AttendanceCard: View {
    let percentage: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Take attendance")
                        .font(.title2.weight(.black))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(percentage)% marked present")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "checklist")
                    .font(.system(size: 34, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [CorsoTheme.orange, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take attendance, \(percentage) percent marked present")
    }
}

private struct EventTile: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CorsoTheme.orange)
                .frame(width: 54, height: 54)
                .background(CorsoTheme.orange.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            Spacer()
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(CorsoTheme.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CorsoTheme.muted)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 205, alignment: .leading)
        .corsoCard()
    }
}
