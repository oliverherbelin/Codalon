// Issue #125 — Sprint horizon zone (Development Mode Canvas)

import SwiftUI
import HelaiaDesign

// MARK: - SprintHorizon

struct SprintHorizon: View {

    // MARK: - Properties

    let milestones: [SprintMilestoneData]
    let onCreateMilestone: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        milestones: [SprintMilestoneData] = [],
        onCreateMilestone: (() -> Void)? = nil
    ) {
        self.milestones = milestones
        self.onCreateMilestone = onCreateMilestone
    }

    // MARK: - Body

    var body: some View {
        let tint = context.theme.color(for: colorScheme)

        HelaiaMaterial.ultraThin.apply(to:
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, CodalonSpacing.zoneGap)
                    .padding(.top, CodalonSpacing.zoneGap)
                    .padding(.bottom, Spacing._2)

                if milestones.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(milestones.prefix(4)) { milestone in
                                milestoneRow(milestone)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                if let onCreateMilestone {
                    Button(action: onCreateMilestone) {
                        HStack(spacing: Spacing._1_5) {
                            HelaiaIconView("plus", size: .xs, color: tint)
                            Text("New milestone")
                                .helaiaFont(.caption1)
                                .foregroundStyle(tint)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, CodalonSpacing.zoneGap)
                    .padding(.bottom, CodalonSpacing.zoneGap)
                }
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: CodalonRadius.zone)
                .stroke(Color.primary.opacity(0.06), lineWidth: BorderWidth.hairline)
        }
        .clipShape(RoundedRectangle(cornerRadius: CodalonRadius.zone))
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "chart.line.uptrend.xyaxis",
                size: .xs,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("SPRINT HORIZON")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Milestone Row

    @ViewBuilder
    private func milestoneRow(_ milestone: SprintMilestoneData) -> some View {
        HStack(spacing: Spacing._3) {
            Circle()
                .fill(statusDotColor(milestone))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Text(milestone.title)
                .helaiaFont(.footnote)
                .lineLimit(1)

            Spacer()

            Text("\(milestone.taskCount) tasks")
                .helaiaFont(.caption2)
                .helaiaForeground(.textSecondary)

            if let dueDate = milestone.dueDate {
                let daysUntil = Calendar.current.dateComponents(
                    [.day], from: .now, to: dueDate
                ).day ?? 0
                Text(dueDate.formatted(.dateTime.month(.abbreviated).day()))
                    .helaiaFont(.caption2)
                    .foregroundStyle(
                        daysUntil <= 14
                            ? SemanticColor.warning(for: colorScheme)
                            : SemanticColor.textSecondary(for: colorScheme)
                    )
            }
        }
        .frame(height: 44)
        .padding(.horizontal, CodalonSpacing.zoneGap)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func statusDotColor(_ milestone: SprintMilestoneData) -> Color {
        if milestone.dueDate == nil {
            return SemanticColor.warning(for: colorScheme)
        }
        if let dueDate = milestone.dueDate, dueDate < .now {
            return SemanticColor.error(for: colorScheme)
        }
        return SemanticColor.success(for: colorScheme)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Spacing._3) {
            HelaiaIconView(
                "flag.checkered",
                size: .xl,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("All clear")
                .helaiaFont(.footnote)
                .helaiaForeground(.textSecondary)
            Text("No upcoming milestones")
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SprintMilestoneData

struct SprintMilestoneData: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let taskCount: Int
    let dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        taskCount: Int,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskCount = taskCount
        self.dueDate = dueDate
    }
}

// MARK: - Preview

#Preview("SprintHorizon") {
    SprintHorizon(
        milestones: [
            SprintMilestoneData(
                title: "Beta Release",
                taskCount: 8,
                dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now)
            ),
            SprintMilestoneData(
                title: "Public Launch",
                taskCount: 15,
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)
            ),
            SprintMilestoneData(
                title: "Post-Launch Polish",
                taskCount: 5
            )
        ],
        onCreateMilestone: {}
    )
    .frame(width: 350, height: 280)
    .padding()
    .environment(\.projectContext, .development)
}
