// Issue #163 — Detect overdue milestones

import Foundation

// MARK: - OverdueMilestoneRule

public struct OverdueMilestoneRule: InsightRuleProtocol {

    public let ruleID = "overdue_milestone"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        context.milestones
            .filter { milestone in
                guard let dueDate = milestone.dueDate else { return false }
                return dueDate < context.now
                    && milestone.status != .completed
                    && milestone.status != .cancelled
                    && milestone.deletedAt == nil
            }
            .map { milestone in
                let daysOverdue = Calendar.current.dateComponents(
                    [.day], from: milestone.dueDate!, to: context.now
                ).day ?? 0

                return DetectedInsight(
                    ruleID: ruleID,
                    type: .reminder,
                    severity: daysOverdue > 7 ? .warning : .info,
                    title: "Milestone overdue: \(milestone.title)",
                    message: "\(milestone.title) was due \(daysOverdue) day\(daysOverdue == 1 ? "" : "s") ago and is still \(milestone.status.rawValue).",
                    deduplicationKey: "\(ruleID):\(milestone.id)"
                )
            }
    }
}
