import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var draft = ProgramSettings()
    @State private var loaded = false
    @State private var savedPulse = false
    @State private var isConfirmingReset = false
    @State private var resetConfirmation = ""
    @State private var backupItem: SettingsBackupItem?
    @State private var backupImporterPresented = false
    @State private var backupMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("School or program name", text: $draft.schoolName)
                TextField("Term label", text: $draft.termLabel)
            } header: {
                Text("Program")
            } footer: {
                Text("These labels appear throughout the coaching workspace.")
            }

            Section("Training session") {
                Picker("Training day", selection: $draft.trainingDay) {
                    ForEach(Self.weekdays, id: \.self) { Text($0).tag($0) }
                }
                DatePicker(
                    "Start time",
                    selection: timeBinding(\.sessionStart, fallbackHour: 15, minute: 10),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "End time",
                    selection: timeBinding(\.sessionEnd, fallbackHour: 16, minute: 5),
                    displayedComponents: .hourAndMinute
                )
            }

            Section {
                ForEach($draft.coaches) { $coach in
                    HStack {
                        TextField("Coach name", text: $coach.name)
                            .textInputAutocapitalization(.words)
                        if draft.coaches.count > 1 {
                            Button(role: .destructive) {
                                draft.coaches.removeAll { $0.id == coach.id }
                            } label: {
                                Label("Remove \(coach.name)", systemImage: "minus.circle")
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                        }
                    }
                }
                Button {
                    draft.coaches.append(Coach(name: ""))
                } label: {
                    Label("Add coach", systemImage: "person.badge.plus")
                }
            } header: {
                Text("Coaches")
            } footer: {
                Text("Finish typing before saving. Blank coach names are not saved.")
            }

            Section {
                Picker(
                    "Programming",
                    selection: $draft.coachProgramsAreShared
                ) {
                    Text("One shared program").tag(true)
                    Text("Separate coach programs").tag(false)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Coach programs")
            } footer: {
                Text(
                    draft.coachProgramsAreShared
                        ? "Every coach sees and edits the same seven-week program."
                        : "Each coach can open, edit and inspect their own program from Sessions."
                )
            }

            Section {
                Stepper(
                    "Provisional athletes: \(draft.provisionalAthleteLimit)",
                    value: $draft.provisionalAthleteLimit,
                    in: 1...500
                )
                Stepper(
                    "Interschool athletes: \(draft.interschoolAthleteLimit)",
                    value: $draft.interschoolAthleteLimit,
                    in: 1...500
                )
            } header: {
                Text("Squad capacity")
            } footer: {
                Text("Reserves do not use an interschool place. Change these limits at any time.")
            }

            EditableNameListSection(
                title: "Factions",
                addLabel: "Add faction",
                placeholder: "Faction name",
                minimumCount: 1,
                values: $draft.factions
            )

            EditableNameListSection(
                title: "Classes",
                addLabel: "Add class",
                placeholder: "Class name",
                minimumCount: 1,
                values: $draft.classes
            )

            Section {
                Button {
                    store.updateSettings(draft)
                    draft = store.state.settings
                    savedPulse.toggle()
                } label: {
                    Label("Save settings", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(CorsoTheme.orange)
                .disabled(!isValid)
            } footer: {
                if let error = store.lastSaveError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Text("Settings are saved on this iPad.")
                }
            }

            Section {
                Button("Export full backup", systemImage: "square.and.arrow.up") {
                    exportBackup()
                }
                Button("Restore from backup", systemImage: "square.and.arrow.down") {
                    backupImporterPresented = true
                }
                Button("Reset this iPad workspace", systemImage: "trash", role: .destructive) {
                    resetConfirmation = ""
                    isConfirmingReset = true
                }
            } header: {
                Text("Data and recovery")
            } footer: {
                Text("Backups include students, results, attendance, sessions, team boards, event assignments and permission-slip wording. Whiteboards are exported separately in Board.")
            }
        }
        .navigationTitle("Settings")
        .task {
            guard !loaded else { return }
            draft = store.state.settings
            loaded = true
        }
        .sensoryFeedback(.success, trigger: savedPulse)
        .alert("Reset workspace?", isPresented: $isConfirmingReset) {
            TextField("Type RESET", text: $resetConfirmation)
                .textInputAutocapitalization(.characters)
            Button("Cancel", role: .cancel) { resetConfirmation = "" }
            Button("Reset", role: .destructive) {
                guard resetConfirmation == "RESET" else { return }
                store.resetWorkspace()
                draft = store.state.settings
                resetConfirmation = ""
            }
            .disabled(resetConfirmation != "RESET")
        } message: {
            Text("This cannot be undone. Type RESET to confirm.")
        }
        .sheet(item: $backupItem) { item in
            CorsoShareSheet(url: item.url)
        }
        .fileImporter(
            isPresented: $backupImporterPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard case .success(let urls) = result, let url = urls.first else { return }
                let payload = try AthleticsBackupService.restore(from: url)
                store.restoreWorkspace(payload.state)
                draft = store.state.settings
                backupMessage = "Backup restored successfully."
            } catch {
                backupMessage = error.localizedDescription
            }
        }
        .alert("Backup and restore", isPresented: Binding(
            get: { backupMessage != nil },
            set: { if !$0 { backupMessage = nil } }
        )) {
            Button("OK", role: .cancel) { backupMessage = nil }
        } message: {
            Text(backupMessage ?? "")
        }
    }

    private var isValid: Bool {
        SettingsDraftValidator.isValid(draft)
    }

    private func exportBackup() {
        do {
            backupItem = SettingsBackupItem(url: try AthleticsBackupService.export(store.state))
        } catch {
            backupMessage = error.localizedDescription
        }
    }

    private func timeBinding(
        _ keyPath: WritableKeyPath<ProgramSettings, String>,
        fallbackHour: Int,
        minute: Int
    ) -> Binding<Date> {
        Binding {
            Self.date(from: draft[keyPath: keyPath], fallbackHour: fallbackHour, minute: minute)
        } set: { date in
            draft[keyPath: keyPath] = Self.makeTimeFormatter().string(from: date)
        }
    }

    private static func date(from time: String, fallbackHour: Int, minute: Int) -> Date {
        if let date = makeTimeFormatter().date(from: time) { return date }
        return Calendar.current.date(bySettingHour: fallbackHour, minute: minute, second: 0, of: .now) ?? .now
    }

    private static func makeTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private static let weekdays = [
        "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
    ]
}

private struct SettingsBackupItem: Identifiable {
    let url: URL
    var id: URL { url }
}

enum SettingsDraftValidator {
    static func isValid(_ settings: ProgramSettings) -> Bool {
        !settings.schoolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && settings.coaches.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && settings.factions.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && settings.classes.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private struct EditableNameListSection: View {
    let title: String
    let addLabel: String
    let placeholder: String
    let minimumCount: Int
    @Binding var values: [String]

    var body: some View {
        Section {
            ForEach(values.indices, id: \.self) { index in
                HStack {
                    TextField(placeholder, text: $values[index])
                        .textInputAutocapitalization(.words)
                    if values.count > minimumCount {
                        Button(role: .destructive) {
                            values.remove(at: index)
                        } label: {
                            Label("Remove \(values[index])", systemImage: "minus.circle")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                }
            }
            Button {
                values.append("")
            } label: {
                Label(addLabel, systemImage: "plus.circle")
            }
        } header: {
            Text(title)
        }
    }
}
