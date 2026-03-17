// Issue #120 — Project summary model

import Foundation

public struct ProjectSummary: Sendable, Equatable {
    public let projectID: UUID
    public let openTaskCount: Int
    public let milestoneCount: Int
    public let activeReleaseVersion: String?
    public let healthScore: Double

    public nonisolated init(
        projectID: UUID,
        openTaskCount: Int,
        milestoneCount: Int,
        activeReleaseVersion: String?,
        healthScore: Double
    ) {
        self.projectID = projectID
        self.openTaskCount = openTaskCount
        self.milestoneCount = milestoneCount
        self.activeReleaseVersion = activeReleaseVersion
        self.healthScore = healthScore
    }
}
