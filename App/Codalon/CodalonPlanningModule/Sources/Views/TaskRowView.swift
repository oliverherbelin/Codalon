// Issue #36 — Task row

import SwiftUI
import HelaiaDesign

// MARK: - TaskRowView

struct TaskRowView: View {

    // MARK: - Properties

    let task: CodalonTask
    let isSelected: Bool
    let onTap: () -> Void
    let onStatusChange: (CodalonTaskStatus) -> Void

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated) {
            HStack(spacing: Spacing._3) {
                priorityIndicator
                taskContent
                Spacer()
                taskMeta
            }
        }
        .overlay(selectionBorder)
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.priority.rawValue) priority, \(task.status.displayLabel)")
    }

    // MARK: - Priority Indicator

    @ViewBuilder
    private var priorityIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(priorityColor)
            .frame(width: 3, height: 32)
    }

    // MARK: - Content

    @ViewBuilder
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HStack(spacing: Spacing._2) {
                Text(task.title)
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    .lineLimit(1)

                if task.isBlocked {
                    HelaiaIconView("xmark.octagon.fill", size: .sm, color: SemanticColor.error(for: colorScheme))
                }
                if task.isLaunchCritical {
                    HelaiaIconView("bolt.fill", size: .sm, color: SemanticColor.warning(for: colorScheme))
                }
                if task.waitingExternal {
                    HelaiaIconView("clock.badge.questionmark", size: .sm, color: SemanticColor.info(for: colorScheme))
                }
            }

            if !task.summary.isEmpty {
                Text(task.summary)
                    .helaiaFont(.footnote)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Meta

    @ViewBuilder
    private var taskMeta: some View {
        HStack(spacing: Spacing._3) {
            if let estimate = task.estimate {
                HStack(spacing: Spacing._1) {
                    HelaiaIconView("clock", size: .sm, color: SemanticColor.textTertiary(for: colorScheme))
                    Text(String(format: "%.0fh", estimate))
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }
            }

            if let dueDate = task.dueDate {
                HStack(spacing: Spacing._1) {
                    HelaiaIconView("calendar", size: .sm, color: dueDateColor(dueDate))
                    Text(dueDate, style: .date)
                        .helaiaFont(.caption1)
                        .foregroundStyle(dueDateColor(dueDate))
                }
            }

            HStack(spacing: Spacing._1) {
                Circle()
                    .fill(statusColor(task.status))
                    .frame(width: 6, height: 6)
                Text(task.status.displayLabel)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }
        }
    }

    // MARK: - Selection Border

    @ViewBuilder
    private var selectionBorder: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: CodalonRadius.card)
                .stroke(SemanticColor.info(for: colorScheme), lineWidth: 2)
        }
    }

    // MARK: - Helpers

    private var priorityColor: Color {
        switch task.priority {
        case .low: SemanticColor.success(for: colorScheme)
        case .medium: SemanticColor.warning(for: colorScheme)
        case .high: Color.orange
        case .critical: SemanticColor.error(for: colorScheme)
        }
    }

    private func statusColor(_ status: CodalonTaskStatus) -> Color {
        switch status {
        case .backlog: SemanticColor.textTertiary(for: colorScheme)
        case .todo: SemanticColor.info(for: colorScheme)
        case .inProgress: SemanticColor.warning(for: colorScheme)
        case .inReview: SemanticColor.info(for: colorScheme)
        case .done: SemanticColor.success(for: colorScheme)
        case .cancelled: SemanticColor.textTertiary(for: colorScheme)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        date < Date() ? SemanticColor.error(for: colorScheme) : SemanticColor.textTertiary(for: colorScheme)
    }
}

// MARK: - Preview

#Preview("TaskRowView") {
    VStack(spacing: 8) {
        TaskRowView(
            task: CodalonTask(
                projectID: UUID(),
                title: "Implement task list",
                summary: "Create the main task list view",
                status: .inProgress,
                priority: .high,
                estimate: 4,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now),
                isBlocked: false,
                isLaunchCritical: true
            ),
            isSelected: false,
            onTap: {},
            onStatusChange: { _ in }
        )
        TaskRowView(
            task: CodalonTask(
                projectID: UUID(),
                title: "Fix blocked task",
                status: .todo,
                priority: .critical,
                isBlocked: true
            ),
            isSelected: true,
            onTap: {},
            onStatusChange: { _ in }
        )
    }
    .padding()
}