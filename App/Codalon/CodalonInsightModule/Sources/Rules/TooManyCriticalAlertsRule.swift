// Issue #174 — Detect too many critical alerts

import Foundation

// MARK: - TooManyCriticalAlertsRule

/// Rule: more than 3 unread critical alerts. Generate summary insight.
public struct TooManyCriticalAlertsRule: InsightRuleProtocol {

    public let ruleID = "too_many_critical_alerts"
    private let threshold: Int

    nonisolated public init(threshold: Int = 3) {
        self.threshold = threshold
    }

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let unreadCritical = context.alerts.filter { alert in
            alert.severity == .critical
                && alert.readState == .unread
                && alert.deletedAt == nil
        }

        guard unreadCritical.count > threshold else { return [] }

        return [
            DetectedInsight(
                ruleID: ruleID,
                type: .anomaly,
                severity: .critical,
                title: "\(unreadCritical.count) unread critical alerts",
                message: "You have \(unreadCritical.count) unread critical alerts. Review and address them to keep the project healthy.",
                deduplicationKey: "\(ruleID):\(context.projectID):\(unreadCritical.count)"
            )
        ]
    }
}
