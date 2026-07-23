import SwiftUI

struct PermissionSlipsView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var kind: PermissionSlipKind = .provisionalTraining
    @State private var settings = PermissionSlipSettings()
    @State private var recipients = Set<UUID>()
    @State private var exportItem: PermissionSlipExportItem?
    @State private var exportError: String?
    @State private var loaded = false

    private var eligible: [Athlete] {
        store.state.athletes.filter {
            switch kind {
            case .provisionalTraining:
                return $0.selection == .provisional
            case .interschoolCarnival:
                return $0.selection == .interschool || $0.selection == .reserve
            }
        }
    }

    private var selectedAthletes: [Athlete] {
        eligible.filter { recipients.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: 0) {
            Form {
                Section {
                    Picker("Document", selection: $kind) {
                        ForEach(PermissionSlipKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Letter wording") {
                    TextField("Document title", text: templateBinding(\.title))
                    TextField("Letter body", text: templateBinding(\.body), axis: .vertical)
                        .lineLimit(7...14)
                    TextField("Permission statement", text: templateBinding(\.acknowledgement), axis: .vertical)
                        .lineLimit(2...4)
                }

                Section(kind == .provisionalTraining ? "Training details" : "Carnival details") {
                    if kind == .provisionalTraining {
                        TextField("Training details", text: $settings.trainingDetails)
                    } else {
                        TextField("Carnival details", text: $settings.carnivalDetails)
                    }
                    TextField("Contact name", text: $settings.contactName)
                    TextField("Contact details", text: $settings.contactDetails)
                }

                Section {
                    Text("Placeholders: {{studentName}}, {{studentYear}}, {{studentClass}}, {{studentFaction}}, {{studentEvents}}")
                        .font(.caption)
                        .foregroundStyle(CorsoTheme.muted)
                    Button("Restore default wording", systemImage: "arrow.counterclockwise") {
                        let defaults = PermissionSlipSettings()
                        settings[kind] = defaults[kind]
                    }
                }
            }
            .frame(minWidth: 440)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Recipients").font(.title3.weight(.bold))
                        Text("\(selectedAthletes.count) of \(eligible.count) selected")
                            .font(.caption)
                            .foregroundStyle(CorsoTheme.muted)
                    }
                    Spacer()
                    Button(recipients.count == eligible.count && !eligible.isEmpty ? "Clear" : "Select all") {
                        if recipients.count == eligible.count {
                            recipients.removeAll()
                        } else {
                            recipients = Set(eligible.map(\.id))
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding()

                List(eligible) { athlete in
                    Toggle(isOn: Binding(
                        get: { recipients.contains(athlete.id) },
                        set: { selected in
                            if selected { recipients.insert(athlete.id) }
                            else { recipients.remove(athlete.id) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(athlete.name)
                            Text("Year \(athlete.year) · \(athlete.className) · \(athlete.events.count) events")
                                .font(.caption)
                                .foregroundStyle(CorsoTheme.muted)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .frame(minWidth: 330)
        }
        .navigationTitle("Permission slips")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .confirmationAction) {
                Button("Save wording") {
                    store.updatePermissionSlipSettings(settings)
                }
                Button("Create PDF", systemImage: "printer", action: export)
                    .disabled(selectedAthletes.isEmpty)
            }
        }
        .task {
            guard !loaded else { return }
            settings = store.state.permissionSlips
            recipients = Set(eligible.map(\.id))
            loaded = true
        }
        .onChange(of: kind) {
            recipients = Set(eligible.map(\.id))
        }
        .sheet(item: $exportItem) { item in
            CorsoShareSheet(url: item.url)
        }
        .alert("Permission slip export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "The PDF could not be created.")
        }
    }

    private func templateBinding(
        _ keyPath: WritableKeyPath<PermissionSlipTemplate, String>
    ) -> Binding<String> {
        Binding {
            settings[kind][keyPath: keyPath]
        } set: { value in
            var template = settings[kind]
            template[keyPath: keyPath] = value
            settings[kind] = template
        }
    }

    private func export() {
        store.updatePermissionSlipSettings(settings)
        do {
            exportItem = PermissionSlipExportItem(
                url: try PermissionSlipExporter.export(
                    schoolName: store.state.settings.schoolName,
                    kind: kind,
                    settings: settings,
                    athletes: selectedAthletes
                )
            )
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct PermissionSlipExportItem: Identifiable {
    let url: URL
    var id: URL { url }
}
