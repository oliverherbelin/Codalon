// Issue #160 — Health score dimensions

import Foundation

// MARK: - HealthScoreDimension

public struct HealthScoreDimension: Identifiable, Sendable, Equatable {
    public let id: String
    public let label: String
    public let value: Double
    public let weight: Double

    nonisolated public init(id: String, label: String, value: Double, weight: Double = 0.25) {
        self.id = id
        self.label = label
        self.value = max(0, min(1, value))
        self.weight = weight
    }
}

// MARK: - Predefined Dimension IDs

public enum HealthScoreDimensionID: Sendable {
    nonisolated public static let planning = "planning"
    nonisolated public static let release = "release"
    nonisolated public static let github = "github"
    nonisolated public static let store = "store"
}

// MARK: - Planning Health Calculator

public enum PlanningHealthCalculator: Sendable {

    /// Calculates planning health from tasks and milestones.
    /// - Factors: task completion ratio, overdue tasks, milestone progress
    nonisolated public static func calculate(
        totalTasks: Int,
        completedTasks: Int,
        overdueTasks: Int,
        milestoneProgress: Double
    ) -> Double {
        guard totalTasks > 0 else { return 0 }

        let completionRatio = Double(completedTasks) / Double(totalTasks)
        let overdueRatio = 1.0 - (Double(overdueTasks) / Double(totalTasks))

        // Weighted: 40% completion, 30% no overdue, 30% milestone progress
        return completionRatio * 0.4 + overdueRatio * 0.3 + milestoneProgress * 0.3
    }
}

// MARK: - Release Health Calculator

public enum ReleaseHealthCalculator: Sendable {

    /// Calculates release health from readiness score and blockers.
    nonisolated public static func calculate(
        readinessScore: Double,
        blockerCount: Int,
        hasTargetDate: Bool
    ) -> Double {
        // readinessScore is 0–100, normalize to 0–1
        let normalized = readinessScore / 100.0
        let blockerPenalty = min(1.0, Double(blockerCount) * 0.15)
        let dateBonus: Double = hasTargetDate ? 0.05 : 0

        return max(0, min(1, normalized - blockerPenalty + dateBonus))
    }
}

// MARK: - GitHub Health Calculator

public enum GitHubHealthCalculator: Sendable {

    /// Calculates GitHub health from issue and PR metrics.
    nonisolated public static func calculate(
        openIssueCount: Int,
        staleIssueCount: Int,
        openPRCount: Int,
        stalePRCount: Int
    ) -> Double {
        guard openIssueCount + openPRCount > 0 else { return 1.0 }

        let totalOpen = Double(openIssueCount + openPRCount)
        let totalStale = Double(staleIssueCount + stalePRCount)
        let staleRatio = totalStale / totalOpen

        return max(0, 1.0 - staleRatio)
    }
}

// MARK: - Store Health Calculator

public enum StoreHealthCalculator: Sendable {

    /// Calculates App Store health from review and crash metrics.
    nonisolated public static func calculate(
        hasRecentReview: Bool,
        crashFreeRate: Double,
        metadataComplete: Bool
    ) -> Double {
        var score = 0.0
        if hasRecentReview { score += 0.2 }
        score += crashFreeRate * 0.5
        if metadataComplete { score += 0.3 }
        return min(1, score)
    }
}
