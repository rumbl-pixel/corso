import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct StudentImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AthleticsStore.self) private var store

    private let availableClasses: [String]

    @State private var assignmentMode = ClassAssignmentMode.oneClass
    @State private var destinationMode: ClassDestinationMode
    @State private var selectedClass: String
    @State private var newClassName = ""
    @State private var defaultYear: Int
    @State private var isSelectingFile = false
    @State private var selectedFileName: String?
    @State private var rawCSV: String?
    @State private var parsedImport: StudentCSVImport?
    @State private var importError: String?
    @State private var completion: StudentImportCompletion?

    init(classes: [String]) {
        let classes = classes.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.caseInsensitiveCompare("Unassigned") != .orderedSame
        }
        availableClasses = classes

        let firstClass = classes.first ?? ""
        _destinationMode = State(initialValue: classes.isEmpty ? .newClass : .existing)
        _selectedClass = State(initialValue: firstClass)
        _defaultYear = State(initialValue: Self.inferredYear(from: firstClass) ?? 3)
    }

    private var destinationClass: String? {
        guard assignmentMode == .oneClass else { return nil }
        let value = destinationMode == .existing ? selectedClass : newClassName
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private var importOptions: StudentCSVImportOptions {
        switch assignmentMode {
        case .oneClass:
            return StudentCSVImportOptions(
                destinationClass: destinationClass,
                defaultYear: defaultYear
            )
        case .classesFromFile:
            return StudentCSVImportOptions(requiresClassColumn: true)
        }
    }

    private var review: StudentImportReview? {
        guard let parsedImport else { return nil }
        return StudentImportReviewer.review(parsedImport.athletes, against: store.state.athletes)
    }

    private var canSelectFile: Bool {
        assignmentMode == .classesFromFile || destinationClass != nil
    }

    private var isStudentDataReady: Bool {
        store.state.settings.pilotReadiness.isStudentDataReady
    }

    var body: some View {
        NavigationStack {
            Group {
                if let completion {
                    StudentImportCompletionView(completion: completion)
                } else {
                    importForm
                }
            }
            .navigationTitle("Import students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(completion == nil ? "Cancel" : "Done") {
                        dismiss()
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isSelectingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false,
            onCompletion: loadSelectedFile
        )
        .interactiveDismissDisabled(completion == nil && rawCSV != nil)
        .onChange(of: assignmentMode) { _, _ in refreshPreview() }
        .onChange(of: destinationMode) { _, _ in refreshPreview() }
        .onChange(of: selectedClass) { _, value in
            if let year = Self.inferredYear(from: value) {
                defaultYear = year
            }
            refreshPreview()
        }
        .onChange(of: newClassName) { _, _ in refreshPreview() }
        .onChange(of: defaultYear) { _, _ in refreshPreview() }
        .frame(minWidth: 580, minHeight: 640)
    }

    private var importForm: some View {
        Form {
            Section {
                Picker("Class assignment", selection: $assignmentMode) {
                    ForEach(ClassAssignmentMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text(
                    assignmentMode == .oneClass
                        ? "Every student in the file will be placed into the class you choose."
                        : "Use this for a whole-school file. The CSV must include Name, Year and Class columns."
                )
            }

            if assignmentMode == .oneClass {
                destinationSection
            }

            Section {
                Button {
                    isSelectingFile = true
                } label: {
                    Label(
                        selectedFileName ?? "Choose CSV file",
                        systemImage: selectedFileName == nil ? "doc.badge.plus" : "doc.text.fill"
                    )
                }
                .disabled(!canSelectFile)

                if selectedFileName != nil {
                    Button("Remove selected file", role: .destructive) {
                        clearSelectedFile()
                    }
                }
            } header: {
                Text("Class list")
            } footer: {
                Text(fileFormatHelp)
            }

            if let importError {
                Section {
                    Label(importError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            if let parsedImport, let review {
                reviewSections(parsedImport: parsedImport, review: review)
            }
        }
        .scrollContentBackground(.hidden)
        .background(CorsoTheme.cream)
    }

    @ViewBuilder
    private var destinationSection: some View {
        Section {
            if !availableClasses.isEmpty {
                Picker("Class", selection: $destinationMode) {
                    ForEach(ClassDestinationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            if destinationMode == .existing, !availableClasses.isEmpty {
                Picker("Destination class", selection: $selectedClass) {
                    ForEach(availableClasses, id: \.self) { className in
                        Text(className).tag(className)
                    }
                }
            } else {
                TextField("Class name, e.g. 4A", text: $newClassName)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Picker("Default year group", selection: $defaultYear) {
                ForEach(1...6, id: \.self) { year in
                    Text("Year \(year)").tag(year)
                }
            }
        } header: {
            Text("Destination")
        } footer: {
            Text("A Year value in the CSV is used when present. The default fills blank Year cells or a file with no Year column.")
        }
    }

    @ViewBuilder
    private func reviewSections(
        parsedImport: StudentCSVImport,
        review: StudentImportReview
    ) -> some View {
        if !isStudentDataReady {
            Section {
                Label("Complete the two student-data checks in Settings before importing real students.", systemImage: "lock.shield")
                    .foregroundStyle(CorsoTheme.orangeDark)
            } footer: {
                Text("Confirm local pilot approval, a school-managed device and the approved recordkeeping process. You can still inspect this CSV without importing it.")
            }
        }

        Section("Review before importing") {
            LabeledContent("Ready to import", value: "\(review.studentsToImport.count)")
            LabeledContent("Duplicates skipped", value: "\(review.duplicates.count)")
            LabeledContent("Invalid rows skipped", value: "\(parsedImport.rejectedRows.count)")
            LabeledContent("Classes", value: "\(classCount(in: review.studentsToImport))")
        }

        if !review.studentsToImport.isEmpty {
            Section("Students to add") {
                ForEach(Array(review.studentsToImport.prefix(50))) { athlete in
                    StudentImportPreviewRow(athlete: athlete)
                }
                if review.studentsToImport.count > 50 {
                    Text("Plus \(review.studentsToImport.count - 50) more students")
                        .foregroundStyle(.secondary)
                }
            }
        }

        if !review.duplicates.isEmpty {
            Section {
                DisclosureGroup("Show duplicate students") {
                    ForEach(Array(review.duplicates.prefix(20))) { athlete in
                        StudentImportPreviewRow(athlete: athlete)
                    }
                    if review.duplicates.count > 20 {
                        Text("Plus \(review.duplicates.count - 20) more duplicates")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("A duplicate has the same name, year and class as an existing student or an earlier row in this file.")
            }
        }

        if !parsedImport.rejectedRows.isEmpty {
            Section {
                Text(parsedImport.rejectedRows.map(String.init).joined(separator: ", "))
                    .textSelection(.enabled)
            } header: {
                Text("Invalid CSV row numbers")
            } footer: {
                Text("These rows are missing a name, a valid Year 1–6 value or a required class.")
            }
        }

        Section {
            Button {
                confirmImport(parsedImport: parsedImport, review: review)
            } label: {
                Label(confirmButtonTitle(for: review), systemImage: "person.3.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CorsoTheme.orange)
            .disabled(review.studentsToImport.isEmpty || !isStudentDataReady)
        }
    }

    private var fileFormatHelp: String {
        switch assignmentMode {
        case .oneClass:
            return "Export the class list from Excel as CSV. Name is required. Year, Gender and Faction are optional."
        case .classesFromFile:
            return "Export from Excel as CSV with Name, Year and Class columns. Gender and Faction are optional."
        }
    }

    private func loadSelectedFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .utf16)
                ?? String(data: data, encoding: .isoLatin1)
            else {
                throw StudentImportFileError.unsupportedTextEncoding
            }

            selectedFileName = url.lastPathComponent
            rawCSV = text
            refreshPreview()
        } catch {
            parsedImport = nil
            importError = error.localizedDescription
        }
    }

    private func refreshPreview() {
        guard let rawCSV else {
            parsedImport = nil
            importError = nil
            return
        }
        guard canSelectFile else {
            parsedImport = nil
            importError = "Choose or enter the destination class before reviewing this file."
            return
        }

        do {
            parsedImport = try StudentCSVImporter.parse(rawCSV, options: importOptions)
            importError = nil
        } catch {
            parsedImport = nil
            importError = error.localizedDescription
        }
    }

    private func clearSelectedFile() {
        selectedFileName = nil
        rawCSV = nil
        parsedImport = nil
        importError = nil
    }

    private func confirmImport(
        parsedImport: StudentCSVImport,
        review: StudentImportReview
    ) {
        let inserted = store.importAthletes(review.studentsToImport)
        let additionalDuplicates = max(review.studentsToImport.count - inserted, 0)
        let importedClassCount = inserted == 0 ? 0 : classCount(in: review.studentsToImport)

        completion = StudentImportCompletion(
            inserted: inserted,
            duplicateCount: review.duplicates.count + additionalDuplicates,
            rejectedRowCount: parsedImport.rejectedRows.count,
            classCount: importedClassCount
        )
    }

    private func confirmButtonTitle(for review: StudentImportReview) -> String {
        let count = review.studentsToImport.count
        if assignmentMode == .oneClass, let destinationClass {
            return "Import \(count) into \(destinationClass)"
        }
        return "Import \(count) students"
    }

    private func classCount(in athletes: [Athlete]) -> Int {
        Set(athletes.map { $0.className.lowercased() }).count
    }

    private static func inferredYear(from className: String) -> Int? {
        className
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
            .first(where: { (1...6).contains($0) })
    }
}

private enum ClassAssignmentMode: String, CaseIterable, Identifiable {
    case oneClass = "One class"
    case classesFromFile = "Classes in CSV"

    var id: Self { self }
}

private enum ClassDestinationMode: String, CaseIterable, Identifiable {
    case existing = "Existing class"
    case newClass = "New class"

    var id: Self { self }
}

private enum StudentImportFileError: LocalizedError {
    case unsupportedTextEncoding

    var errorDescription: String? {
        "The selected file could not be read as a text CSV. Export it from Excel as CSV UTF-8 and try again."
    }
}

private struct StudentImportCompletion {
    let inserted: Int
    let duplicateCount: Int
    let rejectedRowCount: Int
    let classCount: Int
}

private struct StudentImportCompletionView: View {
    let completion: StudentImportCompletion

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(CorsoTheme.orange)

            Text("Import complete")
                .font(.largeTitle.weight(.black))

            Text("\(completion.inserted) \(studentLabel) added across \(completion.classCount) \(classLabel).")
                .font(.title3)
                .multilineTextAlignment(.center)

            if completion.duplicateCount > 0 || completion.rejectedRowCount > 0 {
                VStack(spacing: 8) {
                    if completion.duplicateCount > 0 {
                        Label(
                            "\(completion.duplicateCount) duplicate \(rowLabel(completion.duplicateCount)) skipped",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    if completion.rejectedRowCount > 0 {
                        Label(
                            "\(completion.rejectedRowCount) invalid \(rowLabel(completion.rejectedRowCount)) skipped",
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CorsoTheme.cream)
    }

    private var studentLabel: String {
        completion.inserted == 1 ? "student" : "students"
    }

    private var classLabel: String {
        completion.classCount == 1 ? "class" : "classes"
    }

    private func rowLabel(_ count: Int) -> String {
        count == 1 ? "row" : "rows"
    }
}

private struct StudentImportPreviewRow: View {
    let athlete: Athlete

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(athlete.name)
                    .font(.body.weight(.semibold))
                Text("Year \(athlete.year) · \(athlete.className)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if athlete.faction != "Unassigned" {
                Text(athlete.faction)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CorsoTheme.muted)
            }
        }
    }
}
