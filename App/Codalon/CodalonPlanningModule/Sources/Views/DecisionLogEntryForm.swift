// Issue #72 — Decision log entry form

import SwiftUI
import HelaiaDesign

// MARK: - DecisionLogEntryForm

struct DecisionLogEntryForm: View {

    // MARK: - State

    @State private var title = ""
    @State private var note = ""
    @State private var category: CodalonDecisionCategory = .architecture

    // MARK: - Properties

    private let existingEntry: CodalonDecisionLogEntry?
    private let onSave: (CodalonDecisionLogEntry) async -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.projectContext) private var context

    // MARK: - Init (Create)

    init(onSave: @escaping (CodalonDecisionLogEntry) async -> Void) {
        self.existingEntry = nil
        self.onSave = onSave
    }

    // MARK: - Init (Edit)

    init(
        entry: CodalonDecisionLogEntry,
        onSave: @escaping (CodalonDecisionLogEntry) async -> Void
    ) {
        self.existingEntry = entry
        self.onSave = onSave
        self._title = State(initialValue: entry.title)
        self._note = State(initialValue: entry.note)
        self._category = State(initialValue: entry.category)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            formHeader
            Divider()
            formContent
            Divider()
            formFooter
        }
        .frame(width: 480, height: 380)
    }

    // MARK: - Header

    @ViewBuilder
    private var formHeader: some View {
        HStack {
            Text(existingEntry != nil ? "Edit Decision" : "Log Decision")
                .helaiaFont(.headline)
            Spacer()
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Content

    @ViewBuilder
    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
                HelaiaTextField(
                    title: "Title",
                    text: $title,
                    placeholder: "What was decided?"
                )

                HelaiaTextField(
                    title: "Notes",
                    text: $note,
                    placeholder: "Why and context…"
                )

                HelaiaDropdownPicker(
                    selection: $category,
                    options: CodalonDecisionCategory.allCases.map {
                        HelaiaPickerOption(id: $0, label: $0.rawValue.capitalized)
                    },
                    label: "Category"
                )
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var formFooter: some View {
        HStack {
            HelaiaButton.ghost("Cancel") { dismiss() }
            Spacer()
            HelaiaButton(
                existingEntry != nil ? "Save" : "Log",
                icon: nil
            ) {
                Task { await saveEntry() }
            }
            .fixedSize()
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Save

    private func saveEntry() async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let projectID = existingEntry?.projectID ?? UUID()

        if var existing = existingEntry {
            existing.title = title
            existing.note = note
            existing.category = category
            await onSave(existing)
        } else {
            let entry = CodalonDecisionLogEntry(
                projectID: projectID,
                category: category,
                title: title,
                note: note
            )
            await onSave(entry)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("DecisionLogEntryForm — Create") {
    DecisionLogEntryForm { _ in }
}

#Preview("DecisionLogEntryForm — Edit") {
    DecisionLogEntryForm(
        entry: CodalonDecisionLogEntry(
            projectID: UUID(),
            category: .architecture,
            title: "Use actor-based services",
            note: "Thread safety via Swift actors"
        ),
        onSave: { _ in }
    )
}
