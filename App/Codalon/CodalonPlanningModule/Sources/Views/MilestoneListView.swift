// Issue #23 — Milestones list view

import SwiftUI
import HelaiaDesign

// MARK: - MilestoneListView

struct MilestoneListView: View {

    // MARK: - Properties

    let viewModel: PlanningViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: CodalonSpacing.zoneGap) {
                ForEach(viewModel.filteredMilestones, id: \.id) { milestone in
                    MilestoneRowView(
                        milestone: milestone,
                        tasks: viewModel.tasks[milestone.id] ?? []
                    )
                }
            }
            .padding(Spacing._8)
        }
    }
}

// MARK: - MilestoneRowView

struct MilestoneRowView: View {

    // MARK: - Properties

    let milestone: CodalonMilestone
    let tasks: [CodalonTask]

    // MARK: - State

    @State private var isExpanded = false
    @State private var showDetail = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                headerRow
                progressRow
                if isExpanded {
                    taskList
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
        .sheet(isPresented: $showDetail) {
            MilestoneDetailView(milestone: milestone, tasks: tasks)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: Spacing._3) {
            priorityIndicator
            VStack(alignment: .leading, spacing: Spacing._1) {
                Text(milestone.title)
                    .helaiaFont(.headline)
                if !milestone.summary.isEmpty {
                    Text(milestone.summary)
                        .helaiaFont(.subheadline)
                        .helaiaForeground(.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            statusBadge
            if let dueDate = milestone.dueDate {
                dueDateLabel(dueDate)
            }
            Button { showDetail = true } label: {
                HelaiaIconView(
                    "chevron.right",
                    size: .xs,
                    color: SemanticColor.textTertiary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View milestone details")
        }
    }

    // MARK: - Priority Indicator

    @ViewBuilder
    private var priorityIndicator: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(priorityColor)
            .frame(width: 4, height: 40)
            .accessibilityHidden(true)
    }

    private var priorityColor: Color {
        switch milestone.priority {
        case .low: SemanticColor.success(for: colorScheme)
        case .medium: SemanticColor.warning(for: colorScheme)
        case .high: SemanticColor.error(for: colorScheme)
        case .critical: SemanticColor.error(for: colorScheme)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        Text(milestone.status.displayLabel)
            .helaiaFont(.tag)
            .foregroundStyle(statusColor)
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._0_5)
            .background {
                Capsule().fill(statusColor.opacity(Opacity.faint))
            }
    }

    private var statusColor: Color {
        switch milestone.status {
        case .planned: SemanticColor.textSecondary(for: colorScheme)
        case .active: SemanticColor.info(for: colorScheme)
        case .completed: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    // MARK: - Due Date

    @ViewBuilder
    private func dueDateLabel(_ date: Date) -> some View {
        let isOverdue = date < Date() && milestone.status != .completed
            && milestone.status != .cancelled
        HStack(spacing: Spacing._1) {
            HelaiaIconView(
                "calendar",
                size: .xs,
                color: isOverdue
                    ? SemanticColor.error(for: colorScheme)
                    : SemanticColor.textTertiary(for: colorScheme)
            )
            Text(date, style: .date)
                .helaiaFont(.caption1)
                .foregroundStyle(
                    isOverdue
                        ? SemanticColor.error(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme)
                )
        }
    }

    // MARK: - Progress

    @ViewBuilder
    private var progressRow: some View {
        HStack(spacing: Spacing._3) {
            HelaiaProgressBar(
                value: milestone.progress,
                height: .thin
            )
            Text("\(Int(milestone.progress * 100))%")
                .helaiaFont(.caption1)
                .codalonMonospaced()
                .helaiaForeground(.textSecondary)
                .frame(width: 36, alignment: .trailing)
            Button {
                withAnimation(CodalonAnimation.cardInteraction) {
                    isExpanded.toggle()
                }
            } label: {
                HelaiaIconView(
                    "chevron.down",
                    size: .xs,
                    color: SemanticColor.textTertiary(for: colorScheme)
                )
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse tasks" : "Expand tasks")
        }
    }

    // MARK: - Task List

    @ViewBuilder
    private var taskList: some View {
        if tasks.isEmpty {
            Text("No tasks linked to this milestone")
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
                .padding(.leading, Spacing._4)
        } else {
            VStack(spacing: Spacing._1) {
                ForEach(tasks, id: \.id) { task in
                    taskRow(task)
                }
            }
        }
    }

    @ViewBuilder
    private func taskRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._2) {
            Circle()
                .fill(taskStatusColor(task.status))
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(task.title)
                .helaiaFont(.subheadline)
                .lineLimit(1)
            Spacer()
            Text(task.status.displayLabel)
                .helaiaFont(.caption2)
                .helaiaForeground(.textTertiary)
        }
        .padding(.vertical, Spacing._1)
        .padding(.horizontal, Spacing._4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.status.displayLabel)")
    }

    private func taskStatusColor(_ status: CodalonTaskStatus) -> Color {
        switch status {
        case .backlog, .todo: SemanticColor.textTertiary(for: colorScheme)
        case .inProgress: SemanticColor.info(for: colorScheme)
        case .inReview: SemanticColor.warning(for: colorScheme)
        case .done: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Display Labels

extension CodalonMilestoneStatus {

    nonisolated var displayLabel: String {
        switch self {
        case .planned: "Planned"
        case .active: "Active"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
}

extension CodalonTaskStatus {

    nonisolated var displayLabel: String {
        switch self {
        case .backlog: "Backlog"
        case .todo: "To Do"
        case .inProgress: "In Progress"
        case .inReview: "In Review"
        case .done: "Done"
        case .cancelled: "Cancelled"
        }
    }
}

// MARK: - Preview

#Preview("MilestoneListView") {
    MilestoneListView(viewModel: .preview)
        .frame(width: 800, height: 600)
}
