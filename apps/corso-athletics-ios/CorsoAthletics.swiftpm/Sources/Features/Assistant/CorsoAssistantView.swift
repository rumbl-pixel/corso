import SwiftUI

struct CorsoAssistantView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var messages = [
        AssistantMessage(
            role: .assistant,
            text: "Ask me to record a result, update attendance or selection, place a team, rank an event, or find missing results."
        )
    ]
    @State private var proposal: AssistantProposal?
    @State private var undoState: AthleticsState?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                AssistantBubble(message: message)
                                    .id(message.id)
                            }

                            if let proposal {
                                AssistantConfirmationCard(
                                    proposal: proposal,
                                    cancel: {
                                        self.proposal = nil
                                        reply("Cancelled. Nothing was changed.")
                                    },
                                    confirm: confirm
                                )
                            } else if messages.count == 1 {
                                suggestion("Fastest three Year 5 boys in 100m")
                                suggestion("Show Year 4 students without a long jump result")
                                suggestion("Mark Alex Student present")
                            }
                        }
                        .padding(18)
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()

                if undoState != nil {
                    Button("Undo last assistant action", systemImage: "arrow.uturn.backward") {
                        undo()
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 10)
                }

                HStack(alignment: .bottom, spacing: 10) {
                    TextField(
                        proposal == nil ? "Type or dictate an instruction…" : "Confirm or cancel first",
                        text: $input,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
                    .disabled(proposal != nil)

                    Button("Send", systemImage: "paperplane.fill") {
                        submit(input)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .tint(CorsoTheme.orange)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || proposal != nil)
                }
                .padding(16)

                Text("Local commands only · every write needs confirmation · nothing is sent to an external AI service")
                    .font(.caption2)
                    .foregroundStyle(CorsoTheme.muted)
                    .padding(.bottom, 12)
            }
            .navigationTitle("Ask Corso")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func suggestion(_ text: String) -> some View {
        Button(text) { submit(text) }
            .buttonStyle(.bordered)
    }

    private func submit(_ raw: String) {
        let command = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }
        messages.append(AssistantMessage(role: .user, text: command))
        input = ""

        switch CorsoAssistantEngine.interpret(command, state: store.state) {
        case .answer(let text, let items):
            messages.append(AssistantMessage(role: .assistant, text: text, items: items))
        case .error(let text):
            reply(text)
        case .proposal(let proposal):
            self.proposal = proposal
        }
    }

    private func confirm() {
        guard let proposal else { return }
        let before = store.state
        var next = before
        guard CorsoAssistantEngine.apply(
            proposal,
            to: &next,
            coachID: store.selectedCoachID,
            coachName: store.selectedCoachName
        ) else {
            self.proposal = nil
            reply("The student data changed while this was waiting. Send the instruction again so I can recheck it.")
            return
        }
        undoState = before
        store.commitAssistantChange(state: next)
        self.proposal = nil
        reply("Saved: \(proposal.detail)")
    }

    private func undo() {
        guard var previous = undoState else { return }
        var audit = store.state.assistantAudit
        if let index = audit.indices.last {
            audit[index].undoneAt = .now
            audit[index].undoneBy = store.selectedCoachName
        }
        previous.assistantAudit = audit
        store.commitAssistantChange(state: previous)
        undoState = nil
        reply("Undone. The audit history records the original action and the undo.")
    }

    private func reply(_ text: String) {
        messages.append(AssistantMessage(role: .assistant, text: text))
    }
}

private struct AssistantMessage: Identifiable {
    enum Role: Equatable { case assistant, user }
    let id = UUID()
    let role: Role
    let text: String
    var items: [String] = []
}

private struct AssistantBubble: View {
    let message: AssistantMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(message.text)
            if !message.items.isEmpty {
                ForEach(message.items, id: \.self) { Text($0).font(.subheadline) }
            }
        }
        .padding(12)
        .foregroundStyle(message.role == .user ? .white : CorsoTheme.ink)
        .background(
            message.role == .user ? CorsoTheme.navy : CorsoTheme.navy.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .frame(maxWidth: 520, alignment: message.role == .user ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

private struct AssistantConfirmationCard: View {
    let proposal: AssistantProposal
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("CONFIRM BEFORE SAVING")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(CorsoTheme.orange)
            Text(proposal.title).font(.headline)
            Text(proposal.detail).foregroundStyle(CorsoTheme.muted)
            Text("Instruction: “\(proposal.command)”")
                .font(.caption)
                .foregroundStyle(CorsoTheme.muted)
            HStack {
                Button("Cancel", action: cancel).buttonStyle(.bordered)
                Button("Confirm", systemImage: "checkmark", action: confirm)
                    .buttonStyle(.borderedProminent)
                    .tint(CorsoTheme.orange)
            }
        }
        .padding(16)
        .corsoCard()
    }
}

enum AssistantInterpretation {
    case answer(String, [String])
    case proposal(AssistantProposal)
    case error(String)
}

struct AssistantProposal {
    enum Action {
        case result(athleteID: UUID, event: AthleticsEvent, value: Double)
        case attendance(athleteID: UUID, status: AttendanceStatus)
        case selection(athleteID: UUID, selection: SquadSelection)
        case team(athleteID: UUID, placement: TeamPlacement, scope: TeamBoardScope)
    }

    let command: String
    let title: String
    let detail: String
    let action: Action
}

enum CorsoAssistantEngine {
    static func interpret(_ command: String, state: AthleticsState) -> AssistantInterpretation {
        let input = normalized(command)
        guard !input.isEmpty else { return .error("Type or dictate an athletics instruction first.") }

        if input.contains("fastest") || input.contains("quickest") || input.contains("longest")
            || input.contains("best") || input.contains("top") {
            return rankedAnswer(input: input, state: state)
        }
        if input.contains("without") || input.contains("missing") || input.contains("no recorded") {
            return missingAnswer(input: input, state: state)
        }

        guard let athlete = matchedAthlete(input, athletes: state.athletes) else {
            return .error("I could not match one student. Use their full name as it appears in Corso.")
        }

        if let status = attendanceStatus(input) {
            return .proposal(AssistantProposal(
                command: command,
                title: "Update attendance",
                detail: "\(athlete.name) · \(status.rawValue.capitalized) · today",
                action: .attendance(athleteID: athlete.id, status: status)
            ))
        }

        if let selection = selection(input) {
            return .proposal(AssistantProposal(
                command: command,
                title: "Change selection",
                detail: "\(athlete.name) · \(selection.rawValue)",
                action: .selection(athleteID: athlete.id, selection: selection)
            ))
        }

        if let teamEvent = teamEvent(input), let placement = teamPlacement(input) {
            let stage: TeamStage = athlete.selection == .provisional ? .provisional : .interschool
            guard stage.includes(athlete.selection) else {
                return .error("\(athlete.name) must be provisional, interschool or reserve before joining a team.")
            }
            let scope = TeamBoardScope(
                event: teamEvent,
                stage: stage,
                division: athlete.division,
                gender: athlete.gender == .unspecified ? nil : athlete.gender
            )
            return .proposal(AssistantProposal(
                command: command,
                title: "Update team",
                detail: "\(athlete.name) · \(teamEvent.rawValue) · \(placement.rawValue)",
                action: .team(athleteID: athlete.id, placement: placement, scope: scope)
            ))
        }

        if let event = event(input), let value = performance(input, event: event) {
            return .proposal(AssistantProposal(
                command: command,
                title: "Record result",
                detail: "\(athlete.name) · \(event.rawValue) · \(value.formatted(.number.precision(.fractionLength(2))))\(event.isTimed ? "s" : "m")",
                action: .result(athleteID: athlete.id, event: event, value: value)
            ))
        }

        return .error("I did not recognise that instruction. Try a result, attendance, selection, team, ranking or missing-results request.")
    }

    static func apply(
        _ proposal: AssistantProposal,
        to state: inout AthleticsState,
        coachID: UUID?,
        coachName: String
    ) -> Bool {
        let targetID: UUID
        let auditAction: AssistantAuditAction

        switch proposal.action {
        case .result(let athleteID, let event, let value):
            guard state.athletes.contains(where: { $0.id == athleteID }), value > 0 else { return false }
            state.results.append(ResultRecord(
                athleteID: athleteID,
                event: event,
                value: value,
                addedBy: coachName,
                coachID: coachID,
                source: .training
            ))
            targetID = athleteID
            auditAction = .result

        case .attendance(let athleteID, let status):
            guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }),
                  state.athletes[index].selection == .provisional
                    || state.athletes[index].selection == .interschool
            else { return false }
            state.athletes[index].attendance[Date.now.attendanceKey] = status
            targetID = athleteID
            auditAction = .attendance

        case .selection(let athleteID, let selection):
            guard let index = state.athletes.firstIndex(where: { $0.id == athleteID }) else { return false }
            let count = state.athletes.filter { $0.selection == selection }.count
            if state.athletes[index].selection != selection {
                if selection == .provisional, count >= state.settings.provisionalAthleteLimit { return false }
                if selection == .interschool, count >= state.settings.interschoolAthleteLimit { return false }
            }
            state.athletes[index].selection = selection
            targetID = athleteID
            auditAction = .selection

        case .team(let athleteID, let placement, let scope):
            guard let athlete = state.athletes.first(where: { $0.id == athleteID }),
                  athlete.division == scope.division,
                  scope.gender.map { athlete.gender == $0 } ?? true,
                  scope.stage.includes(athlete.selection)
            else { return false }
            var board = state.teamBoards[scope.id] ?? TeamBoard()
            board.teamA.removeAll { $0 == athleteID }
            board.teamB.removeAll { $0 == athleteID }
            if placement == .teamA { board.teamA.append(athleteID) }
            if placement == .teamB { board.teamB.append(athleteID) }
            state.teamBoards[scope.id] = board
            targetID = athleteID
            auditAction = .team
        }

        state.assistantAudit.append(AssistantAuditRecord(
            id: UUID(),
            command: proposal.command,
            summary: proposal.detail,
            action: auditAction,
            targetIDs: [targetID],
            addedAt: .now,
            addedBy: coachName,
            undoneAt: nil,
            undoneBy: nil
        ))
        state.normalize()
        return true
    }

    private static func rankedAnswer(input: String, state: AthleticsState) -> AssistantInterpretation {
        guard let event = event(input) else { return .error("Which event should I rank?") }
        let cohort = filteredCohort(input: input, athletes: state.athletes)
        let limit = resultLimit(input)
        let ranked = cohort.compactMap { athlete -> (Athlete, ResultRecord)? in
            guard let result = ResultRanking.bestResult(
                for: athlete.id,
                event: event,
                results: state.results
            ) else { return nil }
            return (athlete, result)
        }.sorted {
            event.isTimed ? $0.1.value < $1.1.value : $0.1.value > $1.1.value
        }
        guard !ranked.isEmpty else {
            return .answer("There are no valid \(event.rawValue) results for that group yet.", [])
        }
        let items = ranked.prefix(limit).enumerated().map {
            "\($0.offset + 1). \($0.element.0.name) — \($0.element.1.formattedAssistantValue)"
        }
        return .answer("Top \(items.count) for \(event.rawValue)", items)
    }

    private static func missingAnswer(input: String, state: AthleticsState) -> AssistantInterpretation {
        guard let event = event(input) else { return .error("Which event should I check for missing results?") }
        let missing = filteredCohort(input: input, athletes: state.athletes).filter {
            ResultRanking.bestResult(for: $0.id, event: event, results: state.results) == nil
        }
        if missing.isEmpty {
            return .answer("Everyone in that group has a valid \(event.rawValue) result.", [])
        }
        return .answer(
            "\(missing.count) students without a \(event.rawValue) result:",
            missing.prefix(30).map { "\($0.name) — \($0.className)" }
        )
    }

    private static func filteredCohort(input: String, athletes: [Athlete]) -> [Athlete] {
        let year = firstInteger(after: "year", in: input)
        let gender: AthleteGender? = input.contains("boys") ? .boys : input.contains("girls") ? .girls : nil
        return athletes.filter { athlete in
            (year.map { value in athlete.year == value } ?? true)
                && (gender.map { value in athlete.gender == value } ?? true)
        }
    }

    private static func matchedAthlete(_ input: String, athletes: [Athlete]) -> Athlete? {
        let matches = athletes.filter { input.contains(normalized($0.name)) }
        return matches.count == 1 ? matches[0] : nil
    }

    private static func attendanceStatus(_ input: String) -> AttendanceStatus? {
        if input.contains("absent") { return .absent }
        if input.contains("late") { return .late }
        if input.contains("present") { return .present }
        return nil
    }

    private static func selection(_ input: String) -> SquadSelection? {
        guard input.contains("selection") || input.contains("squad") || input.contains("move")
            || input.contains("make") || input.contains("mark")
        else { return nil }
        if input.contains("reserve") { return .reserve }
        if input.contains("interschool") { return .interschool }
        if input.contains("provisional") { return .provisional }
        if input.contains("class only") { return .classOnly }
        return nil
    }

    private static func teamEvent(_ input: String) -> TeamEvent? {
        TeamEvent.allCases.first { input.contains(normalized($0.rawValue)) }
    }

    private static func teamPlacement(_ input: String) -> TeamPlacement? {
        if input.contains("team a") { return .teamA }
        if input.contains("team b") { return .teamB }
        if input.contains("available") { return .available }
        return nil
    }

    private static func event(_ input: String) -> AthleticsEvent? {
        let aliases: [(AthleticsEvent, [String])] = [
            (.longJump, ["long jump"]),
            (.sprintRelay, ["sprint relay", "relay"]),
            (.passBall, ["pass ball"]),
            (.tunnelBall, ["tunnel ball"]),
            (.leaderBall, ["leader ball"]),
            (.sprint400, ["400m", "400 m"]),
            (.sprint200, ["200m", "200 m"]),
            (.sprint100, ["100m", "100 m"]),
            (.sprint75, ["75m", "75 m"])
        ]
        return aliases.first { pair in pair.1.contains(where: input.contains) }?.0
    }

    private static func performance(_ input: String, event: AthleticsEvent) -> Double? {
        let pattern = event.isTimed
            ? #"(\d+(?:\.\d+)?)\s*(?:seconds?|secs?|s)\b"#
            : #"(\d+(?:\.\d+)?)\s*(?:metres?|meters?|m)\b"#
        guard let range = input.range(of: pattern, options: .regularExpression) else { return nil }
        let match = String(input[range])
        guard let numberRange = match.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) else { return nil }
        return Double(match[numberRange])
    }

    private static func resultLimit(_ input: String) -> Int {
        let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8]
        if let value = words.first(where: { input.contains("top \($0.key)") || input.contains("fastest \($0.key)") })?.value {
            return value
        }
        if let value = firstInteger(after: "top", in: input) { return min(max(value, 1), 8) }
        if let value = firstInteger(after: "fastest", in: input) { return min(max(value, 1), 8) }
        return 3
    }

    private static func firstInteger(after marker: String, in input: String) -> Int? {
        guard let markerRange = input.range(of: marker) else { return nil }
        let tail = input[markerRange.upperBound...]
        guard let range = tail.range(of: #"\d+"#, options: .regularExpression) else { return nil }
        return Int(tail[range])
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: #"[^a-z0-9.]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension ResultRecord {
    var formattedAssistantValue: String {
        value.formatted(.number.precision(.fractionLength(2))) + (event.isTimed ? "s" : "m")
    }
}
