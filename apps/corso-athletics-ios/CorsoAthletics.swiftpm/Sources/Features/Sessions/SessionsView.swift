import SwiftUI

struct SessionsView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var expandedWeek: Int?

    private var displayedSessions: [TrainingSession] {
        TrainingProgram.sessions.compactMap { store.resolvedSession(week: $0.week) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    CorsoSectionTitle(
                        eyebrow: "Seven-week program",
                        title: "Training sessions"
                    )
                    Spacer()
                    Text("\(store.state.settings.trainingDay) · \(store.state.settings.sessionStart)–\(store.state.settings.sessionEnd)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CorsoTheme.muted)
                }

                ForEach(displayedSessions) { session in
                    SessionProgramCard(
                        session: session,
                        isExpanded: expandedWeek == session.week,
                        isCurrent: store.state.currentWeek == session.week,
                        isCustom: store.state.sessionOverrides[session.week] != nil,
                        toggleExpanded: {
                            expandedWeek = expandedWeek == session.week ? nil : session.week
                        }
                    )
                }

                CarnivalWeekCard(
                    week: 6,
                    title: "School athletics carnival",
                    detail: "Record results, confirm event groups and note reserves.",
                    isCurrent: store.state.currentWeek == 6
                )
                CarnivalWeekCard(
                    week: 9,
                    title: "Interschool athletics carnival",
                    detail: "Use the confirmed squad, event list and saved results on carnival day.",
                    isCurrent: store.state.currentWeek == 9
                )
            }
            .padding(28)
        }
        .navigationTitle("Sessions")
        .onAppear {
            expandedWeek = TrainingProgram.sessions.contains(where: { $0.week == store.state.currentWeek })
                ? store.state.currentWeek
                : nil
        }
    }
}

private struct SessionProgramCard: View {
    @Environment(AthleticsStore.self) private var store
    let session: TrainingSession
    let isExpanded: Bool
    let isCurrent: Bool
    let isCustom: Bool
    let toggleExpanded: () -> Void

    @State private var isEditing = false
    @State private var ballGames = ""
    @State private var activities: [SessionActivity] = []

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleExpanded) {
                HStack(spacing: 16) {
                    Text("W\(session.week)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(isCurrent ? CorsoTheme.orange : CorsoTheme.navy, in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.title)
                                .font(.title3.weight(.bold))
                            if isCurrent {
                                Text("CURRENT")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(CorsoTheme.orange)
                            }
                        }
                        Text(session.purpose)
                            .font(.subheadline)
                            .foregroundStyle(CorsoTheme.muted)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(session.ballGames)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CorsoTheme.orange.opacity(0.1), in: Capsule())
                        .foregroundStyle(CorsoTheme.orangeDark)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(CorsoTheme.muted)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        if isCustom {
                            Button("Restore original", systemImage: "arrow.counterclockwise") {
                                store.resetSession(week: session.week)
                                loadDraft()
                            }
                            .buttonStyle(.borderless)
                        }
                        Spacer()
                        Button("Make current week", systemImage: "scope") {
                            store.setCurrentWeek(session.week)
                        }
                        .buttonStyle(.bordered)
                        Button(isEditing ? "Save program" : "Edit program",
                               systemImage: isEditing ? "checkmark" : "pencil") {
                            if isEditing {
                                store.updateSession(
                                    week: session.week,
                                    ballGames: ballGames,
                                    activities: activities
                                )
                            } else {
                                loadDraft()
                            }
                            isEditing.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CorsoTheme.orange)
                    }

                    if isEditing {
                        Picker("Ball-game practice", selection: $ballGames) {
                            if !TrainingProgram.ballGameOptions.contains(ballGames) {
                                Text(ballGames).tag(ballGames)
                            }
                            ForEach(TrainingProgram.ballGameOptions, id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                    }

                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                        GridRow {
                            Text("DONE")
                            Text("MINUTES")
                            Text("BLOCK")
                            Text("EXERCISE")
                        }
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(CorsoTheme.muted)

                        ForEach(Array((isEditing ? activities : session.activities).enumerated()), id: \.element.id) { index, activity in
                            Divider().gridCellColumns(4)
                            SessionActivityRow(
                                activity: activity,
                                isEditing: isEditing,
                                update: { updated in
                                    guard activities.indices.contains(index) else { return }
                                    activities[index] = updated
                                    if !isEditing {
                                        store.updateSession(
                                            week: session.week,
                                            ballGames: session.ballGames,
                                            activities: activities
                                        )
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(20)
                .onAppear(perform: loadDraft)
            }
        }
        .corsoCard()
    }

    private func loadDraft() {
        let resolved = store.resolvedSession(week: session.week) ?? session
        ballGames = resolved.ballGames
        activities = resolved.activities
    }
}

private struct SessionActivityRow: View {
    let activity: SessionActivity
    let isEditing: Bool
    let update: (SessionActivity) -> Void

    var body: some View {
        GridRow {
            Button {
                var copy = activity
                copy.completed.toggle()
                update(copy)
            } label: {
                Image(systemName: activity.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(activity.completed ? CorsoTheme.green : CorsoTheme.muted)
            }
            .buttonStyle(.plain)

            Text(activity.time)
                .font(.subheadline.monospacedDigit().weight(.semibold))

            if isEditing {
                Picker("Block", selection: Binding(
                    get: { activity.activity },
                    set: { value in
                        var copy = activity
                        copy.activity = value
                        copy.detail = TrainingProgram.activityOptions[value]?.first ?? copy.detail
                        update(copy)
                    }
                )) {
                    ForEach(TrainingProgram.activityOptions.keys.sorted(), id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .labelsHidden()
            } else {
                Text(activity.activity).font(.headline)
            }

            if isEditing {
                Picker("Exercise", selection: Binding(
                    get: { activity.detail },
                    set: { value in
                        var copy = activity
                        copy.detail = value
                        update(copy)
                    }
                )) {
                    let choices = TrainingProgram.activityOptions[activity.activity] ?? [activity.detail]
                    ForEach(choices, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            } else {
                Text(activity.detail)
                    .font(.subheadline)
                    .foregroundStyle(CorsoTheme.muted)
            }
        }
        .opacity(activity.completed ? 0.56 : 1)
    }
}

private struct CarnivalWeekCard: View {
    @Environment(AthleticsStore.self) private var store
    let week: Int
    let title: String
    let detail: String
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text("W\(week)")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(isCurrent ? CorsoTheme.orange : CorsoTheme.muted, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(CorsoTheme.muted)
            }
            Spacer()
            Button("Make current", systemImage: "scope") {
                store.setCurrentWeek(week)
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .corsoCard()
    }
}
