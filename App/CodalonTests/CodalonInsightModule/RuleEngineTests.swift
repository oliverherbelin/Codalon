// Issue #182 — Rule engine tests: every detection rule + edge cases

import Foundation
import Testing
import HelaiaLogger
@testable import Codalon

// MARK: - Mock Repositories

private actor MockTaskRepo: TaskRepositoryProtocol {
    var tasks: [CodalonTask] = []
    func save(_ task: CodalonTask) async throws {}
    func load(id: UUID) async throws -> CodalonTask { tasks[0] }
    func loadAll() async throws -> [CodalonTask] { tasks }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] {
        tasks.filter { $0.projectID == projectID }
    }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
}

private actor MockMilestoneRepo: MilestoneRepositoryProtocol {
    var milestones: [CodalonMilestone] = []
    func save(_ milestone: CodalonMilestone) async throws {}
    func load(id: UUID) async throws -> CodalonMilestone { milestones[0] }
    func loadAll() async throws -> [CodalonMilestone] { milestones }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        milestones.filter { $0.projectID == projectID }
    }
    func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone] { [] }
    func fetchOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private actor MockReleaseRepo: ReleaseRepositoryProtocol {
    var releases: [CodalonRelease] = []
    func save(_ release: CodalonRelease) async throws {}
    func load(id: UUID) async throws -> CodalonRelease { releases[0] }
    func loadAll() async throws -> [CodalonRelease] { releases }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] {
        releases.filter { $0.projectID == projectID }
    }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? { nil }
    func fetchByStatus(_ status: CodalonReleaseStatus, projectID: UUID) async throws -> [CodalonRelease] { [] }
}

private actor MockAlertRepo: AlertRepositoryProtocol {
    var alerts: [CodalonAlert] = []
    func save(_ alert: CodalonAlert) async throws {}
    func load(id: UUID) async throws -> CodalonAlert { alerts[0] }
    func loadAll() async throws -> [CodalonAlert] { alerts }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID }
    }
    func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] { [] }
    func fetchByCategory(_ category: CodalonAlertCategory, projectID: UUID) async throws -> [CodalonAlert] { [] }
    func markRead(id: UUID) async throws {}
    func dismiss(id: UUID) async throws {}
}

private actor MockInsightRepo: InsightRepositoryProtocol {
    var insights: [CodalonInsight] = []
    func save(_ insight: CodalonInsight) async throws {
        insights.append(insight)
    }
    func load(id: UUID) async throws -> CodalonInsight { insights[0] }
    func loadAll() async throws -> [CodalonInsight] { insights }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight] {
        insights.filter { $0.projectID == projectID }
    }
    func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] { [] }
    func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] { [] }
}

// MARK: - Tests

@Suite("RuleEngineTests")
@MainActor
struct RuleEngineTests {

    let projectID = UUID()

    // MARK: - Edge Case: Empty Project

    @Test("empty project produces no insights from any rule")
    func emptyProjectNoInsights() async {
        let context = InsightRuleContext(projectID: projectID)

        let rules: [any InsightRuleProtocol] = [
            OverdueMilestoneRule(),
            OverdueTaskRule(),
            BlockedReleaseRule(),
            StaleGitHubIssueRule(),
            MissingASCMetadataRule(),
            TooManyCriticalAlertsRule(),
        ]

        for rule in rules {
            let results = await rule.evaluate(context: context)
            #expect(results.isEmpty, "Rule \(rule.ruleID) should produce nothing for empty project")
        }
    }

    // MARK: - Edge Case: No Linked Repos (StaleGitHubIssueRule)

    @Test("no linked GitHub issues produces no insight")
    func noLinkedRepos() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            linkedGitHubIssueRefs: []
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = StaleGitHubIssueRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("linked issues on recently updated release are not stale")
    func recentlyUpdatedRelease() async {
        let release = CodalonRelease(
            updatedAt: Date(),
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            linkedGitHubIssueRefs: ["owner/repo#1"]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = StaleGitHubIssueRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Edge Case: No ASC (MissingASCMetadataRule)

    @Test("release without ASC build ref produces no metadata insight")
    func noASCBuildRef() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .readyForSubmission,
            checklistItems: [
                CodalonChecklistItem(title: "Incomplete", isComplete: false),
            ]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = MissingASCMetadataRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("release with ASC ref but complete checklist produces no insight")
    func completeChecklist() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .readyForSubmission,
            checklistItems: [
                CodalonChecklistItem(title: "Done", isComplete: true),
            ],
            linkedASCBuildRef: "com.example/1.0/42"
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = MissingASCMetadataRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("release with ASC ref and empty checklist produces no insight")
    func emptyChecklist() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .readyForSubmission,
            checklistItems: [],
            linkedASCBuildRef: "com.example/1.0/42"
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = MissingASCMetadataRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - OverdueMilestoneRule Edge Cases

    @Test("milestone without due date is never overdue")
    func milestoneNoDueDate() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "No Due Date",
            dueDate: nil,
            status: .active
        )
        let context = InsightRuleContext(projectID: projectID, milestones: [milestone])
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("cancelled milestone is not flagged")
    func cancelledMilestone() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Cancelled",
            dueDate: Date().addingTimeInterval(-86400 * 10),
            status: .cancelled
        )
        let context = InsightRuleContext(projectID: projectID, milestones: [milestone])
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("deleted milestone is not flagged")
    func deletedMilestone() async {
        var milestone = CodalonMilestone(
            projectID: projectID,
            title: "Deleted",
            dueDate: Date().addingTimeInterval(-86400 * 5),
            status: .active
        )
        milestone.deletedAt = Date()
        let context = InsightRuleContext(projectID: projectID, milestones: [milestone])
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("milestone overdue >7 days gets warning severity")
    func milestoneOverdueSeverity() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Very Overdue",
            dueDate: Date().addingTimeInterval(-86400 * 10),
            status: .active
        )
        let context = InsightRuleContext(projectID: projectID, milestones: [milestone])
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results[0].severity == .warning)
    }

    @Test("milestone overdue <=7 days gets info severity")
    func milestoneOverdueInfoSeverity() async {
        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Slightly Overdue",
            dueDate: Date().addingTimeInterval(-86400 * 3),
            status: .active
        )
        let context = InsightRuleContext(projectID: projectID, milestones: [milestone])
        let rule = OverdueMilestoneRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results[0].severity == .info)
    }

    // MARK: - OverdueTaskRule Edge Cases

    @Test("done tasks are not flagged as overdue")
    func doneTasksNotOverdue() async {
        let task = CodalonTask(
            projectID: projectID,
            title: "Done Task",
            status: .done,
            dueDate: Date().addingTimeInterval(-86400 * 5)
        )
        let context = InsightRuleContext(projectID: projectID, tasks: [task])
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("cancelled tasks are not flagged as overdue")
    func cancelledTasksNotOverdue() async {
        let task = CodalonTask(
            projectID: projectID,
            title: "Cancelled",
            status: .cancelled,
            dueDate: Date().addingTimeInterval(-86400 * 5)
        )
        let context = InsightRuleContext(projectID: projectID, tasks: [task])
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("deleted tasks are not flagged")
    func deletedTasksNotOverdue() async {
        var task = CodalonTask(
            projectID: projectID,
            title: "Deleted",
            status: .inProgress,
            dueDate: Date().addingTimeInterval(-86400 * 5)
        )
        task.deletedAt = Date()
        let context = InsightRuleContext(projectID: projectID, tasks: [task])
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("tasks without due date are not overdue")
    func tasksWithoutDueDate() async {
        let task = CodalonTask(
            projectID: projectID,
            title: "No Date",
            status: .inProgress
        )
        let context = InsightRuleContext(projectID: projectID, tasks: [task])
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("more than 3 overdue tasks gets warning severity")
    func manyOverdueTasksSeverity() async {
        let tasks = (0..<5).map { i in
            CodalonTask(
                projectID: projectID,
                title: "Task \(i)",
                status: .todo,
                dueDate: Date().addingTimeInterval(-86400)
            )
        }
        let context = InsightRuleContext(projectID: projectID, tasks: tasks)
        let rule = OverdueTaskRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results[0].severity == .warning)
    }

    // MARK: - BlockedReleaseRule Edge Cases

    @Test("release with no blockers is not flagged")
    func noBlockersNotFlagged() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400 * 3),
            status: .drafting
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("release with target far away is not flagged even with blockers")
    func farTargetNotFlagged() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400 * 30),
            status: .drafting,
            blockerCount: 2,
            blockers: [
                CodalonReleaseBlocker(title: "A"),
                CodalonReleaseBlocker(title: "B"),
            ]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("released release with blockers is not flagged")
    func releasedNotFlagged() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(-86400),
            status: .released,
            blockerCount: 1,
            blockers: [CodalonReleaseBlocker(title: "Old")]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("release with no target date but blockers is flagged")
    func noTargetDateWithBlockers() async {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            status: .drafting,
            blockerCount: 1,
            blockers: [CodalonReleaseBlocker(title: "Bug")]
        )
        let context = InsightRuleContext(projectID: projectID, releases: [release])
        let rule = BlockedReleaseRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
    }

    // MARK: - TooManyCriticalAlertsRule Edge Cases

    @Test("read critical alerts are not counted")
    func readCriticalAlertsNotCounted() async {
        let alerts = (0..<5).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "msg",
                readState: .read
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("dismissed critical alerts are not counted")
    func dismissedCriticalAlertsNotCounted() async {
        let alerts = (0..<5).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "msg",
                readState: .dismissed
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("deleted critical alerts are not counted")
    func deletedCriticalAlertsNotCounted() async {
        let alerts = (0..<5).map { i in
            var alert = CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "msg"
            )
            alert.deletedAt = Date()
            return alert
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("exactly at threshold (3) does not trigger")
    func exactlyAtThreshold() async {
        let alerts = (0..<3).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "msg"
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    @Test("custom threshold works")
    func customThreshold() async {
        let alerts = (0..<2).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .critical,
                category: .general,
                title: "Critical \(i)",
                message: "msg"
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule(threshold: 1)
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
    }

    @Test("non-critical alerts are not counted")
    func nonCriticalNotCounted() async {
        let alerts = (0..<10).map { i in
            CodalonAlert(
                projectID: projectID,
                severity: .warning,
                category: .general,
                title: "Warning \(i)",
                message: "msg"
            )
        }
        let context = InsightRuleContext(projectID: projectID, alerts: alerts)
        let rule = TooManyCriticalAlertsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Rule Engine Integration: Deduplication

    @Test("engine deduplicates against existing insights")
    func deduplication() async throws {
        let taskRepo = MockTaskRepo()
        let milestoneRepo = MockMilestoneRepo()
        let releaseRepo = MockReleaseRepo()
        let alertRepo = MockAlertRepo()
        let insightRepo = MockInsightRepo()

        // Pre-populate with an existing insight matching overdue task rule
        let existing = CodalonInsight(
            projectID: projectID,
            type: .reminder,
            severity: .info,
            source: .ruleEngine,
            title: "1 overdue task",
            message: "Fix crash"
        )
        try await insightRepo.save(existing)

        // Add a task that would trigger the same insight
        let task = CodalonTask(
            projectID: projectID,
            title: "Fix crash",
            status: .inProgress,
            dueDate: Date().addingTimeInterval(-86400)
        )
        await taskRepo.setTasks([task], projectID: projectID)

        let engine = await MainActor.run {
            InsightRuleEngine(
                rules: [OverdueTaskRule()],
                taskRepository: taskRepo,
                milestoneRepository: milestoneRepo,
                releaseRepository: releaseRepo,
                alertRepository: alertRepo,
                insightRepository: insightRepo,
                logger: HelaiaMockLogger()
            )
        }

        let newInsights = try await engine.runAllRules(projectID: projectID)

        // Should be deduplicated — same title from ruleEngine source
        #expect(newInsights.isEmpty)
    }

    @Test("engine persists new insights")
    func persistsNewInsights() async throws {
        let taskRepo = MockTaskRepo()
        let milestoneRepo = MockMilestoneRepo()
        let releaseRepo = MockReleaseRepo()
        let alertRepo = MockAlertRepo()
        let insightRepo = MockInsightRepo()

        let task = CodalonTask(
            projectID: projectID,
            title: "Fix crash",
            status: .inProgress,
            dueDate: Date().addingTimeInterval(-86400)
        )
        await taskRepo.setTasks([task], projectID: projectID)

        let engine = await MainActor.run {
            InsightRuleEngine(
                rules: [OverdueTaskRule()],
                taskRepository: taskRepo,
                milestoneRepository: milestoneRepo,
                releaseRepository: releaseRepo,
                alertRepository: alertRepo,
                insightRepository: insightRepo,
                logger: HelaiaMockLogger()
            )
        }

        let newInsights = try await engine.runAllRules(projectID: projectID)
        #expect(newInsights.count == 1)

        let stored = await insightRepo.insights
        #expect(stored.count == 1)
        #expect(stored[0].source == .ruleEngine)
    }

    @Test("engine runs all rules and aggregates results")
    func runsAllRules() async throws {
        let taskRepo = MockTaskRepo()
        let milestoneRepo = MockMilestoneRepo()
        let releaseRepo = MockReleaseRepo()
        let alertRepo = MockAlertRepo()
        let insightRepo = MockInsightRepo()

        // Set up data that triggers multiple rules
        let task = CodalonTask(
            projectID: projectID,
            title: "Overdue Task",
            status: .todo,
            dueDate: Date().addingTimeInterval(-86400)
        )
        await taskRepo.setTasks([task], projectID: projectID)

        let milestone = CodalonMilestone(
            projectID: projectID,
            title: "Overdue MS",
            dueDate: Date().addingTimeInterval(-86400 * 10),
            status: .active
        )
        await milestoneRepo.setMilestones([milestone], projectID: projectID)

        let engine = await MainActor.run {
            InsightRuleEngine(
                rules: [OverdueTaskRule(), OverdueMilestoneRule()],
                taskRepository: taskRepo,
                milestoneRepository: milestoneRepo,
                releaseRepository: releaseRepo,
                alertRepository: alertRepo,
                insightRepository: insightRepo,
                logger: HelaiaMockLogger()
            )
        }

        let newInsights = try await engine.runAllRules(projectID: projectID)
        #expect(newInsights.count == 2)
    }

    @Test("engine with empty project produces no insights")
    func emptyProjectEngine() async throws {
        let taskRepo = MockTaskRepo()
        let milestoneRepo = MockMilestoneRepo()
        let releaseRepo = MockReleaseRepo()
        let alertRepo = MockAlertRepo()
        let insightRepo = MockInsightRepo()

        let engine = await MainActor.run {
            InsightRuleEngine(
                rules: [
                    OverdueTaskRule(),
                    OverdueMilestoneRule(),
                    BlockedReleaseRule(),
                    StaleGitHubIssueRule(),
                    MissingASCMetadataRule(),
                    TooManyCriticalAlertsRule(),
                ],
                taskRepository: taskRepo,
                milestoneRepository: milestoneRepo,
                releaseRepository: releaseRepo,
                alertRepository: alertRepo,
                insightRepository: insightRepo,
                logger: HelaiaMockLogger()
            )
        }

        let newInsights = try await engine.runAllRules(projectID: projectID)
        #expect(newInsights.isEmpty)
    }
}

// MARK: - Mock Setters

private extension MockTaskRepo {
    func setTasks(_ t: [CodalonTask], projectID: UUID) {
        tasks = t
    }
}

private extension MockMilestoneRepo {
    func setMilestones(_ m: [CodalonMilestone], projectID: UUID) {
        milestones = m
    }
}
