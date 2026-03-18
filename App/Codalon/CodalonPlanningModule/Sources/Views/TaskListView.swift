// Issue #36 — Tasks list

import SwiftUI
import HelaiaDesign

// MARK: - TaskListView

struct TaskListView: View {

    // MARK: - State

    @State private var viewModel: TaskViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: TaskViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing._3) {
                if viewModel.filteredTasks.isEmpty {
                    HelaiaEmptyState(
                        icon: "checklist",
                        title: "No tasks yet",
                        description: "Create your first task to start tracking work"
                    )
                } else {
                    ForEach(CodalonTaskStatus.allCases, id: \.self) { status in
                        let tasksForStatus = viewModel.tasksByStatus[status] ?? []
                        if !tasksForStatus.isEmpty {
                            taskSection(status: status, tasks: tasksForStatus)
                        }
                    }
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func taskSection(status: CodalonTaskStatus, tasks: [CodalonTask]) -> some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._2) {
                Circle()
                    .fill(statusColor(status))
                    .frame(width: 8, height: 8)
                Text(status.displayLabel)
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                Spacer()
            }

            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    isSelected: viewModel.selectedTaskIDs.contains(task.id),
                    onTap: { viewModel.toggleSelection(taskID: task.id) },
                    onStatusChange: { status in
                        Task { await viewModel.changeStatus(taskID: task.id, to: status) }
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private func statusColor(_ status: CodalonTaskStatus) -> Color {
        switch status {
        case .backlog: SemanticColor.textTertiary(for: colorScheme)
        case .todo: SemanticColor.info(for: colorScheme)
        case .inProgress: SemanticColor.warning(for: colorScheme)
        case .inReview: SemanticColor.info(for: colorScheme)
        case .done: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("TaskListView") {
    TaskListView(viewModel: .preview)
}