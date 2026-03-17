// Issue #31 — Horizontal timeline showing milestones by due date

import SwiftUI
import HelaiaDesign

// MARK: - RoadmapTimelineView

struct RoadmapTimelineView: View {

    // MARK: - Properties

    let viewModel: PlanningViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        if timelineMilestones.isEmpty {
            HelaiaEmptyState(
                icon: "chart.bar.xaxis",
                title: "No milestones with due dates",
                description: "Add due dates to your milestones to see them on the timeline"
            )
        } else {
            ScrollView(.horizontal) {
                timelineContent
                    .padding(Spacing._8)
            }
        }
    }

    // MARK: - Timeline Content

    @ViewBuilder
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            monthHeaders
            timelineAxis
            milestoneRows
        }
    }

    // MARK: - Month Headers

    @ViewBuilder
    private var monthHeaders: some View {
        HStack(spacing: 0) {
            ForEach(months, id: \.self) { month in
                Text(month.formatted(.dateTime.month(.abbreviated).year()))
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textTertiary)
                    .frame(width: monthWidth)
            }
        }
        .padding(.leading, labelWidth)
    }

    // MARK: - Axis

    @ViewBuilder
    private var timelineAxis: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelWidth, height: 1)
            ForEach(months, id: \.self) { month in
                Rectangle()
                    .fill(SemanticColor.border(for: colorScheme))
                    .frame(width: monthWidth, height: 1)
            }
        }
        .padding(.vertical, Spacing._2)
    }

    // MARK: - Milestone Rows

    @ViewBuilder
    private var milestoneRows: some View {
        ForEach(timelineMilestones, id: \.id) { milestone in
            milestoneRow(milestone)
        }
    }

    @ViewBuilder
    private func milestoneRow(_ milestone: CodalonMilestone) -> some View {
        let offset = offsetForDate(milestone.dueDate ?? Date())
        let isOverdue = (milestone.dueDate ?? .distantFuture) < Date()
            && milestone.status != .completed
            && milestone.status != .cancelled

        HStack(spacing: 0) {
            Text(milestone.title)
                .helaiaFont(.caption1)
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .trailing)
                .padding(.trailing, Spacing._2)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(SemanticColor.border(for: colorScheme).opacity(0.3))
                    .frame(height: 1)
                    .frame(width: totalTimelineWidth)

                timelineMarker(milestone, isOverdue: isOverdue)
                    .offset(x: offset)
            }
        }
        .frame(height: 36)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(milestone.title), due \(milestone.dueDate?.formatted(.dateTime.month().day()) ?? "no date")"
                + (isOverdue ? ", overdue" : "")
        )
    }

    @ViewBuilder
    private func timelineMarker(
        _ milestone: CodalonMilestone,
        isOverdue: Bool
    ) -> some View {
        let color = isOverdue
            ? SemanticColor.error(for: colorScheme)
            : statusColor(milestone.status)

        HStack(spacing: Spacing._1) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            HelaiaProgressBar(
                value: milestone.progress,
                height: .thin
            )
            .frame(width: 60)
        }
    }

    // MARK: - Computed

    private var timelineMilestones: [CodalonMilestone] {
        viewModel.filteredMilestones
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var months: [Date] {
        guard let earliest = timelineMilestones.compactMap(\.dueDate).min(),
              let latest = timelineMilestones.compactMap(\.dueDate).max()
        else { return [] }

        let calendar = Calendar.current
        let startMonth = calendar.dateInterval(of: .month, for: earliest)?.start ?? earliest
        let endMonth = calendar.date(byAdding: .month, value: 1, to: latest) ?? latest

        var result: [Date] = []
        var current = startMonth
        while current <= endMonth {
            result.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? endMonth
        }
        return result
    }

    private var labelWidth: CGFloat { 140 }
    private var monthWidth: CGFloat { 120 }
    private var totalTimelineWidth: CGFloat { CGFloat(months.count) * monthWidth }

    private func offsetForDate(_ date: Date) -> CGFloat {
        guard let firstMonth = months.first else { return 0 }
        let interval = date.timeIntervalSince(firstMonth)
        let totalInterval = TimeInterval(months.count) * 30 * 24 * 3600
        guard totalInterval > 0 else { return 0 }
        return CGFloat(interval / totalInterval) * totalTimelineWidth
    }

    private func statusColor(_ status: CodalonMilestoneStatus) -> Color {
        switch status {
        case .planned: SemanticColor.textSecondary(for: colorScheme)
        case .active: SemanticColor.info(for: colorScheme)
        case .completed: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("RoadmapTimelineView") {
    RoadmapTimelineView(viewModel: .preview)
        .frame(width: 1000, height: 400)
}
