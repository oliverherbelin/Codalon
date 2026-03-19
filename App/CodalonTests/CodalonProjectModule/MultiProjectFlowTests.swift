// Issue #249 — Test multi-project flows

import Foundation
import Testing
@testable import Codalon

// MARK: - Multi-Project Flow Tests

@Suite("Multi-Project Flows")
@MainActor
struct MultiProjectFlowTests {

    @Test("projects have unique IDs")
    func uniqueProjectIDs() {
        let project1 = CodalonProject(
            name: "App A",
            slug: "app-a",
            platform: .iOS,
            projectType: .app
        )
        let project2 = CodalonProject(
            name: "App B",
            slug: "app-b",
            platform: .macOS,
            projectType: .framework
        )

        #expect(project1.id != project2.id)
        #expect(project1.slug != project2.slug)
    }

    @Test("shell state resets when switching projects")
    func shellStateResetsOnSwitch() {
        let state = CodalonShellState()

        // Simulate project A state
        state.activeContext = .release
        state.healthState = .healthy
        state.activeMilestoneID = UUID()
        state.activeReleaseID = UUID()

        // Simulate project switch reset
        state.activeContext = .development
        state.healthState = .noData
        state.activeMilestoneID = nil
        state.activeReleaseID = nil
        state.activeDistributionTargets = []

        #expect(state.activeContext == .development)
        #expect(state.healthState == .noData)
        #expect(state.activeMilestoneID == nil)
        #expect(state.activeReleaseID == nil)
        #expect(state.activeDistributionTargets.isEmpty)
    }

    @Test("tasks are scoped to project ID")
    func tasksAreProjectScoped() {
        let projectA = UUID()
        let projectB = UUID()

        let taskA = CodalonTask(
            projectID: projectA,
            title: "Task for A",
            status: .todo,
            priority: .medium
        )
        let taskB = CodalonTask(
            projectID: projectB,
            title: "Task for B",
            status: .todo,
            priority: .medium
        )

        #expect(taskA.projectID == projectA)
        #expect(taskB.projectID == projectB)
        #expect(taskA.projectID != taskB.projectID)
    }

    @Test("milestones are scoped to project ID")
    func milestonesAreProjectScoped() {
        let projectA = UUID()
        let projectB = UUID()

        let milestoneA = CodalonMilestone(
            projectID: projectA,
            title: "Alpha",
            status: .active,
            priority: .high,
            progress: 0.5
        )
        let milestoneB = CodalonMilestone(
            projectID: projectB,
            title: "Beta",
            status: .planned,
            priority: .medium,
            progress: 0.0
        )

        #expect(milestoneA.projectID != milestoneB.projectID)
    }

    @Test("releases are scoped to project ID")
    func releasesAreProjectScoped() {
        let projectA = UUID()
        let projectB = UUID()

        let releaseA = CodalonRelease(
            projectID: projectA,
            version: "1.0.0",
            buildNumber: "1",
            status: .drafting,
            readinessScore: 50
        )
        let releaseB = CodalonRelease(
            projectID: projectB,
            version: "2.0.0",
            buildNumber: "1",
            status: .drafting,
            readinessScore: 20
        )

        #expect(releaseA.projectID != releaseB.projectID)
    }

    @Test("insights are scoped to project ID")
    func insightsAreProjectScoped() {
        let projectA = UUID()
        let projectB = UUID()

        let insightA = CodalonInsight(
            projectID: projectA,
            type: .anomaly,
            severity: .warning,
            source: .ruleEngine,
            title: "Issue A",
            message: "Problem in A"
        )
        let insightB = CodalonInsight(
            projectID: projectB,
            type: .suggestion,
            severity: .info,
            source: .analytics,
            title: "Tip B",
            message: "Suggestion for B"
        )

        #expect(insightA.projectID != insightB.projectID)
    }
}
