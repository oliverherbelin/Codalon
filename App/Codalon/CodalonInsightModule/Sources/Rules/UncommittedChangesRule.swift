// Issue #283 — Detect uncommitted local changes

import Foundation

// MARK: - UncommittedChangesRule

public struct UncommittedChangesRule: InsightRuleProtocol {

    public let ruleID = "uncommitted_changes"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let total = context.localUnstagedCount + context.localStagedCount
        guard total > 0 else { return [] }

        let severity: CodalonSeverity = total >= 10 ? .warning : .info

        let parts: [String] = [
            context.localStagedCount > 0
                ? "\(context.localStagedCount) staged"
                : nil,
            context.localUnstagedCount > 0
                ? "\(context.localUnstagedCount) unstaged"
                : nil,
        ].compactMap { $0 }

        return [
            DetectedInsight(
                ruleID: ruleID,
                type: .reminder,
                severity: severity,
                title: "Uncommitted changes",
                message: "You have \(parts.joined(separator: " and ")) file\(total == 1 ? "" : "s") that haven't been committed yet.",
                deduplicationKey: "\(ruleID):\(context.projectID)"
            )
        ]
    }
}
