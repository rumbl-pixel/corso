import SwiftUI

struct AttendanceSheet: View {
    @Environment(AthleticsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date.now
    @State private var query = ""

    private var isPast: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: .now)
    }

    private var isLocked: Bool { store.state.isAttendanceLocked(on: selectedDate) }

    private var filteredAthletes: [Athlete] {
        guard !query.isEmpty else { return store.state.athletes }
        return store.state.athletes.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls
                Divider()

                if filteredAthletes.isEmpty {
                    ContentUnavailableView(
                        "No athletes",
                        systemImage: "person.3",
                        description: Text("Add students in Squad, then take attendance here.")
                    )
                } else {
                    List(filteredAthletes) { athlete in
                        AttendanceRow(
                            athlete: athlete,
                            status: athlete.attendance[selectedDate.attendanceKey] ?? .unmarked,
                            locked: isLocked
                        ) { status in
                            store.markAttendance(for: athlete.id, on: selectedDate, as: status)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Attendance")
            .searchable(text: $query, prompt: "Find athlete")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                moveDate(by: -1)
            } label: {
                Label("Previous day", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)

            DatePicker("Attendance for", selection: $selectedDate, displayedComponents: .date)

            Button {
                moveDate(by: 1)
            } label: {
                Label("Next day", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)

            Spacer()
            if isPast {
                Button {
                    if isLocked {
                        store.unlockAttendance(on: selectedDate)
                    } else {
                        store.lockAttendance(on: selectedDate)
                    }
                } label: {
                    Label(
                        isLocked ? "Unlock past date" : "Lock past date",
                        systemImage: isLocked ? "lock" : "lock.open"
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func moveDate(by days: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }
        selectedDate = newDate
    }
}

private struct AttendanceRow: View {
    let athlete: Athlete
    let status: AttendanceStatus
    let locked: Bool
    let update: (AttendanceStatus) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                identity
                attendancePicker
                    .frame(width: 390)
            }

            VStack(alignment: .leading, spacing: 12) {
                identity
                attendancePicker
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 5)
    }

    private var identity: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(CorsoTheme.navy.opacity(0.09))
                Text(athlete.name.prefix(1))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CorsoTheme.navy)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.name).font(.headline)
                Text("Year \(athlete.year) · \(athlete.className) · \(athlete.faction)")
                    .font(.caption)
                    .foregroundStyle(CorsoTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attendancePicker: some View {
        Picker("Attendance for \(athlete.name)", selection: Binding(get: { status }, set: update)) {
            Text("Clear").tag(AttendanceStatus.unmarked)
            Text("Present").tag(AttendanceStatus.present)
            Text("Late").tag(AttendanceStatus.late)
            Text("Absent").tag(AttendanceStatus.absent)
        }
        .pickerStyle(.segmented)
        .disabled(locked)
    }
}
