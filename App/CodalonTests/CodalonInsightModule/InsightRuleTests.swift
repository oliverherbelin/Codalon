// Issues #163, #165, #167, #170, #172, #174 — Insight rule tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Insight Rule Tests

@Suite("InsightRules")
@MainActor
struct InsightRuleTests {

    let projectID = UUID()

    // MARK: - Issue #163 — Overdue Milestones

    @Test("detects overdue milestone")
    func overdueMilestone() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Beta",
            dueDate: Date().addingTimeInterval(-86400 * 3),
            status: .active
        )
        let context = InsightRuleContext(
            projectID: projectID,
            milestones: [milestone]
        )
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.title.contains("Beta") == true)
    }

    @Test("ignores completed milestone")
    func completedMilestoneNotOverdue() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Beta",
            dueDate: Date().addingTimeInterval(-86400),
            status: .completed
        )
        let context = InsightRuleContext(
            projectID: projectID,
            milestones: [milestone]
        )
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Issue #165 — Overdue Tasks

    @Test("detects overdue tasks")
    func overdueTasks() async {
        let tasks = [
            CodalonTask(
                projectID: projectID,
                title: "Fix crash",
                status: .inProgress,
                dueDate: Date().addingTimeInterval(-86400 * 2)
            ),
            CodalonTask(
                projectID: projectID,
                title: "Write docs",
                status: .todo,
                dueDate: Date().addingTimeInterval(-86400)
            ),
        ]
        let context = InsightRuleContext(
            projectID: projectID,
            tasks: tasks
        )
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.title.contains("2") == true)
    }

    @Test("no overdue tasks returns empty")
    func noOverdueTasks() async {
        let tasks = [
            CodalonTask(
                projectID: projectID,
                title: "Future task",
                status: .todo,
                dueDate: Date().addingTimeInterval(86400 * 7)
            ),
        ]
        let context = InsightRuleContext(projectID: projectID, tasks: tasks)
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Issue #167 — Blocked Releases

    @Test("detects release with blockers near target")
    func blockedRelease() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400 * 3),
            status: .drafting,
            blockerCount: 2,
            blockers: [
                CodalonReleaseBlocker(title: "Bug", severity: .critical),
                CodalonReleaseBlocker(title: "Crash", severity: .error),
            ]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.severity == .warning)
    }

    @Test("does not flag released release")
    func releasedReleaseNotFlagged() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .released,
            blockerCount: 1,
            blockers: [CodalonReleaseBlocker(title: "Old bug")]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Issue #170 — Stale GitHub Issues

    @Test("detects stale linked issues")
    func staleGitHubIssues() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            linkedGitHubIssueRefs: ["owner/repo#1", "owner/repo#2"]
        )
        var staleRelease = release
        staleRelease.updatedAt = Date().addingTimeInterval(-86400 * 35)

        let context = InsightRuleContext(projectID: projectID, releases: [staleRelease])
        let rule = StaleGitHubIssueRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.title.contains("2 linked issue") == true)
    }

    // MARK: - Issue #172 — Missing ASC Metadata

    @Test("detects incomplete checklist with ASC build")
    func missingASCMetadata() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .readyForSubmission,
            checklistItems: [
                CodalonChecklistItem(title: "Screenshots", isComplete: true),
                CodalonChecklistItem(title: "Metadata complete", isComplete: false),
            ],
            linkedASCBuildRef: "com.example/1.0/42"
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = MissingASCMetadataRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.severity == .warning)
    }

    // MARK: - Issue #174 — Too Many Critical Alerts

    @Test("flags when more than 3 unread critical alerts")
    func tooManyCriticalAlerts() async {
        let alerts = (0..<5).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "Something critical"
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.severity == .critical)
    }

    @Test("does not flag with 3 or fewer critical alerts")
    func fewCriticalAlerts() async {
        let alerts = (0..<3).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "Something"
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }
}
