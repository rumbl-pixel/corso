import SwiftUI

enum AppDestination: String, CaseIterable, Identifiable {
    case today = "Today"
    case squad = "Squad"
    case classes = "Classes"
    case teams = "Teams"
    case results = "Results"
    case sessions = "Sessions"
    case board = "Board"
    case settings = "Settings"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .today:
            return "stopwatch"
        case .squad:
            return "person.3"
        case .classes:
            return "building.columns"
        case .teams:
            return "rectangle.3.group"
        case .results:
            return "trophy"
        case .sessions:
            return "calendar"
        case .board:
            return "pencil.and.outline"
        case .settings:
            return "gearshape"
        }
    }
}

struct AppShell: View {
    @Bindable var store: AthleticsStore
    @State private var destination: AppDestination = .today
    @State private var assistantPresented = false
    @State private var weekPickerPresented = false
    @State private var preferredTeamEvent: TeamEvent = .passBall
    @State private var preferredResultEvent: AthleticsEvent?

    var body: some View {
        GeometryReader { proxy in
            // Derive the navigation rail from the available iPad width. This
            // keeps the workspace clear in portrait on every supported iPad
            // rather than relying on one fixed sidebar size.
            let usesCompactRail = proxy.size.height > proxy.size.width || proxy.size.width < 950
            // 68pt is the minimum that still contains the 48pt destination
            // targets plus their horizontal padding; smaller rails would
            // visually overlap the destination title in portrait.
            let compactRailWidth = min(max(proxy.size.width * 0.09, 68), 76)
            HStack(spacing: 0) {
                sidebar(isCompact: usesCompactRail)
                    .frame(width: usesCompactRail ? compactRailWidth : min(max(proxy.size.width * 0.2, 210), 238))
                    .background(CorsoTheme.navy)

                Divider()

                NavigationStack {
                    AppDestinationContent(
                        destination: destination,
                        preferredTeamEvent: preferredTeamEvent,
                        preferredResultEvent: preferredResultEvent,
                        openSession: {
                            destination = .sessions
                        },
                        openResults: { event in
                            preferredResultEvent = event
                            destination = .results
                        },
                        openTeams: { event in
                            preferredTeamEvent = event
                            destination = .teams
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CorsoTheme.cream.ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(CorsoTheme.cream, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
            }
        }
        .background(CorsoTheme.cream.ignoresSafeArea())
        .sheet(isPresented: $assistantPresented) {
            CorsoAssistantView()
                .environment(store)
        }
    }

    @ViewBuilder
    private func sidebar(isCompact: Bool) -> some View {
        if isCompact {
            VStack(spacing: 0) {
                CompactBrandMark()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 9) {
                        ForEach(AppDestination.allCases) { item in
                            destinationButton(item, isCompact: true)
                        }
                    }
                    .padding(.horizontal, 10)
                }

                compactSidebarControls
                    .padding(.vertical, 14)
            }
        } else {
            VStack(spacing: 0) {
                BrandHeader()

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AppDestination.allCases) { item in
                            destinationButton(item, isCompact: false)
                        }
                    }
                    .padding(.horizontal, 14)
                }

                expandedSidebarControls
                    .padding(18)
            }
        }
    }

    private var compactSidebarControls: some View {
        HStack(spacing: 6) {
            workspaceMenu(compact: true)
            assistantButton(compact: true)
            coachMenu(compact: true)
        }
    }

    private var expandedSidebarControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WORKSPACE")
                .font(.caption2.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.55))

            workspaceMenu(compact: false)

            assistantButton(compact: false)

            Text("CURRENT COACH")
                .font(.caption2.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 2)

            coachMenu(compact: false)
        }
    }

    private func workspaceMenu(compact: Bool) -> some View {
        Button {
            weekPickerPresented = true
        } label: {
            Group {
                if compact {
                    Image(systemName: "calendar.badge.clock")
                        .font(.body.weight(.semibold))
                        .frame(width: 30, height: 36)
                } else {
                    Label("Week \(store.state.currentWeek)", systemImage: "calendar.badge.clock")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                }
            }
            .foregroundStyle(.white)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $weekPickerPresented, arrowEdge: compact ? .bottom : .leading) {
            WeekPickerPanel(
                selectedWeek: store.state.currentWeek,
                selectWeek: { week in
                    store.setCurrentWeek(week)
                    weekPickerPresented = false
                }
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Workspace controls. Current week \(store.state.currentWeek)")
    }

    private func assistantButton(compact: Bool) -> some View {
        Button {
            assistantPresented = true
        } label: {
            Group {
                if compact {
                    Image(systemName: "message.fill")
                        .font(.body.weight(.semibold))
                        .frame(width: 30, height: 36)
                } else {
                    Label("Ask Corso", systemImage: "message.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                }
            }
            .foregroundStyle(.white)
            .background(CorsoTheme.orange.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask Corso")
    }

    private func coachMenu(compact: Bool) -> some View {
        Menu {
            Picker("Current coach", selection: $store.selectedCoachID) {
                ForEach(store.state.settings.coaches) { coach in
                    Text(coach.name).tag(Optional(coach.id))
                }
            }
        } label: {
            Group {
                if compact {
                    Image(systemName: "person.crop.circle")
                        .font(.body.weight(.semibold))
                        .frame(width: 30, height: 36)
                } else {
                    Label(store.selectedCoachName, systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                }
            }
            .foregroundStyle(.white)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityLabel("Current coach: \(store.selectedCoachName)")
    }

    private func destinationButton(_ item: AppDestination, isCompact: Bool) -> some View {
        Button {
            destination = item
        } label: {
            Group {
                if isCompact {
                    Image(systemName: item.symbol)
                        .font(.title3.weight(.semibold))
                        .frame(width: 48, height: 48)
                } else {
                    Label(item.rawValue, systemImage: item.symbol)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                }
            }
            .foregroundStyle(destination == item ? CorsoTheme.navy : .white)
            .background(
                destination == item ? CorsoTheme.paper : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.rawValue)
        .accessibilityAddTraits(destination == item ? .isSelected : [])
    }
}

private struct WeekPickerPanel: View {
    let selectedWeek: Int
    let selectWeek: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose week")
                .font(.headline.weight(.bold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...9, id: \.self) { week in
                    Button {
                        selectWeek(week)
                    } label: {
                        Text("Week \(week)")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(week == selectedWeek ? .white : CorsoTheme.ink)
                            .background(
                                week == selectedWeek ? CorsoTheme.navy : CorsoTheme.navy.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Week \(week)\(week == selectedWeek ? " (selected)" : "")")
                }
            }
        }
        .padding(18)
        .frame(width: 280)
    }
}

/// Isolates the expanded feature graph from the stable sidebar shell. SwiftUI
/// evaluates only the selected destination after the app has completed its
/// lightweight bootstrap.
private struct AppDestinationContent: View {
    let destination: AppDestination
    let preferredTeamEvent: TeamEvent
    let preferredResultEvent: AthleticsEvent?
    let openSession: () -> Void
    let openResults: (AthleticsEvent) -> Void
    let openTeams: (TeamEvent) -> Void

    @ViewBuilder
    var body: some View {
        Group {
            switch destination {
            case .today:
                TodayView(
                    openSession: openSession,
                    openResults: openResults,
                    openTeams: openTeams
                )
            case .squad:
                SquadView()
            case .classes:
                ClassesView()
            case .teams:
                TeamsView(initialEvent: preferredTeamEvent)
            case .results:
                ResultsView(initialEvent: preferredResultEvent)
            case .sessions:
                SessionsView()
            case .board:
                WhiteboardView()
            case .settings:
                SettingsView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(CorsoTheme.paper)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(CorsoTheme.orange, lineWidth: 3)
                    .padding(4)
                Text("C")
                    .font(.title2.weight(.black))
                    .foregroundStyle(CorsoTheme.navy)
            }
            .frame(width: 52, height: 58)

            VStack(alignment: .leading, spacing: 0) {
                Text("CORSO")
                    .font(.headline.weight(.black))
                Text("ATHLETICS")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(CorsoTheme.orange)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
    }
}

private struct CompactBrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CorsoTheme.paper)
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(CorsoTheme.orange, lineWidth: 3)
                .padding(4)
            Text("C")
                .font(.title2.weight(.black))
                .foregroundStyle(CorsoTheme.navy)
        }
        .frame(width: 52, height: 58)
        .padding(.vertical, 18)
        .accessibilityLabel("Corso Athletics")
    }
}
