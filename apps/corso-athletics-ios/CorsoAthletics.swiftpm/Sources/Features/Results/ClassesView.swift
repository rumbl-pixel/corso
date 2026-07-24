import SwiftUI

struct ClassesView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var selectedClass: String?
    @State private var selectedYear: Int?
    @State private var selectedFaction: String?
    @State private var selectedEvent: AthleticsEvent = .sprint100
    @State private var reportItem: ClassReportExportItem?
    @State private var reportError: String?

    private var athletes: [Athlete] {
        StudentFilter.apply(
            store.state.athletes,
            query: "",
            year: selectedYear,
            faction: selectedFaction,
            className: selectedClass
        )
    }

    private var starredIDs: Set<UUID> {
        ResultRanking.topAthleteIDs(
            athletes: store.state.athletes,
            results: store.state.results,
            event: selectedEvent,
            limit: 3
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if athletes.isEmpty {
                ContentUnavailableView(
                    "No students in this view",
                    systemImage: "list.clipboard",
                    description: Text("Choose another class, year or faction, or add students in Squad.")
                )
            } else {
                List(athletes) { athlete in
                    ClassResultEntryRow(
                        athlete: athlete,
                        event: selectedEvent,
                        best: ResultRanking.bestResult(
                            for: athlete.id,
                            event: selectedEvent,
                            results: store.state.results
                        ),
                        isStarred: starredIDs.contains(athlete.id)
                    ) { value, effort, note in
                        store.recordResult(
                            athleteID: athlete.id,
                            event: selectedEvent,
                            value: value,
                            effort: effort,
                            note: note,
                            source: .classLesson
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Classes")
        .sheet(item: $reportItem) { item in
            ClassReportShareSheet(url: item.url)
        }
        .alert("Report export failed", isPresented: reportErrorBinding) {
            Button("OK", role: .cancel) { reportError = nil }
        } message: {
            Text(reportError ?? "The class report could not be created.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                CorsoSectionTitle(eyebrow: "Class evidence", title: "Record every effort")
                Spacer()
                Text("\(athletes.count) students")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CorsoTheme.muted)
                Button("Print / PDF", systemImage: "printer", action: exportReport)
                    .buttonStyle(.bordered)
                    .disabled(athletes.isEmpty)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    filterPickers
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        eventPicker
                        classPicker
                    }
                    HStack(spacing: 12) {
                        yearPicker
                        factionPicker
                    }
                }
            }
        }
        .padding(24)
        .background(CorsoTheme.paper)
    }

    static let classEvents: [AthleticsEvent] = [
        .sprint75, .sprint100, .sprint200, .sprint400, .longJump
    ]

    private var reportErrorBinding: Binding<Bool> {
        Binding(
            get: { reportError != nil },
            set: { if !$0 { reportError = nil } }
        )
    }

    private func exportReport() {
        do {
            reportItem = ClassReportExportItem(
                url: try ClassReportExporter.export(
                    schoolName: store.state.settings.schoolName,
                    athletes: athletes,
                    results: store.state.results,
                    event: selectedEvent
                )
            )
        } catch {
            reportError = error.localizedDescription
        }
    }

    private var filterPickers: some View {
        Group {
            eventPicker.frame(width: 190)
            classPicker.frame(width: 175)
            yearPicker.frame(width: 145)
            factionPicker.frame(width: 175)
        }
    }

    private var eventPicker: some View {
        Picker("Event", selection: $selectedEvent) {
            ForEach(Self.classEvents) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.menu)
    }

    private var classPicker: some View {
        Picker("Class", selection: $selectedClass) {
            Text("All classes").tag(String?.none)
            ForEach(store.state.settings.classes, id: \.self) { Text($0).tag(Optional($0)) }
        }
        .pickerStyle(.menu)
    }

    private var yearPicker: some View {
        Picker("Year", selection: $selectedYear) {
            Text("All years").tag(Int?.none)
            ForEach(1...6, id: \.self) { Text("Year \($0)").tag(Optional($0)) }
        }
        .pickerStyle(.menu)
    }

    private var factionPicker: some View {
        Picker("Faction", selection: $selectedFaction) {
            Text("All factions").tag(String?.none)
            ForEach(store.state.settings.factions, id: \.self) { Text($0).tag(Optional($0)) }
        }
        .pickerStyle(.menu)
    }
}

enum ResultRanking {
    private struct Cohort: Hashable {
        let year: Int
        let gender: AthleteGender
    }

    static func bestResult(
        for athleteID: UUID,
        event: AthleticsEvent,
        results: [ResultRecord]
    ) -> ResultRecord? {
        let matching = results.filter { $0.athleteID == athleteID && $0.event == event }
        return event.isTimed
            ? matching.min(by: { $0.value < $1.value })
            : matching.max(by: { $0.value < $1.value })
    }

    static func topAthleteIDs(
        athletes: [Athlete],
        results: [ResultRecord],
        event: AthleticsEvent,
        limit: Int
    ) -> Set<UUID> {
        let cohorts = Dictionary(grouping: athletes) {
            Cohort(year: $0.year, gender: $0.gender)
        }
        return cohorts.values.reduce(into: Set<UUID>()) { output, cohort in
            let athleteIDs = Set(cohort.map(\.id))
            let best = Dictionary(grouping: results.filter {
                $0.event == event && athleteIDs.contains($0.athleteID)
            }, by: \.athleteID).compactMap { athleteID, records -> (UUID, Double)? in
                guard let value = event.isTimed
                    ? records.map(\.value).min()
                    : records.map(\.value).max()
                else { return nil }
                return (athleteID, value)
            }
            let sorted = best.sorted { lhs, rhs in
                event.isTimed ? lhs.1 < rhs.1 : lhs.1 > rhs.1
            }
            output.formUnion(sorted.prefix(max(0, limit)).map(\.0))
        }
    }
}

private struct ClassResultEntryRow: View {
    let athlete: Athlete
    let event: AthleticsEvent
    let best: ResultRecord?
    let isStarred: Bool
    let save: (Double, Int?, String) -> Void

    @State private var value = ""
    @State private var effort = 3
    @State private var note = ""
    @State private var savedPulse = false

    private var parsedValue: Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                athleteSummary
                bestResult
                resultField
                effortPicker
                noteField
                saveButton
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    athleteSummary
                    bestResult
                }
                HStack(spacing: 10) {
                    resultField
                    effortPicker
                    saveButton
                }
                noteField
            }
        }
        .padding(.vertical, 6)
        .sensoryFeedback(.success, trigger: savedPulse)
    }

    private var athleteSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(athlete.name).font(.headline)
                if isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Top three result")
                }
            }
            Text("Year \(athlete.year) · \(athlete.className) · \(athlete.faction)")
                .font(.caption)
                .foregroundStyle(CorsoTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var bestResult: some View {
        if let best {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Best")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CorsoTheme.muted)
                Text(best.value.formatted(.number.precision(.fractionLength(2))) + unit)
                    .font(.subheadline.monospacedDigit().weight(.bold))
            }
            .frame(width: 82, alignment: .trailing)
        }
    }

    private var resultField: some View {
        TextField(event.isTimed ? "Seconds" : "Metres", text: $value)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 105)
            .accessibilityLabel("\(event.rawValue) result for \(athlete.name)")
    }

    private var effortPicker: some View {
        Picker("Effort", selection: $effort) {
            ForEach(1...5, id: \.self) { Text("Effort \($0)").tag($0) }
        }
        .frame(width: 105)
    }

    private var noteField: some View {
        TextField("Optional note", text: $note)
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 110, maxWidth: 150)
    }

    private var saveButton: some View {
        Button("Save") {
            guard let parsedValue, parsedValue > 0 else { return }
            save(parsedValue, effort, note.trimmingCharacters(in: .whitespacesAndNewlines))
            value = ""
            note = ""
            savedPulse.toggle()
        }
        .buttonStyle(.borderedProminent)
        .tint(CorsoTheme.orange)
        .disabled(parsedValue.map { $0 <= 0 } ?? true)
    }

    private var unit: String { event.isTimed ? "s" : "m" }
}
