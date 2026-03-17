// Issue #25 — Milestone create/edit form

import SwiftUI
import HelaiaDesign

// MARK: - MilestoneFormView

struct MilestoneFormView: View {

    // MARK: - State

    @State private var title = ""
    @State private var summary = ""
    @State private var dueDate: Date = Calendar.current.date(
        byAdding: .weekOfYear,
        value: 2,
        to: .now
    ) ?? .now
    @State private var hasDueDate = false
    @State private var status: CodalonMilestoneStatus = .planned
    @State private var priority: CodalonPriority = .medium

    // MARK: - Properties

    private let existingMilestone: CodalonMilestone?
    private let onSave: (CodalonMilestone) async -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.projectContext) private var context

    // MARK: - Init (Create)

    init(onSave: @escaping (CodalonMilestone) async -> Void) {
        self.existingMilestone = nil
        self.onSave = onSave
    }

    // MARK: - Init (Edit)

    init(
        milestone: CodalonMilestone,
        onSave: @escaping (CodalonMilestone) async -> Void
    ) {
        self.existingMilestone = milestone
        self.onSave = onSave
        self._title = State(initialValue: milestone.title)
        self._summary = State(initialValue: milestone.summary)
        self._status = State(initialValue: milestone.status)
        self._priority = State(initialValue: milestone.priority)
        if let date = milestone.dueDate {
            self._dueDate = State(initialValue: date)
            self._hasDueDate = State(initialValue: true)
        }
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
        .frame(width: 480, height: 420)
    }

    // MARK: - Header

    @ViewBuilder
    private var formHeader: some View {
        HStack {
            Text(existingMilestone != nil ? "Edit Milestone" : "New Milestone")
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
                    placeholder: "Milestone title"
                )
                HelaiaTextField(
                    title: "Summary",
                    text: $summary,
                    placeholder: "Brief description"
                )
                HelaiaDropdownPicker(
                    selection: $status,
                    options: CodalonMilestoneStatus.allCases.map {
                        HelaiaPickerOption(id: $0, label: $0.displayLabel)
                    },
                    label: "Status"
                )
                HelaiaDropdownPicker(
                    selection: $priority,
                    options: CodalonPriority.allCases.map {
                        HelaiaPickerOption(id: $0, label: $0.rawValue.capitalized)
                    },
                    label: "Priority"
                )
                VStack(alignment: .leading, spacing: Spacing._2) {
                    HelaiaToggle(
                        isOn: $hasDueDate,
                        label: "Due Date"
                    )
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var formFooter: some View {
        HStack {
            HelaiaButton.ghost("Cancel") {
                dismiss()
            }
            Spacer()
            HelaiaButton(
                existingMilestone != nil ? "Save" : "Create",
                icon: nil
            ) {
                Task { await saveMilestone() }
            }
            .fixedSize()
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Save

    private func saveMilestone() async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Use a fixed projectID for now — will be resolved via context/DI
        let projectID = UUID()

        if var existing = existingMilestone {
            existing.title = title
            existing.summary = summary
            existing.status = status
            existing.priority = priority
            existing.dueDate = hasDueDate ? dueDate : nil
            await onSave(existing)
        } else {
            let milestone = CodalonMilestone(
                projectID: projectID,
                title: title,
                summary: summary,
                dueDate: hasDueDate ? dueDate : nil,
                status: status,
                priority: priority
            )
            await onSave(milestone)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("MilestoneFormView — Create") {
    MilestoneFormView { _ in }
}

#Preview("MilestoneFormView — Edit") {
    MilestoneFormView(milestone: .previewActive) { _ in }
}
