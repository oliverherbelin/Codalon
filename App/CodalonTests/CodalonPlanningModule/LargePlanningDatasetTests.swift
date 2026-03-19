// Issue #253 — Test large planning datasets

import Foundation
import Testing
import HelaiaShare
@testable import Codalon

// MARK: - Large Planning Dataset Tests

@Suite("Large Planning Datasets")
@MainActor
struct LargePlanningDatasetTests {

    // MARK: - Test Data Generators

    private func generateMilestones(count: Int, projectID: UUID) -> [CodalonMilestone] {
        (0..<count).map { i in
            CodalonMilestone(
                projectID: projectID,
                title: "Milestone \(i)",
                summary: "Summary for milestone \(i)",
                dueDate: Calendar.current.date(byAdding: .day, value: i * 7, to: .now),
                status: CodalonMilestoneStatus.allCases[i % CodalonMilestoneStatus.allCases.count],
                priority: CodalonPriority.allCases[i % CodalonPriority.allCases.count],
                progress: Double(i % 100) / 100.0
            )
        }
    }

    private func generateTasks(count: Int, projectID: UUID) -> [CodalonTask] {
        (0..<count).map { i in
            CodalonTask(
                projectID: projectID,
                title: "Task \(i)",
                summary: "Description for task \(i)",
                status: CodalonTaskStatus.allCases[i % CodalonTaskStatus.allCases.count],
                priority: CodalonPriority.allCases[i % CodalonPriority.allCases.count],
                estimate: Double(i % 8) + 0.5
            )
        }
    }

    // MARK: - Tests

    @Test("50+ tasks create without issue")
    func fiftyTasksCreate() {
        let projectID = UUID()
        let tasks = generateTasks(count: 60, projectID: projectID)

        #expect(tasks.count == 60)
        #expect(tasks.allSatisfy { $0.projectID == projectID })
    }

    @Test("20+ milestones create without issue")
    func twentyMilestonesCreate() {
        let projectID = UUID()
        let milestones = generateMilestones(count: 25, projectID: projectID)

        #expect(milestones.count == 25)
        #expect(milestones.allSatisfy { $0.projectID == projectID })
    }

    @Test("view model handles 50+ tasks")
    func viewModelWithFiftyTasks() {
        let projectID = UUID()
        let vm = TaskViewModel(
            taskService: LargeDataTaskService(count: 60, projectID: projectID),
            projectID: projectID
        )
        vm.tasks = generateTasks(count: 60, projectID: projectID)

        #expect(vm.tasks.count == 60)
    }

    @Test("planning view model handles 20+ milestones")
    func planningViewModelWithTwentyMilestones() {
        let projectID = UUID()
        let milestones = generateMilestones(count: 25, projectID: projectID)
        let vm = PlanningViewModel(
            planningService: LargeDataPlanningService(milestones: milestones),
            taskRepository: LargeDataTaskRepository(),
            projectID: projectID
        )
        vm.milestones = milestones

        #expect(vm.milestones.count == 25)
        #expect(!vm.filteredMilestones.isEmpty)

        // Verify milestonesByStatus groups correctly
        let byStatus = vm.milestonesByStatus
        let totalFromGroups = byStatus.values.reduce(0) { $0 + $1.count }
        #expect(totalFromGroups == 25)
    }

    @Test("export formatter handles large roadmap")
    func exportFormatterLargeRoadmap() {
        let projectID = UUID()
        let milestones = generateMilestones(count: 25, projectID: projectID)
        let tasks = Dictionary(
            uniqueKeysWithValues: milestones.prefix(5).map { milestone in
                (milestone.id, generateTasks(count: 10, projectID: projectID))
            }
        )

        let content = CodalonExportFormatter.roadmapContent(
            milestones: milestones,
            tasks: tasks,
            projectName: "LargeProject"
        )

        #expect(content.metadata["total_milestones"] == "25")
        #expect(!content.body.isEmpty)
        // Verify all 25 milestones appear in body
        for milestone in milestones {
            #expect(content.body.contains(milestone.title))
        }
    }

    @Test("100 tasks encode/decode round-trip")
    func hundredTasksRoundTrip() throws {
        let projectID = UUID()
        let tasks = generateTasks(count: 100, projectID: projectID)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(tasks)
        let decoded = try decoder.decode([CodalonTask].self, from: data)

        #expect(decoded.count == 100)
        for (original, roundTripped) in zip(tasks, decoded) {
            #expect(original.id == roundTripped.id)
            #expect(original.title == roundTripped.title)
        }
    }
}

// MARK: - Mock Services

private actor LargeDataTaskService: TaskServiceProtocol {
    private let tasks: [CodalonTask]

    init(count: Int, projectID: UUID) {
        tasks = (0..<count).map { i in
            CodalonTask(
                projectID: projectID,
                title: "Task \(i)",
                status: .todo,
                priority: .medium
            )
        }
    }

    func create(_ task: CodalonTask) async throws {}
    func update(_ task: CodalonTask) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonTask { tasks[0] }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] { tasks }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchWaitingExternal(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchDeepWork(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchQuickWins(projectID: UUID) async throws -> [CodalonTask] { [] }
    func changeStatus(taskID: UUID, to: CodalonTaskStatus) async throws {}
    func changePriority(taskID: UUID, to: CodalonPriority) async throws {}
    func setEstimate(taskID: UUID, estimate: Double?) async throws {}
    func setDueDate(taskID: UUID, dueDate: Date?) async throws {}
    func linkToMilestone(taskID: UUID, milestoneID: UUID?) async throws {}
    func linkToEpic(taskID: UUID, epicID: UUID?) async throws {}
    func addDependency(taskID: UUID, dependsOn: UUID) async throws {}
    func removeDependency(taskID: UUID, dependsOn: UUID) async throws {}
    func setBlocked(taskID: UUID, isBlocked: Bool) async throws {}
    func setWaitingExternal(taskID: UUID, waiting: Bool) async throws {}
    func setLaunchCritical(taskID: UUID, isLaunchCritical: Bool) async throws {}
    func bulkChangeStatus(taskIDs: [UUID], to: CodalonTaskStatus) async throws {}
    func bulkChangePriority(taskIDs: [UUID], to: CodalonPriority) async throws {}
    func bulkAssignMilestone(taskIDs: [UUID], milestoneID: UUID?) async throws {}
    func detectOverdue(projectID: UUID) async throws -> [CodalonTask] { [] }
}

private actor LargeDataPlanningService: PlanningServiceProtocol {
    private let milestones: [CodalonMilestone]

    init(milestones: [CodalonMilestone]) {
        self.milestones = milestones
    }

    func create(_ milestone: CodalonMilestone) async throws {}
    func update(_ milestone: CodalonMilestone) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonMilestone { milestones[0] }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] { milestones }
    func fetchByStatus(_ status: CodalonMilestoneStatus, projectID: UUID) async throws -> [CodalonMilestone] {
        milestones.filter { $0.status == status }
    }
    func recalculateProgress(milestoneID: UUID) async throws -> Double { 0.5 }
    func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private actor LargeDataTaskRepository: TaskRepositoryProtocol {
    func save(_ task: CodalonTask) async throws {}
    func load(id: UUID) async throws -> CodalonTask { CodalonTask(projectID: UUID(), title: "", status: .todo, priority: .low) }
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
