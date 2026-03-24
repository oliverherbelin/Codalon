// Issue #284 — Detect unpushed local commits

import Foundation

// MARK: - UnpushedCommitsRule

public struct UnpushedCommitsRule: InsightRuleProtocol {

    public let ruleID = "unpushed_commits"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        guard context.localAheadCount > 0 else { return [] }

        let severity: CodalonSeverity = context.localAheadCount >= 5 ? .warning : .info

        return [
            DetectedInsight(
                ruleID: ruleID,
                type: .reminder,
                severity: severity,
                title: "Unpushed commits",
                message: "You have \(context.localAheadCount) commit\(context.localAheadCount == 1 ? "" : "s") that haven't been pushed to the remote.",
                deduplicationKey: "\(ruleID):\(context.projectID)",
                actionRoute: "localgitpanel/\(context.projectID.uuidString)"
            )
        ]
    }
}
