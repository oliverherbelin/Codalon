// Issue #144 — Readiness score calculation

import Foundation

// MARK: - ReleaseReadinessCalculator

public enum ReleaseReadinessCalculator {

    /// Calculates a 0–100 readiness score for a release.
    ///
    /// Weights:
    /// - Checklist completion: 40%
    /// - Blocker resolution: 30%
    /// - Linked issue closure: 20%
    /// - Has target date: 10%
    nonisolated public static func score(for release: CodalonRelease, closedIssueRatio: Double = 0) -> Double {
        let checklistScore = checklistCompletion(release.checklistItems) * 40
        let blockerScore = blockerResolution(release.blockers) * 30
        let issueScore = closedIssueRatio * 20
        let dateScore: Double = release.targetDate != nil ? 10 : 0

        return min(100, checklistScore + blockerScore + issueScore + dateScore)
    }

    // MARK: - Private

    private nonisolated static func checklistCompletion(_ items: [CodalonChecklistItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        let completed = items.filter(\.isComplete).count
        return Double(completed) / Double(items.count)
    }

    private nonisolated static func blockerResolution(_ blockers: [CodalonReleaseBlocker]) -> Double {
        guard !blockers.isEmpty else { return 1.0 }
        let resolved = blockers.filter(\.isResolved).count
        return Double(resolved) / Double(blockers.count)
    }
}
