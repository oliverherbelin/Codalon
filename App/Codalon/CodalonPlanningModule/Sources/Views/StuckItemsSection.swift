// Issue #92 — Stuck-items section

import SwiftUI
import HelaiaDesign

// MARK: - StuckItemsSection

struct StuckItemsSection: View {

    // MARK: - Properties

    let tasks: [CodalonTask]
    let onUnblock: ((UUID) -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        tasks: [CodalonTask],
        onUnblock: ((UUID) -> Void)? = nil
    ) {
        self.tasks = tasks
        self.onUnblock = onUnblock
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
                        stuckRow(task)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Stuck items")
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "exclamationmark.triangle",
                size: .sm,
                color: SemanticColor.error(for: colorScheme)
            )
            Text("STUCK ITEMS")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
            if !tasks.isEmpty {
                Text("\(tasks.count)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func stuckRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._3) {
            priorityDot(task.priority)

            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text(task.title)
                    .helaiaFont(.footnote)
                    .lineLimit(1)

                HStack(spacing: Spacing._2) {
                    if task.isBlocked {
                        Text("Blocked")
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.error(for: colorScheme))
                    }

                    let staleDays = staleDayCount(task)
                    if staleDays >= 7 {
                        Text("No movement for \(staleDays)d")
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.warning(for: colorScheme))
                    }
                }
            }

            Spacer()

            if task.isBlocked {
                Button {
                    onUnblock?(task.id)
                } label: {
                    Text("Unblock")
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.success(for: colorScheme))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Unblock \(task.title)")
            }
        }
        .padding(.vertical, Spacing._1)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stale Day Count

    private func staleDayCount(_ task: CodalonTask) -> Int {
        Calendar.current.dateComponents(
            [.day], from: task.updatedAt, to: .now
        ).day ?? 0
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
        Text("Nothing stuck — all clear")
            .helaiaFont(.footnote)
            .helaiaForeground(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing._4)
    }
}

// MARK: - Preview

#Preview("StuckItemsSection") {
    StuckItemsSection(
        tasks: [
            CodalonTask(
                projectID: UUID(),
                title: "Blocked by missing API credentials",
                status: .inProgress,
                priority: .critical,
                isBlocked: true
            ),
            CodalonTask(
                createdAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)!,
                updatedAt: Calendar.current.date(byAdding: .day, value: -10, to: .now)!,
                projectID: UUID(),
                title: "Refactor legacy sync module",
                status: .todo,
                priority: .medium
            ),
        ]
    )
    .frame(width: 400)
    .padding()
    .environment(\.projectContext, .development)
}

#Preview("StuckItemsSection — Empty") {
    StuckItemsSection(tasks: [])
        .frame(width: 400)
        .padding()
        .environment(\.projectContext, .development)
}
