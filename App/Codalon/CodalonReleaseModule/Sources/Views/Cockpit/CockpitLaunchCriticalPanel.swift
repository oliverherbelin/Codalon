// Issue #173 — Launch-critical warning area

import SwiftUI
import HelaiaDesign

// MARK: - CockpitLaunchCriticalPanel

struct CockpitLaunchCriticalPanel: View {

    let tasks: [CodalonTask]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let criticalTasks = tasks.filter {
            $0.isLaunchCritical && $0.status != .done && $0.status != .cancelled && $0.deletedAt == nil
        }

        if !criticalTasks.isEmpty {
            ReleaseCockpitPanel(
                title: "Launch-Critical",
                icon: "bolt.trianglebadge.exclamationmark",
                badgeCount: criticalTasks.count
            ) {
                VStack(spacing: Spacing._2) {
                    ForEach(criticalTasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func taskRow(_ task: CodalonTask) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "bolt.fill",
                size: .xs,
                color: priorityColor(task.priority)
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .helaiaFont(.subheadline)

                HStack(spacing: Spacing._1) {
                    Text(task.status.rawValue)
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)

                    if let dueDate = task.dueDate {
                        Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .helaiaFont(.caption1)
                            .foregroundStyle(
                                dueDate < Date()
                                    ? SemanticColor.error(for: colorScheme)
                                    : SemanticColor.textTertiary(for: colorScheme)
                            )
                    }
                }
            }

            Spacer()
        }
    }

    private func priorityColor(_ priority: CodalonPriority) -> Color {
        switch priority {
        case .critical: SemanticColor.error(for: colorScheme)
        case .high: SemanticColor.warning(for: colorScheme)
        case .medium: SemanticColor.textSecondary(for: colorScheme)
        case .low: SemanticColor.textTertiary(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("CockpitLaunchCriticalPanel") {
    let tasks = [
        CodalonTask(
            projectID: UUID(),
            title: "Fix critical crash on launch",
            status: .inProgress,
            priority: .critical,
            dueDate: Date().addingTimeInterval(-86400),
            isLaunchCritical: true
        ),
        CodalonTask(
            projectID: UUID(),
            title: "Complete privacy manifest",
            status: .todo,
            priority: .high,
            isLaunchCritical: true
        ),
    ]

    return CockpitLaunchCriticalPanel(tasks: tasks)
        .padding()
        .frame(width: 400)
}

#Preview("CockpitLaunchCriticalPanel — No Critical Tasks") {
    CockpitLaunchCriticalPanel(tasks: [])
        .padding()
        .frame(width: 400)
}
