import SwiftUI

struct TeamsView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var event: TeamEvent
    @State private var stage: TeamStage = .provisional
    @State private var division: CompetitionDivision = .intermediate
    @State private var gender: AthleteGender? = .boys
    @State private var boardNotice: String?

    init(initialEvent: TeamEvent = .passBall) {
        _event = State(initialValue: initialEvent)
    }

    private var scope: TeamBoardScope {
        TeamBoardScope(event: event, stage: stage, division: division, gender: gender)
    }

    private var board: TeamBoard { store.teamBoard(for: scope) }

    private var eligible: [Athlete] {
        store.state.athletes.filter { athlete in
            athlete.division == division
                && stage.includes(athlete.selection)
                && (gender.map { group in athlete.gender == group } ?? true)
        }
    }

    private var available: [Athlete] {
        let assigned = Set(board.teamA + board.teamB)
        return eligible.filter { !assigned.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if store.state.athletes.isEmpty {
                ContentUnavailableView(
                    "No athletes to position",
                    systemImage: "rectangle.3.group",
                    description: Text("Add students and choose a provisional or interschool status first.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        guidance
                        HStack(alignment: .top, spacing: 14) {
                            TeamColumn(
                                title: "Available athletes",
                                subtitle: "Squad pool",
                                athletes: available,
                                placement: .available,
                                board: board,
                                event: event,
                                scope: scope
                            )
                            TeamColumn(
                                title: "Team A",
                                subtitle: event == .sprintRelay ? "Running order" : "Position order",
                                athletes: athletes(for: board.teamA),
                                placement: .teamA,
                                board: board,
                                event: event,
                                scope: scope
                            )
                            TeamColumn(
                                title: "Team B",
                                subtitle: event == .sprintRelay ? "Running order" : "Position order",
                                athletes: athletes(for: board.teamB),
                                placement: .teamB,
                                board: board,
                                event: event,
                                scope: scope
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("Teams")
        .alert("Coaches workshop", isPresented: Binding(
            get: { boardNotice != nil },
            set: { if !$0 { boardNotice = nil } }
        )) {
            Button("OK", role: .cancel) { boardNotice = nil }
        } message: {
            Text(boardNotice ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            CorsoSectionTitle(eyebrow: "Selection-only workspace", title: "Team positions")

            HStack(spacing: 12) {
                Picker("Event", selection: $event) {
                    ForEach(TeamEvent.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Stage", selection: $stage) {
                    ForEach(TeamStage.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(width: 170)

                Picker("Division", selection: $division) {
                    ForEach(CompetitionDivision.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(width: 170)

                Picker("Gender", selection: $gender) {
                    Text("All groups").tag(AthleteGender?.none)
                    ForEach(AthleteGender.coachingGroups) { Text($0.rawValue).tag(Optional($0)) }
                }
                .frame(width: 155)

                Menu {
                    Button("Auto-balance from results", systemImage: "wand.and.stars") {
                        store.autoArrangeTeams(scope: scope)
                    }
                    Button("Send layout to whiteboard", systemImage: "pencil.and.outline") {
                        sendToWhiteboard()
                    }
                    .disabled(board.teamA.isEmpty && board.teamB.isEmpty)
                } label: {
                    Label("Workshop", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.borderedProminent)
                .tint(CorsoTheme.orange)
            }
        }
        .padding(24)
        .background(CorsoTheme.paper)
    }

    private var guidance: some View {
        Label(event.guidance, systemImage: event == .sprintRelay ? "medal" : "star.fill")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(CorsoTheme.navy)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CorsoTheme.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }

    private func athletes(for ids: [UUID]) -> [Athlete] {
        ids.compactMap { id in eligible.first(where: { $0.id == id }) }
    }

    private func sendToWhiteboard() {
        do {
            let title = try TeamBoardWhiteboardService.createBoard(
                scope: scope,
                board: board,
                athletes: store.state.athletes
            )
            boardNotice = "“\(title)” is ready in Board. Open it to draw, annotate or change the plan with Apple Pencil."
        } catch {
            boardNotice = error.localizedDescription
        }
    }
}

private struct TeamColumn: View {
    @Environment(AthleticsStore.self) private var store
    let title: String
    let subtitle: String
    let athletes: [Athlete]
    let placement: TeamPlacement
    let board: TeamBoard
    let event: TeamEvent
    let scope: TeamBoardScope

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(subtitle.uppercased())
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(CorsoTheme.muted)
                    Text(title).font(.title3.weight(.bold))
                }
                Spacer()
                Text(event == .sprintRelay && placement != .available ? "\(athletes.count)/4" : "\(athletes.count)")
                    .font(.headline.monospacedDigit())
            }

            if athletes.isEmpty {
                Text("No athletes here")
                    .font(.subheadline)
                    .foregroundStyle(CorsoTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 92)
            } else {
                ForEach(Array(athletes.enumerated()), id: \.element.id) { index, athlete in
                    TeamAthleteCard(
                        athlete: athlete,
                        index: index,
                        placement: placement,
                        count: athletes.count,
                        isLeader: isLeader(athlete.id),
                        event: event,
                        scope: scope
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .corsoCard()
        .dropDestination(for: String.self) { values, _ in
            guard let value = values.first, let athleteID = UUID(uuidString: value) else { return false }
            store.placeAthlete(athleteID, in: placement, scope: scope)
            return true
        }
    }

    private func isLeader(_ id: UUID) -> Bool {
        switch placement {
        case .teamA:
            return board.teamALeader == id
        case .teamB:
            return board.teamBLeader == id
        case .available:
            return false
        }
    }

    private struct TeamAthleteCard: View {
        @Environment(AthleticsStore.self) private var store
        let athlete: Athlete
        let index: Int
        let placement: TeamPlacement
        let count: Int
        let isLeader: Bool
        let event: TeamEvent
        let scope: TeamBoardScope

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if placement != .available {
                        Text(event == .sprintRelay ? "R\(index + 1)" : "\(index + 1)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(CorsoTheme.navy, in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(athlete.name)
                            .font(.subheadline.weight(.bold))
                        Text(
                            placement == .available
                                ? "Year \(athlete.year) · \(athlete.gender.rawValue)"
                                : "\(event.positionLabel(at: index, count: count, isLeader: isLeader)) · Year \(athlete.year)"
                        )
                            .font(.caption2)
                            .foregroundStyle(CorsoTheme.muted)
                    }
                }

                Picker("Move \(athlete.name)", selection: Binding(
                    get: { placement },
                    set: { store.placeAthlete(athlete.id, in: $0, scope: scope) }
                )) {
                    ForEach(TeamPlacement.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()

                if placement != .available {
                    HStack(spacing: 6) {
                        Button {
                            store.moveAthlete(athlete.id, in: placement, direction: -1, scope: scope)
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .disabled(index == 0)

                        Button {
                            store.moveAthlete(athlete.id, in: placement, direction: 1, scope: scope)
                        } label: {
                            Image(systemName: "arrow.down")
                        }
                        .disabled(index == count - 1)

                        if event != .sprintRelay {
                            Button {
                                store.makeLeader(athlete.id, in: placement, scope: scope)
                            } label: {
                                Label(isLeader ? "Leader" : "Make leader", systemImage: isLeader ? "star.fill" : "star")
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(11)
            .background(
                isLeader ? CorsoTheme.orange.opacity(0.10) : CorsoTheme.navy.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .draggable(athlete.id.uuidString) {
                Text(athlete.name)
                    .font(.headline)
                    .padding(12)
                    .background(CorsoTheme.paper, in: RoundedRectangle(cornerRadius: 12))
            }
            .dropDestination(for: String.self) { values, _ in
                guard placement != .available,
                      let value = values.first,
                      let athleteID = UUID(uuidString: value)
                else { return false }
                store.placeAthlete(athleteID, in: placement, at: index, scope: scope)
                return true
            }
        }
    }
}
