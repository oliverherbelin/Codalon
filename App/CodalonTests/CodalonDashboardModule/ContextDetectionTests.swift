// Issue #202 — Context detection rules and state transition tests

import Foundation
import Testing
import HelaiaEngine
@testable import Codalon

// MARK: - Context Detection Rule Tests

@Suite("Context Detection Rules")
@MainActor
struct ContextDetectionRuleTests {

    // MARK: - Default Behavior

    @Test("defaults to development when no signals present")
    func defaultsDevelopment() {
        let input = ContextDetectionInput(hasActiveMilestone: true, hasOpenTasks: true)
        let result = detectContext(from: input)
        #expect(result == .development)
    }

    @Test("defaults to development with active milestone only")
    func developmentWithMilestone() {
        let input = ContextDetectionInput(hasActiveMilestone: true)
        let result = detectContext(from: input)
        #expect(result == .development)
    }

    @Test("defaults to development with open tasks only")
    func developmentWithTasks() {
        let input = ContextDetectionInput(hasOpenTasks: true)
        let result = detectContext(from: input)
        #expect(result == .development)
    }

    // MARK: - Release Detection

    @Test("detects release mode when active release is drafting")
    func detectsReleaseDrafting() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .drafting,
            hasActiveMilestone: true,
            hasOpenTasks: true
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    @Test("detects release mode when status is readyForSubmission")
    func detectsReleaseReadyForSubmission() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .readyForSubmission
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    @Test("detects release mode when status is submitted")
    func detectsReleaseSubmitted() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .submitted
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    @Test("detects release mode when status is inReview")
    func detectsReleaseInReview() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .inReview
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    @Test("detects release mode when status is testing")
    func detectsReleaseTesting() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .testing
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    @Test("detects release mode when status is readyForQA")
    func detectsReleaseReadyForQA() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .readyForQA
        )
        let result = detectContext(from: input)
        #expect(result == .release)
    }

    // MARK: - Non-Active Release Statuses

    @Test("does not detect release mode for released status")
    func releasedStatusNotRelease() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .released,
            hasActiveMilestone: true
        )
        let result = detectContext(from: input)
        #expect(result != .release)
    }

    @Test("does not detect release mode for cancelled status")
    func cancelledStatusNotRelease() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .cancelled,
            hasOpenTasks: true
        )
        let result = detectContext(from: input)
        #expect(result != .release)
    }

    // MARK: - Launch Detection

    @Test("detects launch mode when recent launch present")
    func detectsLaunch() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .drafting,
            hasRecentLaunch: true
        )
        let result = detectContext(from: input)
        #expect(result == .launch)
    }

    @Test("launch takes priority over release")
    func launchPriorityOverRelease() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .readyForSubmission,
            hasRecentLaunch: true,
            hasActiveMilestone: true,
            hasOpenTasks: true
        )
        let result = detectContext(from: input)
        #expect(result == .launch)
    }

    // MARK: - Maintenance Detection

    @Test("detects maintenance when no milestones, tasks, or releases")
    func detectsMaintenance() {
        let input = ContextDetectionInput()
        let result = detectContext(from: input)
        #expect(result == .maintenance)
    }

    @Test("maintenance requires no active release")
    func maintenanceNoRelease() {
        let input = ContextDetectionInput(hasActiveRelease: true, releaseStatus: .released)
        let result = detectContext(from: input)
        // Has active release (even if released), so not maintenance
        #expect(result != .maintenance)
    }

    // MARK: - Edge Cases

    @Test("empty input with no signals returns maintenance")
    func emptyInputMaintenance() {
        let input = ContextDetectionInput()
        let result = detectContext(from: input)
        #expect(result == .maintenance)
    }

    @Test("active release without status returns development")
    func activeReleaseWithoutStatus() {
        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: nil,
            hasOpenTasks: true
        )
        let result = detectContext(from: input)
        #expect(result == .development)
    }
}

// MARK: - Context State Manager Tests

@Suite("ContextStateManager")
@MainActor
struct ContextStateManagerTests {

    let projectID = UUID()

    @Test("initial context is development")
    func initialContext() async {
        let manager = ContextStateManager(projectID: projectID, eventBus: EventBus.shared)
        let ctx = await manager.currentContext()
        #expect(ctx == .development)
    }

    @Test("evaluate updates context based on rules")
    func evaluateUpdatesContext() async {
        let manager = ContextStateManager(projectID: projectID, eventBus: EventBus.shared)

        let input = ContextDetectionInput(
            hasActiveRelease: true,
            releaseStatus: .drafting
        )
        let result = await manager.evaluate(input: input)
        #expect(result == .release)

        let current = await manager.currentContext()
        #expect(current == .release)
    }

    @Test("evaluate does not change context when rules return same value")
    func evaluateNoChangeWhenSame() async {
        let manager = ContextStateManager(projectID: projectID, eventBus: EventBus.shared)

        let input = ContextDetectionInput(hasActiveMilestone: true, hasOpenTasks: true)
        let result = await manager.evaluate(input: input)
        #expect(result == .development)
    }

    @Test("setContext overrides to any context")
    func setContextOverrides() async {
        let manager = ContextStateManager(projectID: projectID, eventBus: EventBus.shared)

        await manager.setContext(.maintenance)
        let ctx = await manager.currentContext()
        #expect(ctx == .maintenance)
    }

    @Test("publishes ContextChangedEvent on change")
    func publishesEvent() async {
        let id = projectID
        let manager = ContextStateManager(projectID: id, eventBus: EventBus.shared)

        var receivedEvents: [ContextChangedEvent] = []
        let token = EventBus.shared.subscribe(to: ContextChangedEvent.self) { event in
            if event.projectID == id {
                receivedEvents.append(event)
            }
        }

        await manager.setContext(.launch)

        // Allow event delivery
        try? await Task.sleep(for: .milliseconds(50))

        #expect(receivedEvents.count == 1)
        #expect(receivedEvents[0].previousContext == .development)
        #expect(receivedEvents[0].newContext == .launch)
        #expect(receivedEvents[0].projectID == id)

        _ = token // retain
    }

    @Test("does not publish event when context unchanged")
    func noEventWhenUnchanged() async {
        let id = projectID
        let manager = ContextStateManager(projectID: id, eventBus: EventBus.shared)

        var receivedEvents: [ContextChangedEvent] = []
        let token = EventBus.shared.subscribe(to: ContextChangedEvent.self) { event in
            if event.projectID == id {
                receivedEvents.append(event)
            }
        }

        // Re-set to development (already the default)
        await manager.setContext(.development)

        try? await Task.sleep(for: .milliseconds(50))

        #expect(receivedEvents.isEmpty)

        _ = token
    }

    @Test("multiple transitions produce multiple events")
    func multipleTransitions() async {
        let id = projectID
        let manager = ContextStateManager(projectID: id, eventBus: EventBus.shared)

        var receivedEvents: [ContextChangedEvent] = []
        let token = EventBus.shared.subscribe(to: ContextChangedEvent.self) { event in
            if event.projectID == id {
                receivedEvents.append(event)
            }
        }

        await manager.setContext(.release)
        try? await Task.sleep(for: .milliseconds(30))

        await manager.setContext(.launch)
        try? await Task.sleep(for: .milliseconds(30))

        await manager.setContext(.maintenance)
        try? await Task.sleep(for: .milliseconds(30))

        #expect(receivedEvents.count == 3)
        #expect(receivedEvents[0].newContext == .release)
        #expect(receivedEvents[1].newContext == .launch)
        #expect(receivedEvents[2].newContext == .maintenance)

        _ = token
    }
}

// MARK: - Reduced Noise Filter Tests

@Suite("ReducedNoiseFilter")
@MainActor
struct ReducedNoiseFilterTests {

    @Test("all widgets visible when reduced noise off")
    func allVisibleWhenOff() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "insights",
            context: .development,
            reducedNoise: false
        )
        #expect(visible == true)
    }

    @Test("low priority hidden when reduced noise on in development")
    func lowPriorityHiddenDev() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "alerts",
            context: .development,
            reducedNoise: true
        )
        #expect(visible == false)
    }

    @Test("essential widgets visible when reduced noise on")
    func essentialVisibleDev() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "milestoneFocus",
            context: .development,
            reducedNoise: true
        )
        #expect(visible == true)
    }

    @Test("standard widgets visible when reduced noise on")
    func standardVisibleDev() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "attention",
            context: .development,
            reducedNoise: true
        )
        #expect(visible == true)
    }

    @Test("release context keeps alerts visible in focus mode")
    func releaseAlertsVisible() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "alerts",
            context: .release,
            reducedNoise: true
        )
        #expect(visible == true)
    }

    @Test("release context hides insights in focus mode")
    func releaseInsightsHidden() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "insights",
            context: .release,
            reducedNoise: true
        )
        #expect(visible == false)
    }

    @Test("unknown widget defaults to standard priority")
    func unknownWidgetStandard() {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: "unknownWidget",
            context: .development,
            reducedNoise: true
        )
        #expect(visible == true)
    }
}

// MARK: - Sidebar Config Tests

@Suite("ContextSidebarConfig")
@MainActor
struct ContextSidebarConfigTests {

    @Test("development highlights dashboard, milestones, tasks")
    func devHighlights() {
        let sections = ContextSidebarConfig.sections(for: .development)
        let highlighted = sections.filter(\.isHighlighted).map(\.id)
        #expect(highlighted.contains("dashboard"))
        #expect(highlighted.contains("milestones"))
        #expect(highlighted.contains("tasks"))
    }

    @Test("release highlights releases, appstore, github")
    func releaseHighlights() {
        let sections = ContextSidebarConfig.sections(for: .release)
        let highlighted = sections.filter(\.isHighlighted).map(\.id)
        #expect(highlighted.contains("releases"))
        #expect(highlighted.contains("appstore"))
        #expect(highlighted.contains("github"))
    }

    @Test("launch highlights appstore, alerts, insights")
    func launchHighlights() {
        let sections = ContextSidebarConfig.sections(for: .launch)
        let highlighted = sections.filter(\.isHighlighted).map(\.id)
        #expect(highlighted.contains("appstore"))
        #expect(highlighted.contains("alerts"))
        #expect(highlighted.contains("insights"))
    }

    @Test("maintenance highlights insights")
    func maintenanceHighlights() {
        let sections = ContextSidebarConfig.sections(for: .maintenance)
        let highlighted = sections.filter(\.isHighlighted).map(\.id)
        #expect(highlighted.contains("insights"))
    }

    @Test("all contexts include dashboard as first section")
    func dashboardFirst() {
        for context in CodalonContext.allCases {
            let sections = ContextSidebarConfig.sections(for: context)
            #expect(sections.first?.id == "dashboard")
        }
    }

    @Test("all contexts include settings as last section")
    func settingsLast() {
        for context in CodalonContext.allCases {
            let sections = ContextSidebarConfig.sections(for: context)
            #expect(sections.last?.id == "settings")
        }
    }
}

// MARK: - Action Config Tests

@Suite("ContextActionConfig")
@MainActor
struct ContextActionConfigTests {

    @Test("each context has exactly one primary action")
    func onePrimaryPerContext() {
        for context in CodalonContext.allCases {
            let actions = ContextActionConfig.actions(for: context)
            let primaryCount = actions.filter(\.isPrimary).count
            #expect(primaryCount == 1, "Expected 1 primary action for \(context.displayName), got \(primaryCount)")
        }
    }

    @Test("development primary is newTask")
    func devPrimary() {
        let actions = ContextActionConfig.actions(for: .development)
        let primary = actions.first(where: \.isPrimary)
        #expect(primary?.id == "newTask")
    }

    @Test("release primary is submitBuild")
    func releasePrimary() {
        let actions = ContextActionConfig.actions(for: .release)
        let primary = actions.first(where: \.isPrimary)
        #expect(primary?.id == "submitBuild")
    }

    @Test("launch primary is viewReviews")
    func launchPrimary() {
        let actions = ContextActionConfig.actions(for: .launch)
        let primary = actions.first(where: \.isPrimary)
        #expect(primary?.id == "viewReviews")
    }

    @Test("maintenance primary is newBugfix")
    func maintenancePrimary() {
        let actions = ContextActionConfig.actions(for: .maintenance)
        let primary = actions.first(where: \.isPrimary)
        #expect(primary?.id == "newBugfix")
    }
}
