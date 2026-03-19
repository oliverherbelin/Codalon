// Issue #235 — Preview analytics service for SwiftUI previews

import Foundation
import HelaiaAnalytics

// MARK: - PreviewAnalyticsService

/// Preview-only analytics service that returns sample data.
actor PreviewAnalyticsService: CodalonAnalyticsServiceProtocol {

    func track(_ event: AnalyticsEvent) async {}

    func summary(period: AnalyticsPeriod) async -> AnalyticsSummary {
        AnalyticsSummary(
            period: period,
            totalEvents: 342,
            eventsByCategory: [
                .featureUsage: 178,
                .userAction: 89,
                .navigation: 45,
                .sync: 18,
                .aiUsage: 12,
            ],
            topFeatures: [
                (name: "project_created", count: 34),
                (name: "task_completed", count: 28),
                (name: "release_cockpit_opened", count: 19),
                (name: "github_sync_triggered", count: 15),
                (name: "insight_panel_opened", count: 11),
            ],
            activeDays: 14
        )
    }

    func allEvents() async -> [AnalyticsEvent] {
        let sessionID = UUID()
        return [
            CodalonAnalyticsEvent.projectCreated(
                platform: "macOS", projectType: "app", sessionID: sessionID
            ),
            CodalonAnalyticsEvent.taskCompleted(
                priority: "high", sessionID: sessionID
            ),
            CodalonAnalyticsEvent.githubSyncTriggered(sessionID: sessionID),
            CodalonAnalyticsEvent.releaseCockpitOpened(sessionID: sessionID),
            CodalonAnalyticsEvent.aiInsightRequested(sessionID: sessionID),
        ]
    }

    func clear() async {}
}
