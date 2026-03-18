// Issues #72, #78, #80 — Decision log entry form

import SwiftUI
import HelaiaDesign

// MARK: - DecisionLogEntryForm

struct DecisionLogEntryForm: View {

    // MARK: - State

    @State private var title = ""
    @State private var note = ""
    @State private var category: CodalonDecisionCategory = .architecture
    @State private var selectedLinkID: UUID?

    // MARK: - Properties

    private let existingEntry: CodalonDecisionLogEntry?
    private let linkableItems: [DecisionLinkOption]
    private let onSave: (CodalonDecisionLogEntry) async -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.projectContext) private var context

    // MARK: - Init (Create)

    init(
        linkableItems: [DecisionLinkOption] = [],
        onSave: @escaping (CodalonDecisionLogEntry) async -> Void
    ) {
        self.existingEntry = nil
        self.linkableItems = linkableItems
        self.onSave = onSave
    }

    // MARK: - Init (Edit)

    init(
        entry: CodalonDecisionLogEntry,
        linkableItems: [DecisionLinkOption] = [],
        onSave: @escaping (CodalonDecisionLogEntry) async -> Void
    ) {
        self.existingEntry = entry
        self.linkableItems = linkableItems
        self.onSave = onSave
        self._title = State(initialValue: entry.title)
        self._note = State(initialValue: entry.note)
        self._category = State(initialValue: entry.category)
        self._selectedLinkID = State(initialValue: entry.relatedObjectID)
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
        .frame(width: 480, height: linkableItems.isEmpty ? 380 : 440)
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

                // Issue #78, #80 — Link to release, milestone, or epic
                if !linkableItems.isEmpty {
                    linkPicker
                }
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

    // MARK: - Link Picker (Issues #78, #80)

    @ViewBuilder
    private var linkPicker: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            Text("Link to")
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)

            Picker("", selection: $selectedLinkID) {
                Text("None").tag(UUID?.none)

                ForEach(DecisionLinkType.allCases, id: \.self) { type in
                    let items = linkableItems.filter { $0.type == type }
                    if !items.isEmpty {
                        Section(type.label) {
                            ForEach(items) { item in
                                Text(item.title).tag(Optional(item.id))
                            }
                        }
                    }
                }
            }
            .labelsHidden()
        }
    }

    // MARK: - Save

    private func saveEntry() async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let projectID = existingEntry?.projectID ?? UUID()

        if var existing = existingEntry {
            existing.title = title
            existing.note = note
            existing.category = category
            existing.relatedObjectID = selectedLinkID
            await onSave(existing)
        } else {
            let entry = CodalonDecisionLogEntry(
                projectID: projectID,
                relatedObjectID: selectedLinkID,
                category: category,
                title: title,
                note: note
            )
            await onSave(entry)
        }
        dismiss()
    }
}

// MARK: - DecisionLinkOption

struct DecisionLinkOption: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let type: DecisionLinkType
}

// MARK: - DecisionLinkType

enum DecisionLinkType: String, CaseIterable, Sendable {
    case release
    case milestone
    case epic

    var label: String {
        switch self {
        case .release: "Releases"
        case .milestone: "Milestones"
        case .epic: "Epics"
        }
    }
}

// MARK: - Preview

#Preview("DecisionLogEntryForm — Create") {
    DecisionLogEntryForm { _ in }
}

#Preview("DecisionLogEntryForm — With Links") {
    DecisionLogEntryForm(
        linkableItems: [
            DecisionLinkOption(id: UUID(), title: "v1.0 Beta", type: .release),
            DecisionLinkOption(id: UUID(), title: "MVP Launch", type: .milestone),
            DecisionLinkOption(id: UUID(), title: "Dashboard Epic", type: .epic),
        ],
        onSave: { _ in }
    )
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
