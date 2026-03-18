// Issue #170 — Detect stale GitHub issues

import Foundation

// MARK: - StaleGitHubIssueRule

/// Rule: linked issues open 30+ days with no activity. Generate insight.
/// Note: Since we don't track last-activity date on linked issue refs,
/// this rule checks releases with linked GitHub issues whose release
/// has been in a non-terminal state for 30+ days.
public struct StaleGitHubIssueRule: InsightRuleProtocol {

    public let ruleID = "stale_github_issues"
    private let staleDaysThreshold: Int

    nonisolated public init(staleDaysThreshold: Int = 30) {
        self.staleDaysThreshold = staleDaysThreshold
    }

    public func evaluate(context: InsightRuleContext) async -> [DetectedInsight] {
        let terminalStatuses: Set<CodalonReleaseStatus> = [.released, .cancelled, .rejected]

        let staleReleases = context.releases.filter { release in
            !terminalStatuses.contains(release.status)
                && release.deletedAt == nil
                && !release.linkedGitHubIssueRefs.isEmpty
                && daysSince(release.updatedAt, now: context.now) >= staleDaysThreshold
        }

        guard !staleReleases.isEmpty else { return [] }

        return staleReleases.map { release in
            let issueCount = release.linkedGitHubIssueRefs.count
            return DetectedInsight(
                ruleID: ruleID,
                type: .suggestion,
                severity: .info,
                title: "\(issueCount) linked issue\(issueCount == 1 ? "" : "s") may be stale",
                message: "Release \(release.version) has \(issueCount) linked GitHub issue\(issueCount == 1 ? "" : "s") with no activity for \(staleDaysThreshold)+ days.",
                deduplicationKey: "\(ruleID):\(release.id)"
            )
        }
    }

    private func daysSince(_ date: Date, now: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
    }
}
