// Issue #30 — Kanban-style board grouping milestones by status

import SwiftUI
import HelaiaDesign

// MARK: - RoadmapBoardView

struct RoadmapBoardView: View {

    // MARK: - Properties

    let viewModel: PlanningViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: CodalonSpacing.zoneGap) {
                ForEach(boardColumns, id: \.self) { status in
                    boardColumn(status)
                }
            }
            .padding(Spacing._8)
        }
    }

    // MARK: - Columns

    private var boardColumns: [CodalonMilestoneStatus] {
        [.planned, .active, .completed, .cancelled]
    }

    @ViewBuilder
    private func boardColumn(_ status: CodalonMilestoneStatus) -> some View {
        let milestones = viewModel.milestonesByStatus[status] ?? []
        VStack(alignment: .leading, spacing: Spacing._3) {
            columnHeader(status, count: milestones.count)
            if milestones.isEmpty {
                emptyColumn(status)
            } else {
                ForEach(milestones, id: \.id) { milestone in
                    boardCard(milestone)
                }
            }
            Spacer()
        }
        .frame(width: 280)
    }

    // MARK: - Column Header

    @ViewBuilder
    private func columnHeader(
        _ status: CodalonMilestoneStatus,
        count: Int
    ) -> some View {
        HStack(spacing: Spacing._2) {
            Circle()
                .fill(columnColor(status))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(status.displayLabel)
                .helaiaFont(.headline)
            Text("\(count)")
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
            Spacer()
        }
        .padding(.bottom, Spacing._1)
    }

    private func columnColor(_ status: CodalonMilestoneStatus) -> Color {
        switch status {
        case .planned: SemanticColor.textSecondary(for: colorScheme)
        case .active: SemanticColor.info(for: colorScheme)
        case .completed: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    // MARK: - Empty Column

    @ViewBuilder
    private func emptyColumn(_ status: CodalonMilestoneStatus) -> some View {
        HelaiaCard(variant: .outlined, padding: false) {
            Text("No \(status.displayLabel.lowercased()) milestones")
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Board Card

    @ViewBuilder
    private func boardCard(_ milestone: CodalonMilestone) -> some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._2) {
                HStack(spacing: Spacing._2) {
                    priorityIcon(milestone.priority)
                    Text(milestone.title)
                        .helaiaFont(.buttonSmall)
                        .lineLimit(2)
                }
                if !milestone.summary.isEmpty {
                    Text(milestone.summary)
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                        .lineLimit(2)
                }
                HStack(spacing: Spacing._2) {
                    HelaiaProgressBar(
                        value: milestone.progress,
                        height: .thin
                    )
                    Text("\(Int(milestone.progress * 100))%")
                        .helaiaFont(.caption2)
                        .codalonMonospaced()
                        .helaiaForeground(.textTertiary)
                }
                if let dueDate = milestone.dueDate {
                    dueDateRow(dueDate, milestone: milestone)
                }
            }
            .padding(Spacing._3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel(milestone))
    }

    @ViewBuilder
    private func priorityIcon(_ priority: CodalonPriority) -> some View {
        let color: Color = switch priority {
        case .low: SemanticColor.success(for: colorScheme)
        case .medium: SemanticColor.warning(for: colorScheme)
        case .high, .critical: SemanticColor.error(for: colorScheme)
        }
        HelaiaIconView(
            priorityIconName(priority),
            size: .custom(10),
            weight: .semibold,
            color: color
        )
    }

    private func priorityIconName(_ priority: CodalonPriority) -> String {
        switch priority {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        case .critical: "exclamationmark.2"
        }
    }

    @ViewBuilder
    private func dueDateRow(_ date: Date, milestone: CodalonMilestone) -> some View {
        let isOverdue = date < Date() && milestone.status != .completed
            && milestone.status != .cancelled
        HStack(spacing: Spacing._1) {
            Image(systemName: "calendar")
                .font(.system(size: 10))
            Text(date, style: .date)
                .helaiaFont(.caption2)
        }
        .foregroundStyle(
            isOverdue
                ? SemanticColor.error(for: colorScheme)
                : SemanticColor.textTertiary(for: colorScheme)
        )
    }

    private func cardAccessibilityLabel(_ milestone: CodalonMilestone) -> String {
        var parts = [milestone.title]
        parts.append("Priority: \(milestone.priority.rawValue)")
        parts.append("Progress: \(Int(milestone.progress * 100)) percent")
        if let dueDate = milestone.dueDate {
            parts.append("Due: \(dueDate.formatted(.dateTime.month().day()))")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("RoadmapBoardView") {
    RoadmapBoardView(viewModel: .preview)
        .frame(width: 1200, height: 600)
}
