// Issue #156 — Alert auto-dismissal rules

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol AlertDismissalServiceProtocol: Sendable {
    func evaluateDismissals(projectID: UUID) async throws -> Int
}

// MARK: - Implementation

public actor AlertDismissalService: AlertDismissalServiceProtocol {

    private let alertRepository: any AlertRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol
    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        alertRepository: any AlertRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol,
        milestoneRepository: any MilestoneRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.alertRepository = alertRepository
        self.releaseRepository = releaseRepository
        self.milestoneRepository = milestoneRepository
        self.logger = logger
    }

    /// Evaluates all unread alerts and auto-dismisses those whose underlying condition
    /// has been resolved. Returns count of dismissed alerts.
    public func evaluateDismissals(projectID: UUID) async throws -> Int {
        let unread = try await alertRepository.fetchUnread(projectID: projectID)
        var dismissedCount = 0

        for alert in unread where alert.deletedAt == nil {
            let shouldDismiss = try await shouldAutoDismiss(alert, projectID: projectID)
            if shouldDismiss {
                try await alertRepository.dismiss(id: alert.id)
                dismissedCount += 1
                logger.info("Auto-dismissed alert: \(alert.title)", category: "notification")
            }
        }

        if dismissedCount > 0 {
            logger.success("Auto-dismissed \(dismissedCount) resolved alert\(dismissedCount == 1 ? "" : "s")", category: "notification")
        }

        return dismissedCount
    }

    // MARK: - Private

    private func shouldAutoDismiss(_ alert: CodalonAlert, projectID: UUID) async throws -> Bool {
        switch alert.category {
        case .release:
            return try await isReleaseAlertResolved(alert, projectID: projectID)
        case .milestone:
            return try await isMilestoneAlertResolved(alert, projectID: projectID)
        case .build, .crash, .review, .security, .git, .general:
            return false
        }
    }

    private func isReleaseAlertResolved(_ alert: CodalonAlert, projectID: UUID) async throws -> Bool {
        let activeRelease = try await releaseRepository.fetchActive(projectID: projectID)
        guard let release = activeRelease else {
            // No active release — alert is moot
            return true
        }
        // If alert was about blockers and blockers are now zero, dismiss
        if alert.title.lowercased().contains("blocker") && release.blockerCount == 0 {
            return true
        }
        return false
    }

    private func isMilestoneAlertResolved(_ alert: CodalonAlert, projectID: UUID) async throws -> Bool {
        let milestones = try await milestoneRepository.fetchByProject(projectID)
        // If alert title mentions a milestone that is now completed, dismiss
        let completedTitles = milestones
            .filter { $0.status == .completed }
            .map { $0.title.lowercased() }

        for title in completedTitles {
            if alert.title.lowercased().contains(title) {
                return true
            }
        }
        return false
    }
}
