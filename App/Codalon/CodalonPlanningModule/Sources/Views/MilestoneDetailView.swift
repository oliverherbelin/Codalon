// Issue #24 — Milestone detail view

import SwiftUI
import HelaiaDesign

// MARK: - MilestoneDetailView

struct MilestoneDetailView: View {

    // MARK: - Properties

    let milestone: CodalonMilestone
    let tasks: [CodalonTask]

    // MARK: - State

    @State private var tasksExpanded = true
    @State private var detailsExpanded = true

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
                header
                progressSection
                detailsSection
                tasksSection
            }
            .padding(Spacing._8)
        }
        .frame(minWidth: 500, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing._2) {
            HStack(spacing: Spacing._3) {
                Text(milestone.title)
                    .helaiaFont(.title2)
                statusBadge
                Spacer()
                priorityBadge
            }
            if !milestone.summary.isEmpty {
                Text(milestone.summary)
                    .helaiaFont(.body)
                    .helaiaForeground(.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let color = statusColor(milestone.status)
        Text(milestone.status.displayLabel)
            .helaiaFont(.tag)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._0_5)
            .background {
                Capsule().fill(color.opacity(Opacity.faint))
            }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        let color = priorityColor(milestone.priority)
        HStack(spacing: Spacing._1) {
            HelaiaIconView(
                priorityIcon(milestone.priority),
                size: .xs,
                color: color
            )
            Text(milestone.priority.rawValue.capitalized)
                .helaiaFont(.tag)
                .foregroundStyle(color)
        }
    }

    // MARK: - Progress

    @ViewBuilder
    private var progressSection: some View {
        HelaiaCard(variant: .filled, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack {
                    Text("Progress")
                        .helaiaFont(.headline)
                    Spacer()
                    Text("\(Int(milestone.progress * 100))%")
                        .helaiaFont(.headline)
                        .codalonMonospaced()
                }
                HelaiaProgressBar(value: milestone.progress, height: .regular)
                HStack {
                    let completedCount = tasks.filter { $0.status == .done }.count
                    Text("\(completedCount) of \(tasks.count) tasks completed")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var detailsSection: some View {
        HelaiaExpandableSection(
            title: "Details",
            isExpanded: $detailsExpanded,
            icon: "info.circle"
        ) {
            VStack(spacing: Spacing._3) {
                detailRow(label: "Status", value: milestone.status.displayLabel)
                detailRow(
                    label: "Priority",
                    value: milestone.priority.rawValue.capitalized
                )
                if let dueDate = milestone.dueDate {
                    detailRow(
                        label: "Due Date",
                        value: dueDate.formatted(.dateTime.month().day().year())
                    )
                    if dueDate < Date()
                        && milestone.status != .completed
                        && milestone.status != .cancelled {
                        HStack(spacing: Spacing._1) {
                            HelaiaIconView(
                                "exclamationmark.triangle.fill",
                                size: .xs,
                                color: SemanticColor.error(for: colorScheme)
                            )
                            Text("Overdue")
                                .helaiaFont(.caption1)
                                .foregroundStyle(SemanticColor.error(for: colorScheme))
                        }
                    }
                }
                detailRow(
                    label: "Created",
                    value: milestone.createdAt.formatted(.dateTime.month().day().year())
                )
            }
            .padding(.leading, Spacing._6)
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .helaiaFont(.subheadline)
                .helaiaForeground(.textSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .helaiaFont(.subheadline)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tasks

    @ViewBuilder
    private var tasksSection: some View {
        HelaiaExpandableSection(
            title: "Tasks",
            isExpanded: $tasksExpanded,
            icon: "checklist",
            badge: "\(tasks.count)"
        ) {
            if tasks.isEmpty {
                Text("No tasks linked to this milestone")
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textTertiary)
                    .padding(.leading, Spacing._6)
            } else {
                VStack(spacing: Spacing._1) {
                    ForEach(tasks, id: \.id) { task in
                        taskDetailRow(task)
                    }
                }
                .padding(.leading, Spacing._6)
            }
        }
    }

    @ViewBuilder
    private func taskDetailRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._2) {
            Circle()
                .fill(taskStatusColor(task.status))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(task.title)
                .helaiaFont(.subheadline)
                .lineLimit(1)
            Spacer()
            if task.isBlocked {
                HelaiaIconView(
                    "exclamationmark.triangle.fill",
                    size: .xs,
                    color: SemanticColor.error(for: colorScheme)
                )
                .accessibilityLabel("Blocked")
            }
            Text(task.status.displayLabel)
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(task.title), \(task.status.displayLabel)"
                + (task.isBlocked ? ", blocked" : "")
        )
    }

    // MARK: - Helpers

    private func statusColor(_ status: CodalonMilestoneStatus) -> Color {
        switch status {
        case .planned: SemanticColor.textSecondary(for: colorScheme)
        case .active: SemanticColor.info(for: colorScheme)
        case .completed: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .low: SemanticColor.success(for: colorScheme)
        case .medium: SemanticColor.warning(for: colorScheme)
        case .high, .critical: SemanticColor.error(for: colorScheme)
        }
    }

    private func priorityIcon(_ priority: CodalonPriority) -> String {
        switch priority {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        case .critical: "exclamationmark.2"
        }
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

// MARK: - Preview

#Preview("MilestoneDetailView") {
    MilestoneDetailView(
        milestone: .previewActive,
        tasks: CodalonTask.previewList
    )
}
