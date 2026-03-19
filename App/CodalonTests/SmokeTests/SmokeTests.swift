// Issue #246 — Automated smoke test suite

import Foundation
import Testing
@testable import Codalon

// MARK: - App Launch Smoke Tests

@Suite("Smoke — App Bootstrap")
@MainActor
struct AppBootstrapSmokeTests {

    @Test("CodalonShellState initializes with development context")
    func shellStateDefaults() {
        let state = CodalonShellState()

        #expect(state.activeContext == .development)
        #expect(state.healthState == .noData)
        #expect(state.activeMilestoneID == nil)
        #expect(state.activeReleaseID == nil)
        #expect(state.activeDistributionTargets.isEmpty)
        #expect(state.isInspectorVisible == false)
        #expect(state.isProjectSwitcherVisible == false)
    }

    @Test("CodalonContext has all four cases")
    func contextCases() {
        let contexts: [CodalonContext] = [.development, .release, .launch, .maintenance]
        #expect(contexts.count == 4)
        for context in contexts {
            #expect(!context.displayName.isEmpty)
            #expect(!context.iconName.isEmpty)
        }
    }
}

// MARK: - Project Creation Smoke Tests

@Suite("Smoke — Project Creation")
@MainActor
struct ProjectCreationSmokeTests {

    @Test("CodalonProject creates with required fields")
    func createProject() {
        let project = CodalonProject(
            name: "Test App",
            slug: "test-app",
            platform: .macOS,
            projectType: .app
        )

        #expect(project.name == "Test App")
        #expect(project.slug == "test-app")
        #expect(project.platform == .macOS)
        #expect(project.projectType == .app)
        #expect(project.deletedAt == nil)
    }

    @Test("ProjectSummary initializes correctly")
    func projectSummary() {
        let summary = ProjectSummary(
            projectID: UUID(),
            openTaskCount: 5,
            milestoneCount: 2,
            activeReleaseVersion: "1.0.0",
            healthScore: 0.8
        )

        #expect(summary.openTaskCount == 5)
        #expect(summary.milestoneCount == 2)
        #expect(summary.activeReleaseVersion == "1.0.0")
        #expect(summary.healthScore == 0.8)
    }
}

// MARK: - Dashboard Smoke Tests

@Suite("Smoke — Dashboard")
@MainActor
struct DashboardSmokeTests {

    @Test("ReducedNoiseFilter returns correct visibility")
    func reducedNoiseFilterVisibility() {
        // Essential widgets visible in reduced noise
        let essential = ReducedNoiseFilter.isVisible(
            widgetID: "milestoneFocus",
            context: .development,
            reducedNoise: true
        )
        #expect(essential == true)

        // Low-priority widgets hidden in reduced noise
        let lowPri = ReducedNoiseFilter.isVisible(
            widgetID: "alerts",
            context: .development,
            reducedNoise: true
        )
        #expect(lowPri == false)

        // All widgets visible when reduced noise is off
        let noFilter = ReducedNoiseFilter.isVisible(
            widgetID: "alerts",
            context: .development,
            reducedNoise: false
        )
        #expect(noFilter == true)
    }

    @Test("WidgetPriority ordering is correct")
    func widgetPriorityOrdering() {
        #expect(WidgetPriority.lowPriority < .standard)
        #expect(WidgetPriority.standard < .essential)
    }
}

// MARK: - GitHub Connection Smoke Tests

@Suite("Smoke — GitHub Connection")
@MainActor
struct GitHubConnectionSmokeTests {

    @Test("GitHubConnectionStatus has expected cases")
    func connectionStatusCases() {
        let connected = GitHubConnectionStatus.connected(username: "test")
        let notConnected = GitHubConnectionStatus.notConnected
        let expired = GitHubConnectionStatus.tokenExpired

        #expect(connected != notConnected)
        #expect(notConnected != expired)
    }
}
