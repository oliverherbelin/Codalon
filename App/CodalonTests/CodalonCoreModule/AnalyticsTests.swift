// Issue #236 — Add analytics tests:
// Unit tests confirming correct events fire on key user actions.

import Foundation
import Testing
import HelaiaAnalytics
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let testSessionID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

// MARK: - Mock Analytics Service

private actor MockAnalyticsService: CodalonAnalyticsServiceProtocol {
    var tracked: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) async {
        tracked.append(event)
    }

    func summary(period: AnalyticsPeriod) async -> AnalyticsSummary {
        AnalyticsSummary(
            period: period,
            totalEvents: tracked.count,
            eventsByCategory: [:],
            topFeatures: [],
            activeDays: 0
        )
    }

    func allEvents() async -> [AnalyticsEvent] {
        tracked
    }

    func clear() async {
        tracked.removeAll()
    }
}

// MARK: - CodalonAnalyticsEvent Tests

@Suite("CodalonAnalyticsEvent Factory Methods")
@MainActor
struct CodalonAnalyticsEventTests {

    @Test("projectCreated returns correct name, category, and properties")
    func projectCreatedEvent() {
        let event = CodalonAnalyticsEvent.projectCreated(
            platform: "macOS",
            projectType: "app",
            sessionID: testSessionID
        )

        #expect(event.name == "project_created")
        #expect(event.category == .featureUsage)
        #expect(event.properties["platform"] == "macOS")
        #expect(event.properties["project_type"] == "app")
        #expect(event.sessionID == testSessionID)
    }

    @Test("taskCreated returns correct properties with hasGithubRef as string")
    func taskCreatedEvent() {
        let eventWithGitHub = CodalonAnalyticsEvent.taskCreated(
            priority: "high",
            hasGithubRef: true,
            sessionID: testSessionID
        )

        #expect(eventWithGitHub.name == "task_created")
        #expect(eventWithGitHub.category == .featureUsage)
        #expect(eventWithGitHub.properties["priority"] == "high")
        #expect(eventWithGitHub.properties["has_github_ref"] == "true")

        let eventWithoutGitHub = CodalonAnalyticsEvent.taskCreated(
            priority: "low",
            hasGithubRef: false,
            sessionID: testSessionID
        )

        #expect(eventWithoutGitHub.properties["has_github_ref"] == "false")
    }

    @Test("taskStatusChanged returns correct from and to properties")
    func taskStatusChangedEvent() {
        let event = CodalonAnalyticsEvent.taskStatusChanged(
            from: "todo",
            to: "inProgress",
            sessionID: testSessionID
        )

        #expect(event.name == "task_status_changed")
        #expect(event.category == .featureUsage)
        #expect(event.properties["from_status"] == "todo")
        #expect(event.properties["to_status"] == "inProgress")
        #expect(event.sessionID == testSessionID)
    }

    @Test("milestoneCreated returns category featureUsage")
    func milestoneCreatedEvent() {
        let event = CodalonAnalyticsEvent.milestoneCreated(sessionID: testSessionID)

        #expect(event.name == "milestone_created")
        #expect(event.category == .featureUsage)
        #expect(event.sessionID == testSessionID)
    }

    @Test("githubConnected returns category featureUsage")
    func githubConnectedEvent() {
        let event = CodalonAnalyticsEvent.githubConnected(sessionID: testSessionID)

        #expect(event.name == "github_connected")
        #expect(event.category == .featureUsage)
        #expect(event.sessionID == testSessionID)
    }

    @Test("githubSyncTriggered returns category sync")
    func githubSyncTriggeredEvent() {
        let event = CodalonAnalyticsEvent.githubSyncTriggered(sessionID: testSessionID)

        #expect(event.name == "github_sync_triggered")
        #expect(event.category == .sync)
        #expect(event.sessionID == testSessionID)
    }

    @Test("aiInsightRequested returns category aiUsage")
    func aiInsightRequestedEvent() {
        let event = CodalonAnalyticsEvent.aiInsightRequested(sessionID: testSessionID)

        #expect(event.name == "ai_insight_requested")
        #expect(event.category == .aiUsage)
        #expect(event.sessionID == testSessionID)
    }

    @Test("releaseChecklistToggled returns category userAction")
    func releaseChecklistToggledEvent() {
        let event = CodalonAnalyticsEvent.releaseChecklistToggled(
            item: "screenshots",
            sessionID: testSessionID
        )

        #expect(event.name == "release_checklist_toggled")
        #expect(event.category == .userAction)
        #expect(event.properties["item"] == "screenshots")
        #expect(event.sessionID == testSessionID)
    }

    @Test("ascReleaseNotesUpdated returns category userAction")
    func ascReleaseNotesUpdatedEvent() {
        let event = CodalonAnalyticsEvent.ascReleaseNotesUpdated(sessionID: testSessionID)

        #expect(event.name == "asc_release_notes_updated")
        #expect(event.category == .userAction)
        #expect(event.sessionID == testSessionID)
    }
}

// MARK: - CodalonAnalyticsService Tests

@Suite("CodalonAnalyticsService Integration")
@MainActor
struct CodalonAnalyticsServiceTests {

    @Test("mock service tracks events correctly")
    func mockServiceTracksEvents() async {
        let mockService = MockAnalyticsService()

        let event = CodalonAnalyticsEvent.projectCreated(
            platform: "iOS",
            projectType: "app",
            sessionID: testSessionID
        )

        await mockService.track(event)

        let trackedEvents = await mockService.allEvents()
        #expect(trackedEvents.count == 1)
        #expect(trackedEvents.first?.name == "project_created")
    }

    @Test("mock service summary returns correct aggregate data")
    func mockServiceSummary() async {
        let mockService = MockAnalyticsService()

        // Track multiple events
        await mockService.track(CodalonAnalyticsEvent.projectCreated(
            platform: "macOS",
            projectType: "app",
            sessionID: testSessionID
        ))
        await mockService.track(CodalonAnalyticsEvent.taskCreated(
            priority: "high",
            hasGithubRef: true,
            sessionID: testSessionID
        ))

        let summary = await mockService.summary(period: .today)
        #expect(summary.period == .today)
        #expect(summary.totalEvents == 2)
    }

    @Test("mock service clear removes all events")
    func mockServiceClear() async {
        let mockService = MockAnalyticsService()

        await mockService.track(CodalonAnalyticsEvent.milestoneCreated(sessionID: testSessionID))

        var events = await mockService.allEvents()
        #expect(events.count == 1)

        await mockService.clear()

        events = await mockService.allEvents()
        #expect(events.count == 0)
    }

    @Test("mock service allEvents returns tracked events")
    func mockServiceAllEvents() async {
        let mockService = MockAnalyticsService()

        let event1 = CodalonAnalyticsEvent.githubConnected(sessionID: testSessionID)
        let event2 = CodalonAnalyticsEvent.aiInsightRequested(sessionID: testSessionID)

        await mockService.track(event1)
        await mockService.track(event2)

        let allEvents = await mockService.allEvents()
        #expect(allEvents.count == 2)
        #expect(allEvents.contains { $0.name == "github_connected" })
        #expect(allEvents.contains { $0.name == "ai_insight_requested" })
    }
}