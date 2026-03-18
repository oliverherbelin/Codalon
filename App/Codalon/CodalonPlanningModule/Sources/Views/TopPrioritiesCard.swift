// Issue #86 — Top-3 priorities card

import SwiftUI
import HelaiaDesign

// MARK: - TopPrioritiesCard

struct TopPrioritiesCard: View {

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
        let tint = context.theme.color(for: colorScheme)

        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                header(tint: tint)

                if tasks.isEmpty {
                    emptyState
                } else {
                    ForEach(tasks.prefix(3)) { task in
                        priorityRow(task, tint: tint)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Top priorities")
    }

    // MARK: - Header

    @ViewBuilder
    private func header(tint: Color) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView("flame.fill", size: .sm, color: tint)
            Text("TOP PRIORITIES")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
            Text("\(tasks.prefix(3).count)")
                .helaiaFont(.caption1)
                .foregroundStyle(tint)
        }
    }

    // MARK: - Priority Row

    @ViewBuilder
    private func priorityRow(_ task: CodalonTask, tint: Color) -> some View {
        HStack(spacing: Spacing._3) {
            priorityIndicator(task.priority)

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(task.title)
                    .helaiaFont(.footnote)
                    .lineLimit(1)

                HStack(spacing: Spacing._2) {
                    statusLabel(task.status)

                    if let dueDate = task.dueDate {
                        dueDateLabel(dueDate)
                    }

                    if task.isBlocked {
                        Text("Blocked")
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.error(for: colorScheme))
                    }
                }
            }

            Spacer()

            if task.status != .done {
                Button {
                    onStatusChange?(task.id, .inProgress)
                } label: {
                    HelaiaIconView(
                        "play.circle",
                        size: .sm,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(task.title)")
            }
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Priority Indicator

    @ViewBuilder
    private func priorityIndicator(_ priority: CodalonPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 8, height: 8)
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

    // MARK: - Status Label

    @ViewBuilder
    private func statusLabel(_ status: CodalonTaskStatus) -> some View {
        Text(status.rawValue.capitalized)
            .helaiaFont(.caption2)
            .helaiaForeground(.textTertiary)
    }

    // MARK: - Due Date

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

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        Text("No active high-priority tasks")
            .helaiaFont(.footnote)
            .helaiaForeground(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing._4)
    }
}

// MARK: - Preview

#Preview("TopPrioritiesCard") {
    TopPrioritiesCard(
        tasks: [
            CodalonTask(
                projectID: UUID(),
                title: "Fix critical crash on launch",
                status: .inProgress,
                priority: .critical,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now),
                isBlocked: false
            ),
            CodalonTask(
                projectID: UUID(),
                title: "Implement dashboard layout",
                status: .todo,
                priority: .high,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now)
            ),
            CodalonTask(
                projectID: UUID(),
                title: "Design system alignment audit",
                status: .inProgress,
                priority: .critical,
                isLaunchCritical: true
            ),
        ]
    )
    .frame(width: 400)
    .padding()
    .environment(\.projectContext, .development)
}

#Preview("TopPrioritiesCard — Empty") {
    TopPrioritiesCard(tasks: [])
        .frame(width: 400)
        .padding()
        .environment(\.projectContext, .development)
}
