// Issue #82 — Weekly focus screen

import SwiftUI
import HelaiaDesign

// MARK: - WeeklyFocusScreen

struct WeeklyFocusScreen: View {

    // MARK: - State

    @State private var viewModel: WeeklyFocusViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(viewModel: WeeklyFocusViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: Spacing._3) {
            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text("This Week")
                    .helaiaFont(.title3)
                Text(weekRangeLabel)
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textSecondary)
            }

            Spacer()

            ReducedNoiseToggle(isEnabled: $viewModel.reducedNoiseEnabled)
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: CodalonSpacing.zoneGap) {
                    statsRow
                    milestoneSection
                    topTasksSection
                    decisionsSection
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        let tint = context.theme.color(for: colorScheme)

        HStack(spacing: CodalonSpacing.zoneGap) {
            statCard(
                label: "Completed",
                value: "\(viewModel.completedThisWeek)",
                color: SemanticColor.success(for: colorScheme)
            )
            statCard(
                label: "Overdue",
                value: "\(viewModel.overdueCount)",
                color: viewModel.overdueCount > 0
                    ? SemanticColor.error(for: colorScheme)
                    : SemanticColor.textSecondary(for: colorScheme)
            )
            statCard(
                label: "Blocked",
                value: "\(viewModel.blockedCount)",
                color: viewModel.blockedCount > 0
                    ? SemanticColor.warning(for: colorScheme)
                    : SemanticColor.textSecondary(for: colorScheme)
            )
        }
    }

    @ViewBuilder
    private func statCard(label: String, value: String, color: Color) -> some View {
        HelaiaCard(variant: .elevated) {
            VStack(spacing: Spacing._1) {
                Text(value)
                    .helaiaFont(.title2)
                    .foregroundStyle(color)
                Text(label)
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Milestone Section

    @ViewBuilder
    private var milestoneSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "flag.fill",
                        size: .sm,
                        color: SemanticColor.info(for: colorScheme)
                    )
                    Text("ACTIVE MILESTONE")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }

                if let milestone = viewModel.activeMilestone {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing._1) {
                            Text(milestone.title)
                                .helaiaFont(.headline)

                            if !milestone.summary.isEmpty {
                                Text(milestone.summary)
                                    .helaiaFont(.footnote)
                                    .helaiaForeground(.textSecondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        if let dueDate = milestone.dueDate {
                            dueDateLabel(dueDate)
                        }

                        HelaiaProgressRing(
                            value: milestone.progress,
                            size: 40,
                            lineWidth: 4,
                            label: "\(Int(milestone.progress * 100))"
                        )
                    }
                } else {
                    Text("No active milestone")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                }
            }
        }
    }

    // MARK: - Top Tasks Section

    @ViewBuilder
    private var topTasksSection: some View {
        let tint = context.theme.color(for: colorScheme)

        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "checklist",
                        size: .sm,
                        color: tint
                    )
                    Text("TOP TASKS THIS WEEK")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    Text("\(viewModel.topTasksThisWeek.count)")
                        .helaiaFont(.caption1)
                        .foregroundStyle(tint)
                }

                if viewModel.topTasksThisWeek.isEmpty {
                    Text("No tasks due this week")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing._3)
                } else {
                    ForEach(viewModel.topTasksThisWeek) { task in
                        weeklyTaskRow(task)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func weeklyTaskRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._3) {
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)

            Text(task.title)
                .helaiaFont(.footnote)
                .lineLimit(1)

            Spacer()

            if task.isBlocked {
                Text("Blocked")
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            Text(task.status.rawValue.capitalized)
                .helaiaFont(.caption2)
                .helaiaForeground(.textTertiary)

            if let dueDate = task.dueDate {
                dueDateLabel(dueDate)
            }
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Decisions Section

    @ViewBuilder
    private var decisionsSection: some View {
        if !viewModel.latestDecisions.isEmpty {
            HelaiaCard(variant: .elevated) {
                VStack(alignment: .leading, spacing: Spacing._3) {
                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            "doc.text",
                            size: .sm,
                            color: SemanticColor.textSecondary(for: colorScheme)
                        )
                        Text("RECENT DECISIONS")
                            .helaiaFont(.tag)
                            .tracking(0.5)
                            .helaiaForeground(.textSecondary)
                        Spacer()
                    }

                    ForEach(viewModel.latestDecisions) { decision in
                        HStack(spacing: Spacing._3) {
                            Text(decision.category.rawValue.capitalized)
                                .helaiaFont(.caption2)
                                .padding(.horizontal, Spacing._2)
                                .padding(.vertical, Spacing._0_5)
                                .background(
                                    Capsule().fill(
                                        SemanticColor.info(for: colorScheme).opacity(0.15)
                                    )
                                )

                            Text(decision.title)
                                .helaiaFont(.footnote)
                                .lineLimit(1)

                            Spacer()

                            Text(decision.createdAt, style: .date)
                                .helaiaFont(.caption2)
                                .helaiaForeground(.textTertiary)
                        }
                        .padding(.vertical, Spacing._1)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var weekRangeLabel: String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysToMonday, to: today),
              let sunday = calendar.date(byAdding: .day, value: 6 - daysToMonday, to: today) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monday)) – \(formatter.string(from: sunday))"
    }

    @ViewBuilder
    private func dueDateLabel(_ date: Date) -> some View {
        let daysUntil = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        let color: Color = {
            if daysUntil < 0 { return SemanticColor.error(for: colorScheme) }
            if daysUntil <= 3 { return SemanticColor.warning(for: colorScheme) }
            return SemanticColor.textTertiary(for: colorScheme)
        }()

        Text(date.formatted(.dateTime.month(.abbreviated).day()))
            .helaiaFont(.caption2)
            .foregroundStyle(color)
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .critical: SemanticColor.error(for: colorScheme)
        case .high: SemanticColor.warning(for: colorScheme)
        case .medium: SemanticColor.info(for: colorScheme)
        case .low: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("WeeklyFocusScreen") {
    let vm = WeeklyFocusViewModel(
        taskService: PreviewTaskService(),
        planningService: PreviewPlanningService(),
        decisionRepository: PreviewDecisionLogRepository(),
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
    )
    vm.tasks = CodalonTask.previewList
    vm.milestones = CodalonMilestone.previewList
    vm.recentDecisions = CodalonDecisionLogEntry.previewList

    return WeeklyFocusScreen(viewModel: vm)
        .frame(width: 900, height: 700)
        .environment(\.projectContext, .development)
}
