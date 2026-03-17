// Issue #130 — Active milestone widget (Milestone Focus Card)

import SwiftUI
import HelaiaDesign

// MARK: - MilestoneFocusCard

struct MilestoneFocusCard: View {

    // MARK: - Properties

    let milestone: MilestoneFocusData?
    let onTaskToggle: ((UUID) -> Void)?
    let onCreateMilestone: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        milestone: MilestoneFocusData? = nil,
        onTaskToggle: ((UUID) -> Void)? = nil,
        onCreateMilestone: (() -> Void)? = nil
    ) {
        self.milestone = milestone
        self.onTaskToggle = onTaskToggle
        self.onCreateMilestone = onCreateMilestone
    }

    // MARK: - Body

    var body: some View {
        HelaiaMaterial.regular.apply(to:
            Group {
                if let milestone {
                    activeContent(milestone)
                } else {
                    emptyContent
                }
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: CodalonRadius.card)
                .stroke(Color.primary.opacity(0.06), lineWidth: BorderWidth.hairline)
        }
        .clipShape(RoundedRectangle(cornerRadius: CodalonRadius.card))
        .codalonShadow(CodalonShadow.card)
    }

    // MARK: - Active Content

    @ViewBuilder
    private func activeContent(_ data: MilestoneFocusData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            milestoneHeader(data)
            Divider()
                .opacity(0.06)
            if !data.blockers.isEmpty {
                blockersSection(data.blockers)
            }
            openTasksSection(data.openTasks)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func milestoneHeader(_ data: MilestoneFocusData) -> some View {
        HStack(spacing: CodalonSpacing.zoneGap) {
            VStack(alignment: .leading, spacing: Spacing._1) {
                Text(data.title)
                    .helaiaFont(.title3)
                if !data.description.isEmpty {
                    Text(data.description)
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let dueDate = data.dueDate {
                dueDateLabel(dueDate)
            }
            HelaiaProgressRing(
                value: data.progress,
                size: 32,
                lineWidth: 3,
                label: "\(Int(data.progress * 100))"
            )
        }
        .padding(.horizontal, CodalonSpacing.cardPadding)
        .padding(.vertical, CodalonSpacing.zoneGap)
    }

    @ViewBuilder
    private func dueDateLabel(_ date: Date) -> some View {
        let daysUntil = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        let color: Color = {
            if daysUntil < 0 { return SemanticColor.error(for: colorScheme) }
            if daysUntil <= 7 { return SemanticColor.warning(for: colorScheme) }
            return SemanticColor.textSecondary(for: colorScheme)
        }()

        Text(date.formatted(.dateTime.month(.abbreviated).day()))
            .helaiaFont(.caption1)
            .foregroundStyle(color)
    }

    // MARK: - Blockers Section

    @ViewBuilder
    private func blockersSection(_ blockers: [TaskRowData]) -> some View {
        let maxDisplay = 3
        let overflow = max(blockers.count - maxDisplay, 0)

        VStack(alignment: .leading, spacing: 0) {
            Text("BLOCKERS")
                .helaiaFont(.tag)
                .tracking(0.5)
                .foregroundStyle(SemanticColor.error(for: colorScheme))
                .padding(.horizontal, CodalonSpacing.cardPadding)
                .padding(.top, 12)
                .padding(.bottom, Spacing._2)

            ForEach(blockers.prefix(maxDisplay)) { task in
                taskRow(task)
            }

            if overflow > 0 {
                Text("+ \(overflow) more blockers")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
                    .padding(.horizontal, CodalonSpacing.cardPadding)
                    .padding(.vertical, Spacing._2)
            }
        }
        .background(SemanticColor.error(for: colorScheme).opacity(0.03))
    }

    // MARK: - Open Tasks Section

    @ViewBuilder
    private func openTasksSection(_ tasks: [TaskRowData]) -> some View {
        let maxDisplay = 8
        let overflow = max(tasks.count - maxDisplay, 0)

        VStack(alignment: .leading, spacing: 0) {
            Text("OPEN TASKS")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
                .padding(.horizontal, CodalonSpacing.cardPadding)
                .padding(.top, 12)
                .padding(.bottom, Spacing._2)

            ForEach(tasks.prefix(maxDisplay)) { task in
                taskRow(task)
            }

            if overflow > 0 {
                let tint = context.theme.color(for: colorScheme)
                Text("+ \(overflow) more")
                    .helaiaFont(.caption1)
                    .foregroundStyle(tint)
                    .padding(.horizontal, CodalonSpacing.cardPadding)
                    .padding(.vertical, Spacing._2)
            }
        }
    }

    // MARK: - Task Row

    @ViewBuilder
    private func taskRow(_ task: TaskRowData) -> some View {
        HStack(spacing: Spacing._3) {
            Button {
                onTaskToggle?(task.id)
            } label: {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(SemanticColor.textSecondary(for: colorScheme), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(task.title)")

            statusIndicator(task.status)

            Text(task.title)
                .helaiaFont(.footnote)
                .lineLimit(1)

            if task.hasGitHubRef {
                HelaiaIconView("link", size: .xs, color: SemanticColor.textSecondary(for: colorScheme))
                    .accessibilityHidden(true)
            }

            Spacer()

            priorityDot(task.priority)
        }
        .frame(height: 36)
        .padding(.horizontal, CodalonSpacing.cardPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statusIndicator(_ status: CodalonTaskStatus) -> some View {
        let tint = context.theme.color(for: colorScheme)
        Circle()
            .strokeBorder(tint, lineWidth: 1.5)
            .background {
                if status == .inProgress {
                    Circle()
                        .fill(tint)
                        .padding(3)
                }
            }
            .frame(width: 10, height: 10)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func priorityDot(_ priority: CodalonPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .critical, .high:
            SemanticColor.error(for: colorScheme)
        case .medium:
            SemanticColor.warning(for: colorScheme)
        case .low:
            SemanticColor.textSecondary(for: colorScheme).opacity(0.4)
        }
    }

    // MARK: - Empty Content

    @ViewBuilder
    private var emptyContent: some View {
        let tint = context.theme.color(for: colorScheme)
        VStack(spacing: Spacing._4) {
            Text("No active milestone")
                .helaiaFont(.headline)
                .helaiaForeground(.textSecondary)
            if let onCreateMilestone {
                HelaiaButton.secondary("Create milestone", action: onCreateMilestone)
                    .fixedSize()
                    .tint(tint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(0.5)
    }
}

// MARK: - MilestoneFocusData

struct MilestoneFocusData: Sendable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let dueDate: Date?
    let progress: Double
    let blockers: [TaskRowData]
    let openTasks: [TaskRowData]
}

// MARK: - TaskRowData

struct TaskRowData: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let status: CodalonTaskStatus
    let priority: CodalonPriority
    let hasGitHubRef: Bool
}

// MARK: - Preview

#Preview("MilestoneFocusCard — Active") {
    let projectID = UUID()
    let milestone = MilestoneFocusData(
        id: UUID(),
        title: "Beta Release",
        description: "First public beta with core features",
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now),
        progress: 0.65,
        blockers: [
            TaskRowData(
                id: UUID(), title: "Fix crash on launch",
                status: .inProgress, priority: .critical, hasGitHubRef: true
            )
        ],
        openTasks: [
            TaskRowData(
                id: UUID(), title: "Implement dashboard layout",
                status: .inProgress, priority: .high, hasGitHubRef: true
            ),
            TaskRowData(
                id: UUID(), title: "Add project summary card",
                status: .todo, priority: .medium, hasGitHubRef: false
            ),
            TaskRowData(
                id: UUID(), title: "Write unit tests for sync",
                status: .todo, priority: .low, hasGitHubRef: true
            )
        ]
    )

    MilestoneFocusCard(milestone: milestone)
        .frame(width: 700, height: 430)
        .padding()
        .environment(\.projectContext, .development)
}

#Preview("MilestoneFocusCard — Empty") {
    MilestoneFocusCard(onCreateMilestone: {})
        .frame(width: 700, height: 430)
        .padding()
        .environment(\.projectContext, .development)
}
