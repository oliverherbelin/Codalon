// Issue #70 — Today/next/later execution view

import SwiftUI
import HelaiaDesign

// MARK: - TaskTimelineView

struct TaskTimelineView: View {

    // MARK: - Properties

    let viewModel: TaskViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
                timelineSection(
                    title: "Today",
                    icon: "sun.max.fill",
                    tasks: viewModel.todayTasks,
                    emptyMessage: "Nothing due today"
                )
                timelineSection(
                    title: "Next 7 Days",
                    icon: "calendar.badge.clock",
                    tasks: viewModel.nextTasks,
                    emptyMessage: "Nothing upcoming this week"
                )
                timelineSection(
                    title: "Later",
                    icon: "clock",
                    tasks: viewModel.laterTasks,
                    emptyMessage: "No future tasks"
                )

                if !viewModel.overdueTasks.isEmpty {
                    timelineSection(
                        title: "Overdue",
                        icon: "exclamationmark.triangle.fill",
                        tasks: viewModel.overdueTasks,
                        emptyMessage: ""
                    )
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func timelineSection(
        title: String,
        icon: String,
        tasks: [CodalonTask],
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            HStack(spacing: Spacing._2) {
                HelaiaIconView(icon, size: .md, color: SemanticColor.textSecondary(for: colorScheme))
                Text(title)
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }

            if tasks.isEmpty {
                Text(emptyMessage)
                    .helaiaFont(.footnote)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .padding(.leading, Spacing._8)
            } else {
                ForEach(tasks) { task in
                    TaskRowView(
                        task: task,
                        isSelected: viewModel.selectedTaskIDs.contains(task.id),
                        onTap: { viewModel.toggleSelection(taskID: task.id) },
                        onStatusChange: { _ in }
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("TaskTimelineView") {
    TaskTimelineView(viewModel: .preview)
}