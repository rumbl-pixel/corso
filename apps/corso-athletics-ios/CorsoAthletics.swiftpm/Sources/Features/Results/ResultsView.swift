import AVKit
import SwiftUI
import UniformTypeIdentifiers

struct ResultsView: View {
    @Environment(AthleticsStore.self) private var store
    @State private var eventFilter: AthleticsEvent?
    @State private var sheet: ResultsSheet?

    init(initialEvent: AthleticsEvent? = nil) {
        _eventFilter = State(initialValue: initialEvent)
    }

    private var results: [ResultRecord] {
        store.state.results
            .filter { result in
                eventFilter.map { event in result.event == event } ?? true
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if results.isEmpty {
                ContentUnavailableView(
                    "No results in this view",
                    systemImage: "trophy",
                    description: Text(store.state.athletes.isEmpty
                        ? "Add students before recording results."
                        : "Record a result or choose another event.")
                )
            } else {
                List(results) { result in
                    ResultHistoryRow(
                        result: result,
                        athlete: store.state.athletes.first { $0.id == result.athleteID }
                    ) {
                        sheet = .edit(result)
                    } delete: {
                        store.deleteResult(id: result.id)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Results")
        .sheet(item: $sheet) { destination in
            switch destination {
            case .record:
                ResultEditorView(initialEvent: eventFilter)
            case .edit(let result):
                ResultEditorView(result: result)
            case .divisions:
                NavigationStack { RaceDivisionsView() }
            case .video:
                NavigationStack { RaceVideoTimerView() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                CorsoSectionTitle(eyebrow: "Evidence for selection", title: "Results")
                Spacer()
                Button("Build divisions", systemImage: "figure.run") {
                    sheet = .divisions
                }
                .buttonStyle(.bordered)
                .disabled(store.state.athletes.isEmpty)

                Button("Race video", systemImage: "video") {
                    sheet = .video
                }
                .buttonStyle(.bordered)
                .disabled(store.state.athletes.isEmpty)

                Button("Record result", systemImage: "plus") {
                    sheet = .record
                }
                .buttonStyle(.borderedProminent)
                .tint(CorsoTheme.orange)
                .disabled(store.state.athletes.isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ResultFilterButton(title: "All", selected: eventFilter == nil) {
                        eventFilter = nil
                    }
                    ForEach(AthleticsEvent.allCases) { event in
                        ResultFilterButton(title: event.rawValue, selected: eventFilter == event) {
                            eventFilter = event
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(CorsoTheme.paper)
    }
}

private enum ResultsSheet: Identifiable {
    case record
    case edit(ResultRecord)
    case divisions
    case video

    var id: String {
        switch self {
        case .record: return "record"
        case .edit(let result): return result.id.uuidString
        case .divisions: return "divisions"
        case .video: return "video"
        }
    }
}

private struct ResultFilterButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? .white : CorsoTheme.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(selected ? CorsoTheme.navy : CorsoTheme.navy.opacity(0.07), in: Capsule())
            .buttonStyle(.plain)
    }
}

private struct ResultHistoryRow: View {
    let result: ResultRecord
    let athlete: Athlete?
    let edit: () -> Void
    let delete: () -> Void
    @State private var confirmsDelete = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(athlete?.name ?? "Unknown student")
                    .font(.headline)
                Text("\(result.event.rawValue) · \(result.source.label)")
                    .font(.caption)
                    .foregroundStyle(CorsoTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(result.formattedValue)
                .font(.title3.monospacedDigit().weight(.black))
                .foregroundStyle(CorsoTheme.navy)
                .frame(width: 100, alignment: .trailing)

            if let effort = result.effort {
                Text("Effort \(effort)/5")
                    .font(.caption.weight(.semibold))
                    .frame(width: 78)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.date.formatted(date: .abbreviated, time: .omitted))
                Text("Added by \(result.addedBy)")
                    .foregroundStyle(CorsoTheme.muted)
            }
            .font(.caption)
            .frame(width: 150, alignment: .leading)

            Text(result.note.isEmpty ? "—" : result.note)
                .font(.caption)
                .foregroundStyle(CorsoTheme.muted)
                .lineLimit(2)
                .frame(width: 150, alignment: .leading)

            Button("Edit", systemImage: "pencil", action: edit)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            Button("Delete", systemImage: "trash", role: .destructive) {
                confirmsDelete = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 6)
        .confirmationDialog("Delete this result?", isPresented: $confirmsDelete) {
            Button("Delete result", role: .destructive, action: delete)
        }
    }
}

private struct ResultEditorView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: ResultRecord?
    @State private var athleteID: UUID?
    @State private var event: AthleticsEvent
    @State private var value: String
    @State private var date: Date
    @State private var effort: Int
    @State private var note: String
    @State private var source: ResultSource

    init(result: ResultRecord? = nil, initialEvent: AthleticsEvent? = nil) {
        existing = result
        _athleteID = State(initialValue: result?.athleteID)
        _event = State(initialValue: result?.event ?? initialEvent ?? .sprint75)
        _value = State(initialValue: result.map { String($0.value) } ?? "")
        _date = State(initialValue: result?.date ?? .now)
        _effort = State(initialValue: result?.effort ?? 3)
        _note = State(initialValue: result?.note ?? "")
        _source = State(initialValue: result?.source ?? .training)
    }

    private var parsedValue: Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Student", selection: $athleteID) {
                    Text("Choose student").tag(UUID?.none)
                    ForEach(store.state.athletes) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Event", selection: $event) {
                    ForEach(AthleticsEvent.allCases) { Text($0.rawValue).tag($0) }
                }
                TextField(event.isTimed ? "Time in seconds" : "Distance in metres", text: $value)
                    .keyboardType(.decimalPad)
                DatePicker("Result date", selection: $date, displayedComponents: .date)
                Picker("Effort", selection: $effort) {
                    ForEach(1...5, id: \.self) { Text("\($0)/5").tag($0) }
                }
                Picker("Source", selection: $source) {
                    ForEach(ResultSource.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                TextField("Coach note", text: $note, axis: .vertical)
                    .lineLimit(2...5)
            }
            .navigationTitle(existing == nil ? "Record result" : "Edit result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(athleteID == nil || parsedValue.map { $0 <= 0 } ?? true)
                }
            }
        }
    }

    private func save() {
        guard let athleteID, let parsedValue, parsedValue > 0 else { return }
        if var existing {
            existing.athleteID = athleteID
            existing.event = event
            existing.value = parsedValue
            existing.unit = event.resultUnit
            existing.date = date
            existing.effort = effort
            existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.source = source
            _ = store.updateResult(existing)
        } else {
            _ = store.recordResult(
                athleteID: athleteID,
                event: event,
                value: parsedValue,
                effort: effort,
                note: note,
                date: date,
                source: source
            )
        }
        dismiss()
    }
}

private struct RaceDivisionsView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var event: AthleticsEvent = .sprint75
    @State private var year = 3
    @State private var gender: AthleteGender = .boys
    @State private var maximumSize = 8

    private var eligible: [Athlete] {
        store.state.athletes.filter { $0.year == year && $0.gender == gender }
    }

    private var plan: RaceDivisionPlan {
        RaceDivisionBuilder.build(
            athletes: eligible,
            results: store.state.results,
            event: event,
            maximumSize: maximumSize
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Students are seeded by their best recorded time. Faster runners fill Division 1 first, and group sizes are balanced.")
                    .foregroundStyle(CorsoTheme.muted)

                HStack {
                    Picker("Race", selection: $event) {
                        ForEach(Self.raceEvents) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Year", selection: $year) {
                        ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                    }
                    Picker("Gender", selection: $gender) {
                        ForEach(AthleteGender.coachingGroups) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Maximum", selection: $maximumSize) {
                        ForEach([4, 6, 8], id: \.self) { Text("\($0) runners").tag($0) }
                    }
                }

                if plan.divisions.isEmpty {
                    ContentUnavailableView(
                        "No seeded divisions yet",
                        systemImage: "figure.run",
                        description: Text("Record at least one \(event.rawValue) time for this group.")
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
                        ForEach(plan.divisions) { division in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(division.name).font(.title3.weight(.bold))
                                    Spacer()
                                    Text("\(division.lanes.count) runners")
                                        .font(.caption)
                                        .foregroundStyle(CorsoTheme.muted)
                                }
                                ForEach(division.lanes) { lane in
                                    HStack {
                                        Text("Lane \(lane.lane)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(CorsoTheme.orange)
                                            .frame(width: 54, alignment: .leading)
                                        Text(lane.athlete.name)
                                        Spacer()
                                        Text(lane.bestSeconds.formatted(.number.precision(.fractionLength(2))) + "s")
                                            .monospacedDigit()
                                    }
                                }
                            }
                            .padding(16)
                            .corsoCard()
                        }
                    }
                }

                if !plan.untimed.isEmpty {
                    Label(
                        "Needs a recorded \(event.rawValue) time: \(plan.untimed.map(\.name).joined(separator: ", "))",
                        systemImage: "clock.badge.questionmark"
                    )
                    .font(.subheadline)
                    .padding(14)
                    .background(CorsoTheme.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
        .navigationTitle("Race divisions")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private static let raceEvents: [AthleticsEvent] = [
        .sprint75, .sprint100, .sprint200, .sprint400
    ]
}

private struct RaceVideoTimerView: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var year = 3
    @State private var gender: AthleteGender = .boys
    @State private var event: AthleticsEvent = .sprint75
    @State private var selected = Set<UUID>()
    @State private var player: AVPlayer?
    @State private var videoURL: URL?
    @State private var importerPresented = false
    @State private var cameraPresented = false
    @State private var videoUsesSecurityScope = false
    @State private var startTime: Double?
    @State private var finishTimes: [UUID: Double] = [:]
    @State private var playheadSeconds = 0.0
    @State private var timeObserver: Any?
    @State private var videoMessage: String?

    private var eligible: [Athlete] {
        store.state.athletes.filter { $0.year == year && $0.gender == gender }
    }

    private var selectedAthletes: [Athlete] {
        eligible.filter { selected.contains($0.id) }
    }

    var body: some View {
        HStack(spacing: 0) {
            Form {
                Section("Choose race") {
                    Picker("Year", selection: $year) {
                        ForEach(1...6, id: \.self) { Text("Year \($0)").tag($0) }
                    }
                    Picker("Gender", selection: $gender) {
                        ForEach(AthleteGender.coachingGroups) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Race", selection: $event) {
                        ForEach(Self.raceEvents) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Students") {
                    ForEach(eligible) { athlete in
                        Toggle(athlete.name, isOn: Binding(
                            get: { selected.contains(athlete.id) },
                            set: { enabled in
                                if enabled { selected.insert(athlete.id) }
                                else { selected.remove(athlete.id) }
                            }
                        ))
                    }
                }

                Section {
                    Button("Record race in Corso", systemImage: "camera.fill") {
                        beginCameraCapture()
                    }
                    Button("Choose existing video", systemImage: "folder") {
                        chooseExistingVideo()
                    }
                } footer: {
                    Text("Corso does not save race video after this review. Complete the video permission check in Settings before using either option.")
                }
            }
            .frame(width: 360)

            Divider()

            VStack(spacing: 16) {
                if let player {
                    VideoPlayer(player: player)
                        .frame(maxHeight: 390)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    HStack {
                        Button("Previous frame", systemImage: "backward.frame") { step(-1) }
                        Text(playheadSeconds.formatted(.number.precision(.fractionLength(3))) + "s")
                            .font(.headline.monospacedDigit())
                            .frame(minWidth: 90)
                        Button("Next frame", systemImage: "forward.frame") { step(1) }
                        Spacer()
                        Button("Mark race start", systemImage: "timer") {
                            startTime = currentSeconds
                            finishTimes = [:]
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CorsoTheme.orange)
                    }

                    if let startTime {
                        Text("Race start: \(startTime.formatted(.number.precision(.fractionLength(3))))s")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CorsoTheme.muted)
                    }

                    List(selectedAthletes) { athlete in
                        HStack {
                            Text(athlete.name)
                            Spacer()
                            Text(elapsed(for: athlete.id).map {
                                $0.formatted(.number.precision(.fractionLength(2))) + "s"
                            } ?? "—")
                            .font(.headline.monospacedDigit())
                            .frame(width: 80)
                            Button("Mark finish") {
                                finishTimes[athlete.id] = currentSeconds
                            }
                            .disabled(startTime == nil)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView(
                        "Race footage appears here",
                        systemImage: "video",
                        description: Text("Choose a video on the left, mark the start frame, then mark each student's finish.")
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle("Race video timer")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save times", action: saveTimes)
                    .disabled(finishTimes.isEmpty || startTime == nil)
            }
        }
        .fileImporter(
            isPresented: $importerPresented,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            loadVideo(url, securityScoped: true)
        }
        .sheet(isPresented: $cameraPresented) {
            RaceVideoCaptureView { url in
                cameraPresented = false
                if let url {
                    loadVideo(url, securityScoped: false)
                }
            }
            .ignoresSafeArea()
        }
        .alert("Race video", isPresented: Binding(
            get: { videoMessage != nil },
            set: { if !$0 { videoMessage = nil } }
        )) {
            Button("OK", role: .cancel) { videoMessage = nil }
        } message: {
            Text(videoMessage ?? "")
        }
        .onDisappear {
            releaseVideo()
        }
    }

    private var currentSeconds: Double {
        playheadSeconds
    }

    private func beginCameraCapture() {
        guard store.state.settings.pilotReadiness.isVideoReady else {
            videoMessage = "Before using race video, confirm local pilot approval, the school-managed device, approved recordkeeping process and parent/carer video permission in Settings."
            return
        }
        if RaceVideoCaptureView.cameraIsAvailable {
            cameraPresented = true
        } else {
            videoMessage = "A camera is not available on this device. Choose an existing race video instead."
        }
    }

    private func chooseExistingVideo() {
        guard store.state.settings.pilotReadiness.isVideoReady else {
            videoMessage = "Before using race video, confirm local pilot approval, the school-managed device, approved recordkeeping process and parent/carer video permission in Settings."
            return
        }
        importerPresented = true
    }

    private func step(_ direction: Int) {
        guard let player, let item = player.currentItem else { return }
        player.pause()
        item.step(byCount: direction)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(45))
            playheadSeconds = player.currentTime().seconds.finiteOrZero
        }
    }

    private func elapsed(for athleteID: UUID) -> Double? {
        guard let startTime, let finish = finishTimes[athleteID] else { return nil }
        return max(0, finish - startTime)
    }

    private func saveTimes() {
        for athlete in selectedAthletes {
            guard let value = elapsed(for: athlete.id), value > 0 else { continue }
            _ = store.recordResult(
                athleteID: athlete.id,
                event: event,
                value: value,
                note: "Video review · Year \(year) \(gender.rawValue)",
                source: .videoReview
            )
        }
        dismiss()
    }

    private func loadVideo(_ url: URL, securityScoped: Bool) {
        releaseVideo()
        let startedScope = securityScoped && url.startAccessingSecurityScopedResource()
        videoUsesSecurityScope = startedScope
        videoURL = url
        let nextPlayer = AVPlayer(url: url)
        nextPlayer.rate = 0
        player = nextPlayer
        playheadSeconds = 0
        startTime = nil
        finishTimes = [:]
        timeObserver = nextPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 120),
            queue: .main
        ) { time in
            Task { @MainActor in
                playheadSeconds = time.seconds.finiteOrZero
            }
        }
    }

    private func releaseVideo() {
        player?.pause()
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        if videoUsesSecurityScope {
            videoURL?.stopAccessingSecurityScopedResource()
        }
        videoUsesSecurityScope = false
    }

    private static let raceEvents: [AthleticsEvent] = [
        .sprint75, .sprint100, .sprint200, .sprint400
    ]
}

private extension ResultRecord {
    var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(2)))
            + (event.isTimed ? "s" : "m")
    }
}

private extension ResultSource {
    var label: String {
        switch self {
        case .classLesson: return "Class lesson"
        case .training: return "Training"
        case .carnival: return "Carnival"
        case .videoReview: return "Video review"
        case .importFile: return "Import"
        case .unknown: return "Historical"
        }
    }
}

private extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
