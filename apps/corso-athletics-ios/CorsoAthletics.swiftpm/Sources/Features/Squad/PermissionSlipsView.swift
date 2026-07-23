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
        GeometryReader { proxy in
            if proxy.size.width >= 900 {
                HStack(spacing: 0) {
                    permissionEditor
                        .frame(width: proxy.size.width * 0.62)
                    Divider()
                    recipientList
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 0) {
                    permissionEditor
                    Divider()
                    recipientList
                        .frame(minHeight: 260)
                }
            }
        }
        .background(CorsoTheme.cream)
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

    private var permissionEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Document", selection: $kind) {
                    ForEach(PermissionSlipKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                editorCard("Letter wording") {
                    labeledField("Document title") {
                        TextField("Document title", text: templateBinding(\.title))
                            .textFieldStyle(.roundedBorder)
                    }
                    labeledField("Letter body") {
                        TextEditor(text: templateBinding(\.body))
                            .frame(minHeight: 190)
                            .padding(8)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CorsoTheme.sand)
                            }
                    }
                    labeledField("Permission statement") {
                        TextField(
                            "Permission statement",
                            text: templateBinding(\.acknowledgement),
                            axis: .vertical
                        )
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                    }
                }

                editorCard(kind == .provisionalTraining ? "Training details" : "Carnival details") {
                    if kind == .provisionalTraining {
                        labeledField("Training details") {
                            TextField("Training details", text: $settings.trainingDetails)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        labeledField("Carnival details") {
                            TextField("Carnival details", text: $settings.carnivalDetails)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    labeledField("Contact name") {
                        TextField("Contact name", text: $settings.contactName)
                            .textFieldStyle(.roundedBorder)
                    }
                    labeledField("Contact details") {
                        TextField("Contact details", text: $settings.contactDetails)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                HStack(alignment: .top) {
                    Text("Placeholders: {{studentName}}, {{studentYear}}, {{studentClass}}, {{studentFaction}}, {{studentEvents}}")
                        .font(.caption)
                        .foregroundStyle(CorsoTheme.muted)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Restore default wording", systemImage: "arrow.counterclockwise") {
                        let defaults = PermissionSlipSettings()
                        settings[kind] = defaults[kind]
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(22)
        }
    }

    private var recipientList: some View {
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

            if eligible.isEmpty {
                ContentUnavailableView(
                    "No eligible students",
                    systemImage: "doc.text",
                    description: Text("Select students for this squad stage first.")
                )
            } else {
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
        }
        .background(CorsoTheme.paper)
    }

    private func editorCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(CorsoTheme.muted)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .corsoCard()
    }

    private func labeledField<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(CorsoTheme.muted)
            content()
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
