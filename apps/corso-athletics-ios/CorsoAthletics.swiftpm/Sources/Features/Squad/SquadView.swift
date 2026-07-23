import SwiftUI

struct SquadView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var workspace: SquadWorkspace = .selection
    @State private var shownSelection: SquadSelection?
    @State private var division: CompetitionDivision?
    @State private var gender: AthleteGender?
    @State private var query = ""
    @State private var permissionSlipsPresented = false

    private var athletes: [Athlete] {
        SquadFilter.apply(
            store.state.athletes,
            query: query,
            selection: shownSelection,
            division: division,
            gender: gender
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            squadHeader
            Divider()

            switch workspace {
            case .selection:
                selectionWorkspace
            case .students:
                StudentDirectoryView()
            }
        }
        .navigationTitle("Squad")
        .sheet(isPresented: $permissionSlipsPresented) {
            NavigationStack { PermissionSlipsView() }
                .environment(store)
        }
    }

    private var squadHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                CorsoSectionTitle(eyebrow: "Selection", title: "Build the strongest fair squad")
                Spacer()
                Button("Permission slips", systemImage: "doc.text") {
                    permissionSlipsPresented = true
                }
                .buttonStyle(.bordered)
                .disabled(store.state.athletes.isEmpty)
                ViewThatFits(in: .horizontal) {
                    Picker("Squad workspace", selection: $workspace) {
                        ForEach(SquadWorkspace.allCases) { item in
                            Label(item.rawValue, systemImage: item.symbol).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 330)

                    Picker("Workspace", selection: $workspace) {
                        ForEach(SquadWorkspace.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            if workspace == .selection {
                HStack(spacing: 12) {
                    LabeledMenu(title: "Selection status", value: shownSelection?.rawValue ?? "All") {
                        Button("All students") { shownSelection = nil }
                        Divider()
                        ForEach(SquadSelection.allCases) { item in
                            Button(item.rawValue) { shownSelection = item }
                        }
                    }
                    LabeledMenu(title: "Competition division", value: division?.rawValue ?? "All") {
                        Button("All divisions") { division = nil }
                        Divider()
                        ForEach(CompetitionDivision.allCases) { item in
                            Button(item.rawValue) { division = item }
                        }
                    }
                    LabeledMenu(title: "Gender group", value: gender?.rawValue ?? "All") {
                        Button("All groups") { gender = nil }
                        Divider()
                        ForEach(AthleteGender.allCases) { item in
                            Button(item.rawValue) { gender = item }
                        }
                    }
                    Spacer()
                    Text("\(athletes.count) shown")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CorsoTheme.muted)
                }
            }
        }
        .padding(24)
        .background(CorsoTheme.paper)
    }

    @ViewBuilder
    private var selectionWorkspace: some View {
        if athletes.isEmpty {
            ContentUnavailableView(
                store.state.athletes.isEmpty ? "No students yet" : "No students match these filters",
                systemImage: "person.3.sequence",
                description: Text(store.state.athletes.isEmpty
                    ? "Open Student register above and add the first student."
                    : "Try another status, division or gender group.")
            )
        } else {
            List(athletes) { athlete in
                SquadSelectionRow(athlete: athlete) { selection in
                    store.updateSelection(for: athlete.id, to: selection)
                } eventUpdate: { event, assigned in
                    store.setEvent(event, assigned: assigned, for: athlete.id)
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Find student in squad")
        }
    }
}

enum SquadFilter {
    static func apply(
        _ athletes: [Athlete],
        query: String,
        selection: SquadSelection?,
        division: CompetitionDivision?,
        gender: AthleteGender?
    ) -> [Athlete] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return athletes.filter { athlete in
            let matchesQuery = cleanQuery.isEmpty
                || athlete.name.localizedCaseInsensitiveContains(cleanQuery)
            return matchesQuery
                && (selection.map { athlete.selection == $0 } ?? true)
                && (division.map { athlete.division == $0 } ?? true)
                && (gender.map { athlete.gender == $0 } ?? true)
        }
    }
}

enum SquadWorkspace: String, CaseIterable, Identifiable {
    case selection = "Squad selection"
    case students = "Student register"

    var id: Self { self }
    var symbol: String { self == .selection ? "person.3" : "person.text.rectangle" }
}

private struct LabeledMenu<Content: View>: View {
    let title: String
    let value: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(CorsoTheme.muted)
            Menu {
                content()
            } label: {
                HStack {
                    Text(value)
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CorsoTheme.ink)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(CorsoTheme.navy.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

private struct SquadSelectionRow: View {
    let athlete: Athlete
    let update: (SquadSelection) -> Void
    let eventUpdate: (AthleticsEvent, Bool) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                athleteSummary
                eventMenu
                selectionPicker
                    .pickerStyle(.segmented)
                    .frame(width: 470)
            }

            VStack(alignment: .leading, spacing: 10) {
                athleteSummary
                HStack {
                    eventMenu
                    Text("Selection status")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CorsoTheme.muted)
                    Spacer()
                    selectionPicker
                        .pickerStyle(.menu)
                }
            }
        }
        .padding(.vertical, 7)
    }

    private var athleteSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(athlete.name)
                .font(.headline)
            Text("Year \(athlete.year) · \(athlete.division.rawValue) · \(athlete.gender.rawValue) · \(athlete.className)")
                .font(.caption)
                .foregroundStyle(CorsoTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionPicker: some View {
        Picker(
            "Selection for \(athlete.name)",
            selection: Binding(get: { athlete.selection }, set: update)
        ) {
            ForEach(SquadSelection.allCases) { selection in
                Text(shortLabel(for: selection)).tag(selection)
            }
        }
        .accessibilityHint("A student can hold only one selection status")
    }

    private var eventMenu: some View {
        Menu {
            ForEach(AthleticsEvent.allCases) { event in
                Button {
                    eventUpdate(event, !athlete.events.contains(event))
                } label: {
                    if athlete.events.contains(event) {
                        Label(event.rawValue, systemImage: "checkmark")
                    } else {
                        Text(event.rawValue)
                    }
                }
            }
        } label: {
            Label(
                athlete.events.isEmpty ? "Assign events" : "\(athlete.events.count) events",
                systemImage: "list.bullet.clipboard"
            )
        }
        .buttonStyle(.bordered)
        .frame(width: 135)
    }

    private func shortLabel(for selection: SquadSelection) -> String {
        switch selection {
        case .classOnly:
            return "Class"
        case .provisional:
            return "Provisional"
        case .interschool:
            return "Interschool"
        case .reserve:
            return "Reserve"
        }
    }
}
