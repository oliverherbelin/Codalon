// Issue #167 — Detect blocked releases

import Foundation

// MARK: - BlockedReleaseRule

public struct BlockedReleaseRule: InsightRuleProtocol {

    public let ruleID = "blocked_release"

    nonisolated public init() {}

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]

        return context.releases
            .filter { release in
                !terminalStatuses.contains(release.status)
                    && release.blockerCount > 0
                    && release.deletedAt == nil
                    && isWithinSevenDays(release.targetDate, now: context.now)
            }
            .map { release in
                let daysUntil = daysUntilTarget(release.targetDate, now: context.now)

                return DetectedInsight(
                    ruleID: ruleID,
                    type: .anomaly,
                    severity: .warning,
                    title: "Release \(release.version) has \(release.blockerCount) blocker\(release.blockerCount == 1 ? "" : "s")",
                    message: daysUntil >= 0
                        ? "Target date is in \(daysUntil) day\(daysUntil == 1 ? "" : "s"). Resolve blockers before shipping."
                        : "Target date has passed. Resolve blockers to ship.",
                    deduplicationKey: "\(ruleID):\(release.id):\(release.blockerCount)"
                )
            }
    }

    // MARK: - Private

    private func isWithinSevenDays(_ targetDate: Date?, now: Date) -> Bool {
        guard let target = targetDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: now, to: target).day ?? 0
        return days <= 7
    }

    private func daysUntilTarget(_ targetDate: Date?, now: Date) -> Int {
        guard let target = targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: now, to: target).day ?? 0
    }
}
