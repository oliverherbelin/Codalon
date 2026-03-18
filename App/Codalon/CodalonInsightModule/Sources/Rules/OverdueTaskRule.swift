// Issue #165 — Detect overdue tasks

import Foundation

// MARK: - OverdueTaskRule

public struct OverdueTaskRule: InsightRuleProtocol {

    public let ruleID = "overdue_task"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let overdueTasks = context.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < context.now
                && task.status != .done
                && task.status != .cancelled
                && task.deletedAt == nil
        }

        guard !overdueTasks.isEmpty else { return [] }

        return [
            DetectedInsight(
                ruleID: ruleID,
                type: .reminder,
                severity: overdueTasks.count > 3 ? .warning : .info,
                title: "\(overdueTasks.count) overdue task\(overdueTasks.count == 1 ? "" : "s")",
                message: overdueTasks.prefix(3).map(\.title).joined(separator: ", ")
                    + (overdueTasks.count > 3 ? " and \(overdueTasks.count - 3) more" : ""),
                deduplicationKey: "\(ruleID):\(context.projectID):\(overdueTasks.count)"
            )
        ]
    }
}
