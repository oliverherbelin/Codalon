// Issue #186 — Context detection rules

import Foundation

// MARK: - ContextDetectionInput

/// Snapshot of project state used to determine the appropriate context.
public struct ContextDetectionInput: Sendable, Equatable {
    public let hasActiveRelease: Bool
    public let releaseStatus: CodalonReleaseStatus?
    public let daysSinceLastRelease: Int?
    public let hasRecentLaunch: Bool
    public let hasActiveMilestone: Bool
    public let hasOpenTasks: Bool

    public init(
        hasActiveRelease: Bool = false,
        releaseStatus: CodalonReleaseStatus? = nil,
        daysSinceLastRelease: Int? = nil,
        hasRecentLaunch: Bool = false,
        hasActiveMilestone: Bool = false,
        hasOpenTasks: Bool = false
    ) {
        self.hasActiveRelease = hasActiveRelease
        self.releaseStatus = releaseStatus
        self.daysSinceLastRelease = daysSinceLastRelease
        self.hasRecentLaunch = hasRecentLaunch
        self.hasActiveMilestone = hasActiveMilestone
        self.hasOpenTasks = hasOpenTasks
    }
}

// MARK: - Context Detection

/// Determine the context from a project state snapshot.
/// Free function to avoid MainActor isolation from module-level SwiftUI imports.
nonisolated public func detectContext(from input: ContextDetectionInput) -> CodalonContext {
    // Rule 1: Recent launch → Launch mode (monitoring post-launch metrics)
    if input.hasRecentLaunch {
        return .launch
    }

    // Rule 2: Active release in progress → Release mode
    if input.hasActiveRelease,
       let status = input.releaseStatus,
       isActiveReleaseStatus(status) {
        return .release
    }

    // Rule 3: No milestones, no open tasks, no active release → Maintenance
    if !input.hasActiveMilestone && !input.hasOpenTasks && !input.hasActiveRelease {
        return .maintenance
    }

    // Rule 4: Default → Development
    return .development
}

/// Whether a release status indicates active release work.
nonisolated func isActiveReleaseStatus(_ status: CodalonReleaseStatus) -> Bool {
    switch status {
    case .drafting, .readyForQA, .testing, .readyForSubmission, .submitted, .inReview:
        true
    default:
        false
    }
}
