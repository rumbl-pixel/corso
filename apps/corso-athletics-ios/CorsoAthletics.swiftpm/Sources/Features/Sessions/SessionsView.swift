import SwiftUI
import UniformTypeIdentifiers

struct SessionsView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var expandedWeek: Int?
    @State private var programCoachID: UUID?
    @State private var shareItem: CoachProgramShareItem?
    @State private var importerPresented = false
    @State private var importPayload: CoachProgramSharePayload?
    @State private var sharingError: String?

    private var displayedSessions: [TrainingSession] {
        TrainingProgram.sessions.compactMap {
            store.resolvedSession(week: $0.week, coachID: programCoachID)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sessionHeader

                ForEach(displayedSessions) { session in
                    SessionProgramCard(
                        session: session,
                        isExpanded: expandedWeek == session.week,
                        isCurrent: store.state.currentWeek == session.week,
                        isCustom: store.sessionIsCustom(week: session.week, coachID: programCoachID),
                        coachID: programCoachID,
                        toggleExpanded: {
                            expandedWeek = expandedWeek == session.week ? nil : session.week
                        }
                    )
                    .id("\(session.week)-\(programCoachID?.uuidString ?? "shared")")
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
        .sheet(item: $shareItem) { item in
            CorsoShareSheet(url: item.url)
        }
        .sheet(item: $importPayload) { payload in
            CoachProgramImportSheet(
                payload: payload,
                initialCoachID: programCoachID
            )
            .environment(store)
        }
        .fileImporter(
            isPresented: $importerPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard case .success(let urls) = result, let url = urls.first else { return }
                importPayload = try CoachProgramSharing.read(from: url)
            } catch {
                sharingError = error.localizedDescription
            }
        }
        .alert("Coach program sharing", isPresented: Binding(
            get: { sharingError != nil },
            set: { if !$0 { sharingError = nil } }
        )) {
            Button("OK", role: .cancel) { sharingError = nil }
        } message: {
            Text(sharingError ?? "")
        }
        .onAppear {
            programCoachID = store.selectedCoachID ?? store.state.settings.coaches.first?.id
            expandedWeek = TrainingProgram.sessions.contains(where: { $0.week == store.state.currentWeek })
                ? store.state.currentWeek
                : nil
        }
    }

    private var programCoachName: String {
        store.state.settings.coaches.first(where: { $0.id == programCoachID })?.name ?? "Coach program"
    }

    private var sessionHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom) {
                sessionTitle
                Spacer(minLength: 16)
                sessionHeaderActions
            }

            VStack(alignment: .leading, spacing: 12) {
                sessionTitle
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        sessionHeaderActions
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        sessionHeaderActions
                    }
                }
            }
        }
    }

    private var sessionTitle: some View {
        CorsoSectionTitle(
            eyebrow: "Seven-week program",
            title: "Training sessions"
        )
    }

    private var sessionHeaderActions: some View {
        Group {
            if !store.state.settings.coachProgramsAreShared {
                Menu {
                    Picker("View coach program", selection: $programCoachID) {
                        ForEach(store.state.settings.coaches) { coach in
                            Text(coach.name).tag(Optional(coach.id))
                        }
                    }
                    Divider()
                    Menu("Copy another program here") {
                        ForEach(store.state.settings.coaches.filter { $0.id != programCoachID }) { coach in
                            Button(coach.name) {
                                guard let programCoachID else { return }
                                store.copyProgram(from: coach.id, to: programCoachID)
                            }
                        }
                    }
                } label: {
                    Label(programCoachName, systemImage: "person.crop.circle")
                }
                .buttonStyle(.bordered)
            }

            Menu {
                Button("Share this program", systemImage: "square.and.arrow.up") {
                    shareProgram()
                }
                Button("Import a coach program", systemImage: "square.and.arrow.down") {
                    importerPresented = true
                }
            } label: {
                Label("Share", systemImage: "person.2.wave.2")
            }
            .buttonStyle(.bordered)

            Text("\(store.state.settings.trainingDay) · \(store.state.settings.sessionStart)–\(store.state.settings.sessionEnd)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CorsoTheme.muted)
        }
    }

    private func shareProgram() {
        do {
            shareItem = CoachProgramShareItem(
                url: try CoachProgramSharing.export(
                    state: store.state,
                    coachID: programCoachID
                )
            )
        } catch {
            sharingError = error.localizedDescription
        }
    }
}

private struct CoachProgramImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AthleticsStore.self) private var store
    let payload: CoachProgramSharePayload
    @State private var destinationCoachID: UUID?
    @State private var importFailed = false

    init(payload: CoachProgramSharePayload, initialCoachID: UUID?) {
        self.payload = payload
        _destinationCoachID = State(initialValue: initialCoachID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shared program") {
                    LabeledContent("From", value: payload.sourceCoachName)
                    LabeledContent("School", value: payload.schoolName)
                    LabeledContent("Term", value: payload.termLabel)
                    LabeledContent("Sessions", value: "\(payload.sessions.count)")
                    LabeledContent("Exported", value: payload.exportedAt.formatted(date: .abbreviated, time: .shortened))
                }

                Section {
                    if store.state.settings.coachProgramsAreShared {
                        LabeledContent("Replace", value: "Shared program")
                    } else {
                        Picker("Replace program for", selection: $destinationCoachID) {
                            ForEach(store.state.settings.coaches) { coach in
                                Text(coach.name).tag(Optional(coach.id))
                            }
                        }
                    }
                } footer: {
                    Text("This replaces the chosen seven-week program only. Students, results, attendance, teams and settings are not imported.")
                }

                if importFailed {
                    Section {
                        Label("Choose a destination coach and try again.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Import coach program?")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Replace program") {
                        let imported = store.replaceProgram(
                            with: payload,
                            destinationCoachID: destinationCoachID
                        )
                        importFailed = !imported
                        if imported { dismiss() }
                    }
                    .disabled(
                        !store.state.settings.coachProgramsAreShared
                            && destinationCoachID == nil
                    )
                }
            }
            .onAppear {
                if destinationCoachID == nil {
                    destinationCoachID = store.selectedCoachID
                        ?? store.state.settings.coaches.first?.id
                }
            }
        }
    }
}

private struct SessionProgramCard: View {
    @Environment(AthleticsStore.self) private var store
    let session: TrainingSession
    let isExpanded: Bool
    let isCurrent: Bool
    let isCustom: Bool
    let coachID: UUID?
    let toggleExpanded: () -> Void

    @State private var isEditing = false
    @State private var title = ""
    @State private var purpose = ""
    @State private var outcome = ""
    @State private var ballGames = ""
    @State private var activities: [SessionActivity] = []
    @State private var editHistory: [SessionEditSnapshot] = []
    @State private var activityLibraryNotice: String?

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

                    SessionOutcomeBadge(outcome: session.outcome)

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
                                store.resetSession(week: session.week, coachID: coachID)
                                loadDraft()
                            }
                            .buttonStyle(.borderless)
                        }
                        if isEditing {
                            Button("Undo change", systemImage: "arrow.uturn.backward") {
                                restoreLastEdit()
                            }
                            .buttonStyle(.bordered)
                            .disabled(editHistory.isEmpty)
                            .accessibilityHint("Restores the last unsaved program edit")
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
                                    coachID: coachID,
                                    title: title,
                                    purpose: purpose,
                                    outcome: outcome,
                                    ballGames: ballGames,
                                    activities: activities
                                )
                                editHistory.removeAll()
                            } else {
                                loadDraft()
                                editHistory.removeAll()
                            }
                            isEditing.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CorsoTheme.orange)
                    }

                    if isEditing {
                        TextField("Weekly session name", text: editBinding(.title))
                            .font(.title3.weight(.bold))
                        TextField("Session purpose", text: editBinding(.purpose), axis: .vertical)
                            .lineLimit(2...4)
                        TextField("Session goal / outcome", text: editBinding(.outcome), axis: .vertical)
                            .lineLimit(1...3)
                        Picker("Team-game work", selection: editBinding(.ballGames)) {
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
                                willUpdate: { if isEditing { captureUndoStep() } },
                                update: { updated in
                                    guard activities.indices.contains(index) else { return }
                                    activities[index] = updated
                                    if !isEditing {
                                        store.updateSession(
                                            week: session.week,
                                            coachID: coachID,
                                            ballGames: session.ballGames,
                                            activities: activities
                                        )
                                    }
                                },
                                saveForLater: isEditing ? { activity in
                                    saveActivityForReuse(activity)
                                } : nil,
                                remove: isEditing ? {
                                    guard activities.indices.contains(index) else { return }
                                    captureUndoStep()
                                    activities.remove(at: index)
                                } : nil
                            )
                        }
                    }

                    if isEditing {
                        HStack {
                            Button("Add custom activity", systemImage: "plus.circle") {
                                captureUndoStep()
                                activities.append(
                                    SessionActivity(
                                        id: "custom-\(UUID().uuidString)",
                                        time: "",
                                        activity: "Custom",
                                        detail: ""
                                    )
                                )
                            }
                            .buttonStyle(.bordered)

                            Menu {
                                ForEach(SessionDrillLibrary.categories, id: \.self) { category in
                                    Menu(category) {
                                        ForEach(SessionDrillLibrary.templates(in: category)) { template in
                                            Button(template.activity) {
                                                addDrill(template)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Label("Add from drill library", systemImage: "figure.run")
                            }
                            .buttonStyle(.bordered)

                            if !store.state.savedSessionActivities.isEmpty {
                                Menu {
                                    ForEach(store.state.savedSessionActivities) { saved in
                                        Button {
                                            addSavedActivity(saved)
                                        } label: {
                                            VStack(alignment: .leading) {
                                                Text(saved.activity)
                                                if !saved.detail.isEmpty {
                                                    Text(saved.detail)
                                                }
                                            }
                                        }
                                    }
                                    Divider()
                                    Menu("Remove saved activity") {
                                        ForEach(store.state.savedSessionActivities) { saved in
                                            Button(saved.activity, role: .destructive) {
                                                store.deleteSavedSessionActivity(id: saved.id)
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Use saved activity", systemImage: "bookmark")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    if let activityLibraryNotice {
                        Label(activityLibraryNotice, systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CorsoTheme.green)
                    }
                }
                .padding(20)
                .onAppear(perform: loadDraft)
            }
        }
        .corsoCard()
    }

    private func loadDraft() {
        let resolved = store.resolvedSession(week: session.week, coachID: coachID) ?? session
        title = resolved.title
        purpose = resolved.purpose
        outcome = resolved.outcome
        ballGames = resolved.ballGames
        activities = resolved.activities
    }

    private func captureUndoStep() {
        let snapshot = SessionEditSnapshot(
            title: title,
            purpose: purpose,
            outcome: outcome,
            ballGames: ballGames,
            activities: activities
        )
        guard editHistory.last != snapshot else { return }
        editHistory.append(snapshot)
        if editHistory.count > 60 { editHistory.removeFirst(editHistory.count - 60) }
    }

    private func restoreLastEdit() {
        guard let snapshot = editHistory.popLast() else { return }
        title = snapshot.title
        purpose = snapshot.purpose
        outcome = snapshot.outcome
        ballGames = snapshot.ballGames
        activities = snapshot.activities
    }

    private func addDrill(_ template: SessionDrillTemplate) {
        captureUndoStep()
        activities.append(template.sessionActivity)
    }

    private func addSavedActivity(_ saved: SavedSessionActivity) {
        captureUndoStep()
        activities.append(saved.makeSessionActivity())
    }

    private func saveActivityForReuse(_ activity: SessionActivity) {
        let didSave = store.saveSessionActivityForReuse(activity)
        activityLibraryNotice = didSave
            ? "Saved \(activity.activity) for later sessions"
            : "That activity is already saved"
    }

    private func editBinding(_ field: SessionEditField) -> Binding<String> {
        Binding {
            switch field {
            case .title: title
            case .purpose: purpose
            case .outcome: outcome
            case .ballGames: ballGames
            }
        } set: { value in
            let current: String
            switch field {
            case .title: current = title
            case .purpose: current = purpose
            case .outcome: current = outcome
            case .ballGames: current = ballGames
            }
            guard current != value else { return }
            captureUndoStep()
            switch field {
            case .title: title = value
            case .purpose: purpose = value
            case .outcome: outcome = value
            case .ballGames: ballGames = value
            }
        }
    }
}

private enum SessionEditField {
    case title
    case purpose
    case outcome
    case ballGames
}

private struct SessionEditSnapshot: Equatable {
    let title: String
    let purpose: String
    let outcome: String
    let ballGames: String
    let activities: [SessionActivity]
}

private struct SessionActivityRow: View {
    let activity: SessionActivity
    let isEditing: Bool
    let willUpdate: () -> Void
    let update: (SessionActivity) -> Void
    let saveForLater: ((SessionActivity) -> Void)?
    let remove: (() -> Void)?

    var body: some View {
        GridRow {
            Button {
                var copy = activity
                copy.completed.toggle()
                if isEditing { willUpdate() }
                update(copy)
            } label: {
                Image(systemName: activity.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(activity.completed ? CorsoTheme.green : CorsoTheme.muted)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("0–10", text: fieldBinding(\.time))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 74)
            } else {
                Text(activity.time)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }

            if isEditing {
                TextField("Activity name", text: fieldBinding(\.activity))
            } else {
                Text(activity.activity).font(.headline)
            }

            if isEditing {
                HStack {
                    TextField("Write your own exercise or coaching notes", text: fieldBinding(\.detail), axis: .vertical)
                        .lineLimit(1...4)
                    if let saveForLater {
                        Button {
                            saveForLater(activity)
                        } label: {
                            Image(systemName: "bookmark.badge.plus")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Save \(activity.activity) for later sessions")
                    }
                    if let remove {
                        Button(role: .destructive, action: remove) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } else {
                Text(activity.detail)
                    .font(.subheadline)
                    .foregroundStyle(CorsoTheme.muted)
            }
        }
        .opacity(activity.completed ? 0.56 : 1)
    }

    private func fieldBinding(
        _ keyPath: WritableKeyPath<SessionActivity, String>
    ) -> Binding<String> {
        Binding {
            activity[keyPath: keyPath]
        } set: { value in
            willUpdate()
            var copy = activity
            copy[keyPath: keyPath] = value
            update(copy)
        }
    }
}

private struct SessionOutcomeBadge: View {
    let outcome: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("GOAL")
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
            Text(outcome)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.86)
        }
        .foregroundStyle(CorsoTheme.orangeDark)
        .frame(maxWidth: 172, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(CorsoTheme.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Session goal: \(outcome)")
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
