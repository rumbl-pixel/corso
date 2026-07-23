import SwiftUI

struct StudentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    private let original: Athlete?
    private let settings: ProgramSettings
    private let save: (Athlete) -> Void

    @State private var name: String
    @State private var year: Int
    @State private var gender: AthleteGender
    @State private var faction: String
    @State private var className: String

    init(
        athlete: Athlete?,
        settings: ProgramSettings,
        save: @escaping (Athlete) -> Void
    ) {
        original = athlete
        self.settings = settings
        self.save = save
        _name = State(initialValue: athlete?.name ?? "")
        _year = State(initialValue: athlete?.year ?? 3)
        _gender = State(initialValue: athlete?.gender ?? .unspecified)
        _faction = State(initialValue: athlete?.faction ?? settings.factions.first ?? "Unassigned")
        _className = State(initialValue: athlete?.className ?? settings.classes.first ?? "Unassigned")
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Student") {
                    TextField("Full name", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                    Picker("Year group", selection: $year) {
                        ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                    }
                    LabeledContent("Division", value: CompetitionDivision.forYear(year).rawValue)
                    Picker("Gender", selection: $gender) {
                        ForEach(AthleteGender.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("School grouping") {
                    Picker("Class", selection: $className) {
                        ForEach(options(current: className, within: settings.classes), id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Faction", selection: $faction) {
                        ForEach(options(current: faction, within: settings.factions), id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .navigationTitle(original == nil ? "Add student" : "Edit student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save(
                            Athlete(
                                id: original?.id ?? UUID(),
                                name: cleanName,
                                year: year,
                                gender: gender,
                                faction: faction,
                                className: className,
                                selection: original?.selection ?? .classOnly,
                                attendance: original?.attendance ?? [:]
                            )
                        )
                        dismiss()
                    }
                    .disabled(cleanName.isEmpty)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 600)
        .interactiveDismissDisabled(!cleanName.isEmpty && cleanName != original?.name)
    }

    private func options(current: String, within values: [String]) -> [String] {
        values.contains(current) ? values : [current] + values
    }
}
