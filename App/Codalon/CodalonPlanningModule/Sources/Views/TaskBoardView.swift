// Issues #36, #66 — Task kanban board

import SwiftUI
import HelaiaDesign

// MARK: - TaskBoardView

struct TaskBoardView: View {

    // MARK: - Properties

    let viewModel: TaskViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: CodalonSpacing.zoneGap) {
                ForEach(boardColumns, id: \.self) { status in
                    boardColumn(for: status)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Column

    @ViewBuilder
    private func boardColumn(for status: CodalonTaskStatus) -> some View {
        let tasks = viewModel.tasksByStatus[status] ?? []

        VStack(alignment: .leading, spacing: Spacing._3) {
            HStack(spacing: Spacing._2) {
                Circle()
                    .fill(columnColor(for: status))
                    .frame(width: 8, height: 8)
                Text(status.displayLabel)
                    .helaiaFont(.subheadline)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                Spacer()
            }

            if tasks.isEmpty {
                HelaiaCard(variant: .outlined) {
                    Text("No tasks")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                ForEach(tasks) { task in
                    HelaiaKanbanCard(
                        title: task.title,
                        subtitle: task.summary.isEmpty ? nil : task.summary,
                        priority: task.priority.helaiaDesignPriority,
                        status: task.status.helaiaDesignStatus,
                        tags: taskTags(task),
                        dueDate: task.dueDate,
                        isSelected: viewModel.selectedTaskIDs.contains(task.id)
                    ) {
                        viewModel.toggleSelection(taskID: task.id)
                    }
                }
            }
        }
        .frame(width: 280)
    }

    // MARK: - Helpers

    private var boardColumns: [CodalonTaskStatus] {
        [.backlog, .todo, .inProgress, .inReview, .done]
    }

    private func columnColor(for status: CodalonTaskStatus) -> Color {
        switch status {
        case .backlog: SemanticColor.textTertiary(for: colorScheme)
        case .todo: SemanticColor.info(for: colorScheme)
        case .inProgress: SemanticColor.warning(for: colorScheme)
        case .inReview: SemanticColor.info(for: colorScheme)
        case .done: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private func taskTags(_ task: CodalonTask) -> [String] {
        var tags: [String] = []
        if task.isBlocked { tags.append("Blocked") }
        if task.isLaunchCritical { tags.append("Launch") }
        if task.waitingExternal { tags.append("Waiting") }
        if let e = task.estimate { tags.append("\(String(format: "%.0f", e))h") }
        return tags
    }
}

// MARK: - Mapping Helpers

extension CodalonPriority {
    nonisolated var helaiaDesignPriority: HelaiaTaskPriority {
        switch self {
        case .low: .low
        case .medium: .medium
        case .high: .high
        case .critical: .critical
        }
    }
}

extension CodalonTaskStatus {
    nonisolated var helaiaDesignStatus: HelaiaTaskStatus {
        switch self {
        case .backlog, .todo: .todo
        case .inProgress: .inProgress
        case .inReview: .review
        case .done: .done
        case .cancelled: .blocked
        }
    }
}

// MARK: - Preview

#Preview("TaskBoardView") {
    TaskBoardView(viewModel: .preview)
}