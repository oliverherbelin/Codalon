// Issue #36 — Task filter bar

import SwiftUI
import HelaiaDesign

// MARK: - TaskFilterBar

struct TaskFilterBar: View {

    // MARK: - Bindings

    @Binding var statusFilter: CodalonTaskStatus?
    @Binding var priorityFilter: CodalonPriority?
    @Binding var sortMode: TaskSortMode

    // MARK: - State

    @State private var statusSelection: TaskStatusOption = .all
    @State private var prioritySelection: TaskPriorityOption = .all

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing._2) {
            HelaiaDropdownPicker(
                selection: $statusSelection,
                options: TaskStatusOption.allOptions,
                label: "Status"
            )
            .frame(width: 140)
            .onChange(of: statusSelection) { _, newValue in
                statusFilter = newValue.status
            }

            HelaiaDropdownPicker(
                selection: $prioritySelection,
                options: TaskPriorityOption.allOptions,
                label: "Priority"
            )
            .frame(width: 140)
            .onChange(of: prioritySelection) { _, newValue in
                priorityFilter = newValue.priority
            }

            HelaiaDropdownPicker(
                selection: $sortMode,
                options: TaskSortMode.allCases.map {
                    HelaiaPickerOption(id: $0, label: $0.label)
                },
                label: "Sort"
            )
            .frame(width: 130)

            if hasActiveFilters {
                HelaiaButton.ghost("Clear") {
                    statusSelection = .all
                    prioritySelection = .all
                    statusFilter = nil
                    priorityFilter = nil
                }
                .fixedSize()
            }
        }
    }

    // MARK: - Helpers

    private var hasActiveFilters: Bool {
        statusFilter != nil || priorityFilter != nil
    }
}

// MARK: - TaskStatusOption

enum TaskStatusOption: String, Hashable, Sendable, CaseIterable {
    case all
    case backlog
    case todo
    case inProgress
    case inReview
    case done
    case cancelled

    nonisolated var status: CodalonTaskStatus? {
        switch self {
        case .all: nil
        case .backlog: .backlog
        case .todo: .todo
        case .inProgress: .inProgress
        case .inReview: .inReview
        case .done: .done
        case .cancelled: .cancelled
        }
    }

    nonisolated static var allOptions: [HelaiaPickerOption<TaskStatusOption>] {
        [HelaiaPickerOption(id: .all, label: "All Statuses")]
            + CodalonTaskStatus.allCases.map {
                HelaiaPickerOption(id: TaskStatusOption(from: $0), label: $0.displayLabel)
            }
    }

    nonisolated init(from status: CodalonTaskStatus) {
        switch status {
        case .backlog: self = .backlog
        case .todo: self = .todo
        case .inProgress: self = .inProgress
        case .inReview: self = .inReview
        case .done: self = .done
        case .cancelled: self = .cancelled
        }
    }
}

// MARK: - TaskPriorityOption

enum TaskPriorityOption: String, Hashable, Sendable, CaseIterable {
    case all
    case low
    case medium
    case high
    case critical

    nonisolated var priority: CodalonPriority? {
        switch self {
        case .all: nil
        case .low: .low
        case .medium: .medium
        case .high: .high
        case .critical: .critical
        }
    }

    nonisolated static var allOptions: [HelaiaPickerOption<TaskPriorityOption>] {
        [HelaiaPickerOption(id: .all, label: "All Priorities")]
            + CodalonPriority.allCases.map {
                HelaiaPickerOption(id: TaskPriorityOption(from: $0), label: $0.rawValue.capitalized)
            }
    }

    nonisolated init(from priority: CodalonPriority) {
        switch priority {
        case .low: self = .low
        case .medium: self = .medium
        case .high: self = .high
        case .critical: self = .critical
        }
    }
}

// MARK: - Preview

#Preview("TaskFilterBar") {
    struct PreviewWrapper: View {
        @State private var status: CodalonTaskStatus? = nil
        @State private var priority: CodalonPriority? = nil
        @State private var sort: TaskSortMode = .priority

        var body: some View {
            TaskFilterBar(
                statusFilter: $status,
                priorityFilter: $priority,
                sortMode: $sort
            )
            .padding()
        }
    }

    return PreviewWrapper()
}