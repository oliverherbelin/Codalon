// Issue #32 — Filters and sorting

import SwiftUI
import HelaiaDesign

// MARK: - PlanningFilterBar

struct PlanningFilterBar: View {

    // MARK: - Bindings

    @Binding var statusFilter: CodalonMilestoneStatus?
    @Binding var priorityFilter: CodalonPriority?
    @Binding var sortMode: PlanningViewModel.SortMode

    // MARK: - State

    @State private var statusSelection: PlanningStatusOption = .all
    @State private var prioritySelection: PlanningPriorityOption = .all

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing._2) {
            HelaiaDropdownPicker(
                selection: $statusSelection,
                options: PlanningStatusOption.allOptions,
                label: "Status"
            )
            .frame(width: 140)
            .onChange(of: statusSelection) { _, newValue in
                statusFilter = newValue.status
            }

            HelaiaDropdownPicker(
                selection: $prioritySelection,
                options: PlanningPriorityOption.allOptions,
                label: "Priority"
            )
            .frame(width: 140)
            .onChange(of: prioritySelection) { _, newValue in
                priorityFilter = newValue.priority
            }

            HelaiaDropdownPicker(
                selection: $sortMode,
                options: PlanningViewModel.SortMode.allCases.map {
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

// MARK: - PlanningStatusOption

enum PlanningStatusOption: String, Hashable, Sendable, CaseIterable {
    case all
    case planned
    case active
    case completed
    case cancelled

    nonisolated var status: CodalonMilestoneStatus? {
        switch self {
        case .all: nil
        case .planned: .planned
        case .active: .active
        case .completed: .completed
        case .cancelled: .cancelled
        }
    }

    nonisolated static var allOptions: [HelaiaPickerOption<PlanningStatusOption>] {
        [HelaiaPickerOption(id: .all, label: "All Statuses")]
            + CodalonMilestoneStatus.allCases.map {
                HelaiaPickerOption(id: PlanningStatusOption(from: $0), label: $0.displayLabel)
            }
    }

    nonisolated init(from status: CodalonMilestoneStatus) {
        switch status {
        case .planned: self = .planned
        case .active: self = .active
        case .completed: self = .completed
        case .cancelled: self = .cancelled
        }
    }
}

// MARK: - PlanningPriorityOption

enum PlanningPriorityOption: String, Hashable, Sendable, CaseIterable {
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

    nonisolated static var allOptions: [HelaiaPickerOption<PlanningPriorityOption>] {
        [HelaiaPickerOption(id: .all, label: "All Priorities")]
            + CodalonPriority.allCases.map {
                HelaiaPickerOption(id: PlanningPriorityOption(from: $0), label: $0.rawValue.capitalized)
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

#Preview("PlanningFilterBar") {
    struct PreviewWrapper: View {
        @State private var status: CodalonMilestoneStatus? = nil
        @State private var priority: CodalonPriority? = nil
        @State private var sort: PlanningViewModel.SortMode = .dueDate

        var body: some View {
            PlanningFilterBar(
                statusFilter: $status,
                priorityFilter: $priority,
                sortMode: $sort
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
