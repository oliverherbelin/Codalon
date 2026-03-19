// Issue #248 — Test empty project flows

import Foundation
import Testing
@testable import Codalon

// MARK: - Empty Project Flow Tests

@Suite("Empty Project Flows")
@MainActor
struct EmptyProjectFlowTests {

    @Test("empty project has zero open tasks")
    func emptyProjectSummary() {
        let summary = ProjectSummary(
            projectID: UUID(),
            openTaskCount: 0,
            milestoneCount: 0,
            activeReleaseVersion: nil,
            healthScore: 0.0
        )

        #expect(summary.openTaskCount == 0)
        #expect(summary.milestoneCount == 0)
        #expect(summary.activeReleaseVersion == nil)
        #expect(summary.healthScore == 0.0)
    }

    @Test("empty milestone list returns empty filtered results")
    func emptyMilestoneList() {
        let vm = PlanningViewModel(
            planningService: EmptyPlanningService(),
            taskRepository: EmptyTaskRepository(),
            projectID: UUID()
        )

        #expect(vm.milestones.isEmpty)
        #expect(vm.filteredMilestones.isEmpty)
    }

    @Test("empty task list returns empty results")
    func emptyTaskList() {
        let vm = TaskViewModel(
            taskService: EmptyTaskService(),
            projectID: UUID()
        )

        #expect(vm.tasks.isEmpty)
    }

    @Test("empty release list shows no active release")
    func emptyReleaseList() {
        let vm = ReleaseViewModel(
            releaseService: EmptyReleaseService(),
            projectID: UUID()
        )

        #expect(vm.releases.isEmpty)
        #expect(vm.activeRelease == nil)
        #expect(vm.selectedRelease == nil)
    }

    @Test("empty insight list shows no insights")
    func emptyInsightList() {
        let vm = InsightViewModel(
            insightRepository: EmptyInsightRepository(),
            ruleEngine: EmptyRuleEngine(),
            healthScoreService: EmptyHealthScoreService(),
            projectID: UUID()
        )

        #expect(vm.insights.isEmpty)
        #expect(vm.filteredInsights.isEmpty)
        #expect(vm.actionableInsights.isEmpty)
        #expect(vm.informationalInsights.isEmpty)
    }
}

// MARK: - Empty Mock Services

private actor EmptyPlanningService: PlanningServiceProtocol {
    func create(_ milestone: CodalonMilestone) async throws {}
    func update(_ milestone: CodalonMilestone) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonMilestone {
        throw EmptyError.notFound
    }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] { [] }
    func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone] { [] }
    func recalculateProgress(milestoneID: UUID) async throws -> Double { 0 }
    func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private actor EmptyTaskRepository: TaskRepositoryProtocol {
    func save(_ task: CodalonTask) async throws {}
    func load(id: UUID) async throws -> CodalonTask { throw EmptyError.notFound }
    func loadAll() async throws -> [CodalonTask] { [] }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
}

private actor EmptyTaskService: TaskServiceProtocol {
    func create(_ task: CodalonTask) async throws {}
    func update(_ task: CodalonTask) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonTask { throw EmptyError.notFound }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchWaitingExternal(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchDeepWork(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchQuickWins(projectID: UUID) async throws -> [CodalonTask] { [] }
    func changeStatus(taskID: UUID, to newStatus: CodalonTaskStatus) async throws {}
    func changePriority(taskID: UUID, to priority: CodalonPriority) async throws {}
    func setEstimate(taskID: UUID, estimate: Double?) async throws {}
    func setDueDate(taskID: UUID, dueDate: Date?) async throws {}
    func linkToMilestone(taskID: UUID, milestoneID: UUID?) async throws {}
    func linkToEpic(taskID: UUID, epicID: UUID?) async throws {}
    func addDependency(taskID: UUID, dependsOn: UUID) async throws {}
    func removeDependency(taskID: UUID, dependsOn: UUID) async throws {}
    func setBlocked(taskID: UUID, isBlocked: Bool) async throws {}
    func setWaitingExternal(taskID: UUID, waiting: Bool) async throws {}
    func setLaunchCritical(taskID: UUID, isLaunchCritical: Bool) async throws {}
    func bulkChangeStatus(taskIDs: [UUID], to status: CodalonTaskStatus) async throws {}
    func bulkChangePriority(taskIDs: [UUID], to priority: CodalonPriority) async throws {}
    func bulkAssignMilestone(taskIDs: [UUID], milestoneID: UUID?) async throws {}
    func detectOverdue(projectID: UUID) async throws -> [CodalonTask] { [] }
}

private actor EmptyReleaseService: ReleaseServiceProtocol {
    func save(_ release: CodalonRelease) async throws {}
    func load(id: UUID) async throws -> CodalonRelease { throw EmptyError.notFound }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] { [] }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? { nil }
}

private actor EmptyInsightRepository: InsightRepositoryProtocol {
    func save(_ insight: CodalonInsight) async throws {}
    func load(id: UUID) async throws -> CodalonInsight { throw EmptyError.notFound }
    func loadAll() async throws -> [CodalonInsight] { [] }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonInsight] { [] }
    func fetchBySeverity(_ severity: CodalonSeverity, projectID: UUID) async throws -> [CodalonInsight] { [] }
    func fetchBySource(_ source: CodalonInsightSource, projectID: UUID) async throws -> [CodalonInsight] { [] }
}

private actor EmptyRuleEngine: InsightRuleEngineProtocol {
    func runAllRules(projectID: UUID) async throws -> [CodalonInsight] { [] }
}

private actor EmptyHealthScoreService: HealthScoreServiceProtocol {
    func recalculate(projectID: UUID) async throws -> HealthScoreResult {
        HealthScoreResult(overallScore: 0.0, dimensions: [])
    }
}

private enum EmptyError: Error {
    case notFound
}
