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
    @State private var preferredTeamEvent: TeamEvent = .passBall
    @State private var preferredResultEvent: AthleticsEvent?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                BrandHeader()

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AppDestination.allCases) { item in
                            Button {
                                destination = item
                            } label: {
                                Label(item.rawValue, systemImage: item.symbol)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .frame(height: 52)
                                    .foregroundStyle(destination == item ? CorsoTheme.navy : .white)
                                    .background(
                                        destination == item ? CorsoTheme.paper : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(destination == item ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 14)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("CURRENT COACH")
                        .font(.caption2.weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.55))
                    Picker("Current coach", selection: $store.selectedCoachID) {
                        ForEach(store.state.settings.coaches) { coach in
                            Text(coach.name).tag(Optional(coach.id))
                        }
                    }
                    .labelsHidden()
                    .tint(.white)
                }
                .padding(18)
            }
            .frame(width: 238)
            .background(CorsoTheme.navy)

            Divider()

            NavigationStack {
                Group {
                    switch destination {
                    case .today:
                        TodayView(
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CorsoTheme.cream.ignoresSafeArea())
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Picker("Current week", selection: Binding(
                            get: { store.state.currentWeek },
                            set: store.setCurrentWeek
                        )) {
                            ForEach(1...9, id: \.self) { week in
                                Text("Week \(week)").tag(week)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            assistantPresented = true
                        } label: {
                            Label("Ask Corso", systemImage: "message.fill")
                        }
                        .tint(CorsoTheme.orange)
                    }
                }
            }
        }
        .background(CorsoTheme.cream.ignoresSafeArea())
        .sheet(isPresented: $assistantPresented) {
            CorsoAssistantView()
                .environment(store)
        }
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
