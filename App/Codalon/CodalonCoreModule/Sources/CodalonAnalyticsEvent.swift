// Issues #227, #228, #229, #230, #231, #232, #233, #234 — Analytics event taxonomy

import Foundation
import HelaiaAnalytics

/// Codalon-specific analytics event constructors.
/// Provides static factory methods for creating properly configured analytics events.
nonisolated public enum CodalonAnalyticsEvent {

    // MARK: - Issue #228 — Project events

    /// Records when a new project is created.
    nonisolated public static func projectCreated(
        platform: String,
        projectType: String,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "project_created",
            category: .featureUsage,
            properties: [
                "platform": platform,
                "project_type": projectType
            ],
            sessionID: sessionID
        )
    }

    /// Records when a project is deleted.
    nonisolated public static func projectDeleted(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "project_deleted",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #229 — Task events

    /// Records when a new task is created.
    nonisolated public static func taskCreated(
        priority: String,
        hasGithubRef: Bool,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "task_created",
            category: .featureUsage,
            properties: [
                "priority": priority,
                "has_github_ref": String(hasGithubRef)
            ],
            sessionID: sessionID
        )
    }

    /// Records when a task's status changes.
    nonisolated public static func taskStatusChanged(
        from: String,
        to: String,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "task_status_changed",
            category: .featureUsage,
            properties: [
                "from_status": from,
                "to_status": to
            ],
            sessionID: sessionID
        )
    }

    /// Records when a task is completed.
    nonisolated public static func taskCompleted(
        priority: String,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "task_completed",
            category: .featureUsage,
            properties: [
                "priority": priority
            ],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #230 — Milestone events

    /// Records when a new milestone is created.
    nonisolated public static func milestoneCreated(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "milestone_created",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when a milestone is completed.
    nonisolated public static func milestoneCompleted(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "milestone_completed",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when an overdue milestone is detected.
    nonisolated public static func milestoneOverdueDetected(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "milestone_overdue_detected",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #231 — Release cockpit events

    /// Records when the release cockpit is opened.
    nonisolated public static func releaseCockpitOpened(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "release_cockpit_opened",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when a release checklist item is toggled.
    nonisolated public static func releaseChecklistToggled(
        item: String,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "release_checklist_toggled",
            category: .userAction,
            properties: [
                "item": item
            ],
            sessionID: sessionID
        )
    }

    /// Records when a release blocker is resolved.
    nonisolated public static func releaseBlockerResolved(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "release_blocker_resolved",
            category: .userAction,
            properties: [:],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #232 — GitHub integration events

    /// Records when GitHub is connected.
    nonisolated public static func githubConnected(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "github_connected",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when a GitHub issue is created from within Codalon.
    nonisolated public static func githubIssueCreated(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "github_issue_created",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when a GitHub sync is triggered.
    nonisolated public static func githubSyncTriggered(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "github_sync_triggered",
            category: .sync,
            properties: [:],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #233 — ASC integration events

    /// Records when App Store Connect is connected.
    nonisolated public static func ascConnected(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "asc_connected",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when App Store Connect metadata is viewed.
    nonisolated public static func ascMetadataViewed(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "asc_metadata_viewed",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when App Store Connect release notes are updated.
    nonisolated public static func ascReleaseNotesUpdated(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "asc_release_notes_updated",
            category: .userAction,
            properties: [:],
            sessionID: sessionID
        )
    }

    // MARK: - Issue #234 — Insight events

    /// Records when the insight panel is opened.
    nonisolated public static func insightPanelOpened(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "insight_panel_opened",
            category: .featureUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when an AI insight is requested.
    nonisolated public static func aiInsightRequested(sessionID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "ai_insight_requested",
            category: .aiUsage,
            properties: [:],
            sessionID: sessionID
        )
    }

    /// Records when a rule-based insight is generated.
    nonisolated public static func ruleInsightGenerated(
        ruleName: String,
        sessionID: UUID
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "rule_insight_generated",
            category: .featureUsage,
            properties: [
                "rule_name": ruleName
            ],
            sessionID: sessionID
        )
    }
}