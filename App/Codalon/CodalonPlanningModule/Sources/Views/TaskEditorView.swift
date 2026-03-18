// Issue #40 — Task create/edit editor

import SwiftUI
import HelaiaDesign

// MARK: - TaskEditorView

struct TaskEditorView: View {

    // MARK: - State

    @State private var title = ""
    @State private var summary = ""
    @State private var status: CodalonTaskStatus = .backlog
    @State private var priority: CodalonPriority = .medium
    @State private var estimate: String = ""
    @State private var hasDueDate = false
    @State private var dueDate: Date = Calendar.current.date(
        byAdding: .weekOfYear, value: 1, to: .now
    ) ?? .now
    @State private var isBlocked = false
    @State private var isLaunchCritical = false
    @State private var waitingExternal = false
    @State private var githubIssueRef = ""

    // MARK: - Properties

    private let existingTask: CodalonTask?
    private let onSave: (CodalonTask) async -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.projectContext) private var context

    // MARK: - Init (Create)

    init(onSave: @escaping (CodalonTask) async -> Void) {
        self.existingTask = nil
        self.onSave = onSave
    }

    // MARK: - Init (Edit)

    init(task: CodalonTask, onSave: @escaping (CodalonTask) async -> Void) {
        self.existingTask = task
        self.onSave = onSave
        self._title = State(initialValue: task.title)
        self._summary = State(initialValue: task.summary)
        self._status = State(initialValue: task.status)
        self._priority = State(initialValue: task.priority)
        self._estimate = State(initialValue: task.estimate.map { String(format: "%.1f", $0) } ?? "")
        self._isBlocked = State(initialValue: task.isBlocked)
        self._isLaunchCritical = State(initialValue: task.isLaunchCritical)
        self._waitingExternal = State(initialValue: task.waitingExternal)
        self._githubIssueRef = State(initialValue: task.githubIssueRef ?? "")
        if let date = task.dueDate {
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
        .frame(width: 520, height: 560)
    }

    // MARK: - Header

    @ViewBuilder
    private var formHeader: some View {
        HStack {
            Text(existingTask != nil ? "Edit Task" : "New Task")
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
                    placeholder: "Task title"
                )
                HelaiaTextField(
                    title: "Summary",
                    text: $summary,
                    placeholder: "Brief description"
                )

                HStack(spacing: Spacing._4) {
                    HelaiaDropdownPicker(
                        selection: $status,
                        options: CodalonTaskStatus.allCases.map {
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
                }

                HelaiaTextField(
                    title: "Estimate (hours)",
                    text: $estimate,
                    placeholder: "e.g. 4.0"
                )

                VStack(alignment: .leading, spacing: Spacing._2) {
                    HelaiaToggle(isOn: $hasDueDate, label: "Due Date")
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }

                HelaiaTextField(
                    title: "GitHub Issue Ref",
                    text: $githubIssueRef,
                    placeholder: "#123"
                )

                VStack(alignment: .leading, spacing: Spacing._2) {
                    HelaiaToggle(isOn: $isBlocked, label: "Blocked")
                    HelaiaToggle(isOn: $isLaunchCritical, label: "Launch Critical")
                    HelaiaToggle(isOn: $waitingExternal, label: "Waiting External")
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
                existingTask != nil ? "Save" : "Create",
                icon: nil
            ) {
                Task { await saveTask() }
            }
            .fixedSize()
        }
        .padding(CodalonSpacing.cardPadding)
    }

    // MARK: - Save

    private func saveTask() async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let projectID = existingTask?.projectID ?? UUID()
        let parsedEstimate = Double(estimate)

        if var existing = existingTask {
            existing.title = title
            existing.summary = summary
            existing.status = status
            existing.priority = priority
            existing.estimate = parsedEstimate
            existing.dueDate = hasDueDate ? dueDate : nil
            existing.isBlocked = isBlocked
            existing.isLaunchCritical = isLaunchCritical
            existing.waitingExternal = waitingExternal
            existing.githubIssueRef = githubIssueRef.isEmpty ? nil : githubIssueRef
            await onSave(existing)
        } else {
            let task = CodalonTask(
                projectID: projectID,
                title: title,
                summary: summary,
                status: status,
                priority: priority,
                estimate: parsedEstimate,
                dueDate: hasDueDate ? dueDate : nil,
                isBlocked: isBlocked,
                isLaunchCritical: isLaunchCritical,
                waitingExternal: waitingExternal,
                githubIssueRef: githubIssueRef.isEmpty ? nil : githubIssueRef
            )
            await onSave(task)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("TaskEditorView — Create") {
    TaskEditorView { _ in }
}

#Preview("TaskEditorView — Edit") {
    TaskEditorView(
        task: CodalonTask(
            projectID: UUID(),
            title: "Existing Task",
            summary: "Some work",
            status: .inProgress,
            priority: .high,
            estimate: 4.0,
            dueDate: .now,
            isLaunchCritical: true
        ),
        onSave: { _ in }
    )
}