import SwiftUI

struct StudentDirectoryView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var query = ""
    @State private var year: Int?
    @State private var faction: String?
    @State private var className: String?
    @State private var sheet: StudentSheetRoute?

    private var athletes: [Athlete] {
        StudentFilter.apply(
            store.state.athletes,
            query: query,
            year: year,
            faction: faction,
            className: className
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            StudentFilterBar(
                year: $year,
                faction: $faction,
                className: $className,
                factions: store.state.settings.factions,
                classes: store.state.settings.classes
            )
            Divider()

            if athletes.isEmpty {
                ContentUnavailableView(
                    store.state.athletes.isEmpty ? "No students yet" : "No matching students",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text(store.state.athletes.isEmpty
                        ? "Add the first student to start recording athletics evidence."
                        : "Change or clear a filter to see more students.")
                )
            } else {
                List(athletes) { athlete in
                    StudentRow(athlete: athlete) {
                        sheet = .edit(athlete)
                    } delete: {
                        store.deleteAthlete(id: athlete.id)
                    }
                }
                .listStyle(.plain)
            }
        }
        .searchable(text: $query, prompt: "Student, class or faction")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    sheet = .importStudents
                } label: {
                    Label("Import students", systemImage: "square.and.arrow.down")
                }
                Button {
                    sheet = .add
                } label: {
                    Label("Add student", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(item: $sheet) { route in
            switch route {
            case .importStudents:
                StudentImportView(classes: store.state.settings.classes)
            case .add, .edit(_):
                StudentEditorView(
                    athlete: route.athlete,
                    settings: store.state.settings
                ) { athlete in
                    if route.isNew {
                        store.addAthlete(athlete)
                    } else {
                        store.updateAthlete(athlete)
                    }
                }
            }
        }
    }
}

enum StudentSheetRoute: Identifiable {
    case importStudents
    case add
    case edit(Athlete)

    var id: String {
        switch self {
        case .importStudents:
            return "importStudents"
        case .add:
            return "add"
        case .edit(let athlete):
            return athlete.id.uuidString
        }
    }

    var athlete: Athlete? {
        if case .edit(let athlete) = self { return athlete }
        return nil
    }

    var isNew: Bool {
        if case .add = self { return true }
        return false
    }
}

enum StudentFilter {
    static func apply(
        _ athletes: [Athlete],
        query: String,
        year: Int?,
        faction: String?,
        className: String?
    ) -> [Athlete] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return athletes.filter { athlete in
            let matchesSearch = search.isEmpty
                || athlete.name.localizedCaseInsensitiveContains(search)
                || athlete.className.localizedCaseInsensitiveContains(search)
                || athlete.faction.localizedCaseInsensitiveContains(search)
            return matchesSearch
                && (year.map { athlete.year == $0 } ?? true)
                && (faction.map { athlete.faction == $0 } ?? true)
                && (className.map { athlete.className == $0 } ?? true)
        }
    }
}

private struct StudentFilterBar: View {
    @Binding var year: Int?
    @Binding var faction: String?
    @Binding var className: String?
    let factions: [String]
    let classes: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterMenu(title: "Year", value: year.map(String.init)) {
                    Button("All years") { year = nil }
                    ForEach(1...6, id: \.self) { item in
                        Button("Year \(item)") { year = item }
                    }
                }
                FilterMenu(title: "Faction", value: faction) {
                    Button("All factions") { faction = nil }
                    ForEach(factions, id: \.self) { item in
                        Button(item) { faction = item }
                    }
                }
                FilterMenu(title: "Class", value: className) {
                    Button("All classes") { className = nil }
                    ForEach(classes, id: \.self) { item in
                        Button(item) { className = item }
                    }
                }

                if year != nil || faction != nil || className != nil {
                    Button("Clear filters") {
                        year = nil
                        faction = nil
                        className = nil
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(CorsoTheme.paper)
    }
}

private struct FilterMenu<Content: View>: View {
    let title: String
    let value: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                Text(value ?? title)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(value == nil ? CorsoTheme.navy.opacity(0.07) : CorsoTheme.orange.opacity(0.12))
            .foregroundStyle(value == nil ? CorsoTheme.ink : CorsoTheme.orangeDark)
            .clipShape(Capsule())
        }
    }
}

private struct StudentRow: View {
    let athlete: Athlete
    let edit: () -> Void
    let delete: () -> Void
    @State private var confirmsDelete = false

    var body: some View {
        HStack(spacing: 14) {
            Text(athlete.name.prefix(1).uppercased())
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(CorsoTheme.navy)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.name)
                    .font(.headline)
                Text("Year \(athlete.year) · \(athlete.division.rawValue) · \(athlete.className) · \(athlete.faction)")
                    .font(.caption)
                    .foregroundStyle(CorsoTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(athlete.gender.rawValue)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(CorsoTheme.navy.opacity(0.07), in: Capsule())

            Button(action: edit) {
                Label("Edit", systemImage: "pencil")
            }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)

            Button(role: .destructive) {
                confirmsDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 5)
        .confirmationDialog(
            "Delete \(athlete.name)?",
            isPresented: $confirmsDelete,
            titleVisibility: .visible
        ) {
            Button("Delete student and results", role: .destructive, action: delete)
        } message: {
            Text("This permanently removes the student and their recorded results.")
        }
    }
}
