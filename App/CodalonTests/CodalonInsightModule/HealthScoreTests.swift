// Issues #160, #162 — Health score dimension and calculator tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Health Score Dimension Tests

@Suite("HealthScoreDimensions")
@MainActor
struct HealthScoreDimensionTests {

    @Test("dimension value is clamped 0–1")
    func valueClamped() {
        let over = HealthScoreDimension(id: "test", label: "Test", value: 1.5)
        #expect(over.value == 1.0)

        let under = HealthScoreDimension(id: "test", label: "Test", value: -0.3)
        #expect(under.value == 0.0)
    }

    @Test("planning health with no tasks is 0")
    func planningHealthNoTasks() {
        let score = PlanningHealthCalculator.calculate(
            totalTasks: 0,
            completedTasks: 0,
            overdueTasks: 0,
            milestoneProgress: 0
        )
        #expect(score == 0)
    }

    @Test("planning health with all done and no overdue")
    func planningHealthAllDone() {
        let score = PlanningHealthCalculator.calculate(
            totalTasks: 10,
            completedTasks: 10,
            overdueTasks: 0,
            milestoneProgress: 1.0
        )
        #expect(score == 1.0)
    }

    @Test("planning health with half done and some overdue")
    func planningHealthHalfDone() {
        let score = PlanningHealthCalculator.calculate(
            totalTasks: 10,
            completedTasks: 5,
            overdueTasks: 2,
            milestoneProgress: 0.5
        )
        // 0.5*0.4 + 0.8*0.3 + 0.5*0.3 = 0.2 + 0.24 + 0.15 = 0.59
        #expect(score > 0.58 && score < 0.60)
    }

    @Test("release health with high readiness and no blockers")
    func releaseHealthGood() {
        let score = ReleaseHealthCalculator.calculate(
            readinessScore: 90,
            blockerCount: 0,
            hasTargetDate: true
        )
        #expect(score > 0.9)
    }

    @Test("release health with blockers reduces score")
    func releaseHealthWithBlockers() {
        let score = ReleaseHealthCalculator.calculate(
            readinessScore: 80,
            blockerCount: 3,
            hasTargetDate: true
        )
        // 0.8 - 0.45 + 0.05 = 0.4
        #expect(score < 0.5)
    }

    @Test("github health with no open items is 1.0")
    func githubHealthNoIssues() {
        let score = GitHubHealthCalculator.calculate(
            openIssueCount: 0,
            staleIssueCount: 0,
            openPRCount: 0,
            stalePRCount: 0
        )
        #expect(score == 1.0)
    }

    @Test("github health decreases with stale items")
    func githubHealthStale() {
        let score = GitHubHealthCalculator.calculate(
            openIssueCount: 10,
            staleIssueCount: 5,
            openPRCount: 0,
            stalePRCount: 0
        )
        #expect(score == 0.5)
    }

    @Test("store health with all indicators")
    func storeHealthFull() {
        let score = StoreHealthCalculator.calculate(
            hasRecentReview: true,
            crashFreeRate: 0.99,
            metadataComplete: true
        )
        // 0.2 + 0.495 + 0.3 = 0.995
        #expect(score > 0.99)
    }
}
