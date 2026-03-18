// Issue #88 — Follow-up-needed section

import SwiftUI
import HelaiaDesign

// MARK: - FollowUpSection

struct FollowUpSection: View {

    // MARK: - Properties

    let tasks: [CodalonTask]
    let onStatusChange: ((UUID, CodalonTaskStatus) -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        tasks: [CodalonTask],
        onStatusChange: ((UUID, CodalonTaskStatus) -> Void)? = nil
    ) {
        self.tasks = tasks
        self.onStatusChange = onStatusChange
    }

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header

                if tasks.isEmpty {
                    emptyState
                } else {
                    ForEach(tasks) { task in
                        followUpRow(task)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Follow-up needed")
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "bell.badge",
                size: .sm,
                color: SemanticColor.warning(for: colorScheme)
            )
            Text("FOLLOW-UP NEEDED")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
            if !tasks.isEmpty {
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.warning(for: colorScheme))
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func followUpRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._3) {
            priorityDot(task.priority)

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(task.title)
                    .helaiaFont(.footnote)
                    .lineLimit(1)

                if let dueDate = task.dueDate {
                    let daysUntil = Calendar.current.dateComponents(
                        [.day], from: .now, to: dueDate
                    ).day ?? 0
                    Text(daysUntil < 0
                        ? "Overdue by \(abs(daysUntil))d"
                        : "Due in \(daysUntil)d")
                        .helaiaFont(.caption2)
                        .foregroundStyle(
                            daysUntil < 0
                                ? SemanticColor.error(for: colorScheme)
                                : SemanticColor.textTertiary(for: colorScheme)
                        )
                }
            }

            Spacer()

            Button {
                onStatusChange?(task.id, .done)
            } label: {
                HelaiaIconView(
                    "checkmark.circle",
                    size: .sm,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Complete \(task.title)")
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Priority Dot

    @ViewBuilder
    private func priorityDot(_ priority: CodalonPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 6, height: 6)
            .accessibilityHidden(true)
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .critical: SemanticColor.error(for: colorScheme)
        case .high: SemanticColor.warning(for: colorScheme)
        case .medium: SemanticColor.info(for: colorScheme)
        case .low: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        Text("Nothing needs follow-up")
            .helaiaFont(.footnote)
            .helaiaForeground(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing._4)
    }
}

// MARK: - Preview

#Preview("FollowUpSection") {
    FollowUpSection(
        tasks: [
            CodalonTask(
                projectID: UUID(),
                title: "Review design feedback from QA",
                status: .inReview,
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now)
            ),
            CodalonTask(
                projectID: UUID(),
                title: "Check CI pipeline fix",
                status: .inProgress,
                priority: .medium,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now)
            ),
        ]
    )
    .frame(width: 400)
    .padding()
    .environment(\.projectContext, .development)
}

#Preview("FollowUpSection — Empty") {
    FollowUpSection(tasks: [])
        .frame(width: 400)
        .padding()
        .environment(\.projectContext, .development)
}
