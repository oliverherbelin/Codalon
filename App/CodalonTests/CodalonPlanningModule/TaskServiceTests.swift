// Issues #42, #44, #46, #48, #50, #52, #54, #56, #58, #60, #62, #64, #66 — Task service tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
@MainActor private let milestoneID = UUID(uuidString: "00000002-0002-0002-0002-000000000002")!
@MainActor private let epicID = UUID(uuidString: "00000003-0003-0003-0003-000000000003")!

// MARK: - Mock Task Repository

private actor MockTaskRepo: TaskRepositoryProtocol {
    var stored: [UUID: CodalonTask] = [:]

    func save(_ task: CodalonTask) async throws {
        stored[task.id] = task
    }

    func load(id: UUID) async throws -> CodalonTask {
        guard let t = stored[id] else {
            throw NSError(domain: "test", code: 404)
        }
        return t
    }

    func loadAll() async throws -> [CodalonTask] { Array(stored.values) }
    func delete(id: UUID) async throws { stored.removeValue(forKey: id) }

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.projectID == projectID }
    }

    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.milestoneID == milestoneID }
    }

    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.epicID == epicID }
    }

    func fetchByStatus(_ status: CodalonTaskStatus, projectID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.projectID == projectID && $0.status == status }
    }

    func fetchByPriority(_ priority: CodalonPriority, projectID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.projectID == projectID && $0.priority == priority }
    }

    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.projectID == projectID && $0.isBlocked }
    }

    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] {
        stored.values.filter { $0.projectID == projectID && $0.isLaunchCritical }
    }
}

// MARK: - Status Transition Tests (#42)

@Suite("Task Status Workflow")
@MainActor
struct TaskStatusWorkflowTests {

    @Test("valid transition backlog → todo")
    func backlogToTodo() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", status: .backlog)
        try await repo.save(task)

        try await service.changeStatus(taskID: task.id, to: .todo)
        let updated = try await repo.load(id: task.id)
        #expect(updated.status == .todo)
    }

    @Test("valid transition todo → inProgress → inReview → done")
    func fullWorkflow() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", status: .todo)
        try await repo.save(task)

        try await service.changeStatus(taskID: task.id, to: .inProgress)
        try await service.changeStatus(taskID: task.id, to: .inReview)
        try await service.changeStatus(taskID: task.id, to: .done)

        let final_ = try await repo.load(id: task.id)
        #expect(final_.status == .done)
    }

    @Test("invalid transition backlog → done throws")
    func invalidTransition() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", status: .backlog)
        try await repo.save(task)

        await #expect(throws: TaskServiceError.self) {
            try await service.changeStatus(taskID: task.id, to: .done)
        }
    }

    @Test("reopen: done → todo")
    func reopen() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", status: .done)
        try await repo.save(task)

        try await service.changeStatus(taskID: task.id, to: .todo)
        let updated = try await repo.load(id: task.id)
        #expect(updated.status == .todo)
    }
}

// MARK: - Priority Tests (#44)

@Suite("Task Priority")
@MainActor
struct TaskPriorityTests {

    @Test("change priority")
    func changePriority() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", priority: .low)
        try await repo.save(task)

        try await service.changePriority(taskID: task.id, to: .critical)
        let updated = try await repo.load(id: task.id)
        #expect(updated.priority == .critical)
    }
}

// MARK: - Estimate Tests (#46)

@Suite("Task Estimates")
@MainActor
struct TaskEstimateTests {

    @Test("set estimate")
    func setEstimate() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.setEstimate(taskID: task.id, estimate: 4.0)
        let updated = try await repo.load(id: task.id)
        #expect(updated.estimate == 4.0)
    }

    @Test("clear estimate")
    func clearEstimate() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test", estimate: 2.0)
        try await repo.save(task)

        try await service.setEstimate(taskID: task.id, estimate: nil)
        let updated = try await repo.load(id: task.id)
        #expect(updated.estimate == nil)
    }
}

// MARK: - Due Date Tests (#48)

@Suite("Task Due Dates")
@MainActor
struct TaskDueDateTests {

    @Test("set due date")
    func setDueDate() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        let date = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
        try await service.setDueDate(taskID: task.id, dueDate: date)
        let updated = try await repo.load(id: task.id)
        #expect(updated.dueDate != nil)
    }

    @Test("detect overdue tasks")
    func detectOverdue() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let overdue = CodalonTask(
            projectID: projectID,
            title: "Overdue",
            status: .inProgress,
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now)
        )
        let future = CodalonTask(
            projectID: projectID,
            title: "Future",
            status: .todo,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: .now)
        )
        try await repo.save(overdue)
        try await repo.save(future)

        let result = try await service.detectOverdue(projectID: projectID)
        #expect(result.count == 1)
        #expect(result.first?.title == "Overdue")
    }
}

// MARK: - Link Tests (#50, #52)

@Suite("Task Links")
@MainActor
struct TaskLinkTests {

    @Test("link to milestone")
    func linkMilestone() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.linkToMilestone(taskID: task.id, milestoneID: milestoneID)
        let updated = try await repo.load(id: task.id)
        #expect(updated.milestoneID == milestoneID)
    }

    @Test("link to epic")
    func linkEpic() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.linkToEpic(taskID: task.id, epicID: epicID)
        let updated = try await repo.load(id: task.id)
        #expect(updated.epicID == epicID)
    }

    @Test("unlink milestone")
    func unlinkMilestone() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, milestoneID: milestoneID, title: "Test")
        try await repo.save(task)

        try await service.linkToMilestone(taskID: task.id, milestoneID: nil)
        let updated = try await repo.load(id: task.id)
        #expect(updated.milestoneID == nil)
    }
}

// MARK: - Flag Tests (#56, #58, #60)

@Suite("Task Flags")
@MainActor
struct TaskFlagTests {

    @Test("set blocked")
    func setBlocked() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.setBlocked(taskID: task.id, isBlocked: true)
        let updated = try await repo.load(id: task.id)
        #expect(updated.isBlocked == true)
    }

    @Test("set waiting external")
    func setWaitingExternal() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.setWaitingExternal(taskID: task.id, waiting: true)
        let updated = try await repo.load(id: task.id)
        #expect(updated.waitingExternal == true)
    }

    @Test("set launch critical")
    func setLaunchCritical() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let task = CodalonTask(projectID: projectID, title: "Test")
        try await repo.save(task)

        try await service.setLaunchCritical(taskID: task.id, isLaunchCritical: true)
        let updated = try await repo.load(id: task.id)
        #expect(updated.isLaunchCritical == true)
    }
}

// MARK: - Deep Work & Quick Win Tests (#62, #64)

@Suite("Task Tags — Deep Work & Quick Win")
@MainActor
struct TaskTagTests {

    @Test("deep work tasks are those with estimate >= 4h")
    func deepWork() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let deep = CodalonTask(projectID: projectID, title: "Deep", status: .todo, estimate: 6.0)
        let quick = CodalonTask(projectID: projectID, title: "Quick", status: .todo, estimate: 0.5)
        try await repo.save(deep)
        try await repo.save(quick)

        let result = try await service.fetchDeepWork(projectID: projectID)
        #expect(result.count == 1)
        #expect(result.first?.title == "Deep")
    }

    @Test("quick win tasks are those with estimate <= 1h")
    func quickWins() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let deep = CodalonTask(projectID: projectID, title: "Deep", status: .todo, estimate: 6.0)
        let quick = CodalonTask(projectID: projectID, title: "Quick", status: .todo, estimate: 0.5)
        try await repo.save(deep)
        try await repo.save(quick)

        let result = try await service.fetchQuickWins(projectID: projectID)
        #expect(result.count == 1)
        #expect(result.first?.title == "Quick")
    }
}

// MARK: - Bulk Action Tests (#66)

@Suite("Bulk Task Actions")
@MainActor
struct BulkActionTests {

    @Test("bulk change status")
    func bulkStatus() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let t1 = CodalonTask(projectID: projectID, title: "Task 1", status: .todo)
        let t2 = CodalonTask(projectID: projectID, title: "Task 2", status: .inProgress)
        try await repo.save(t1)
        try await repo.save(t2)

        try await service.bulkChangeStatus(taskIDs: [t1.id, t2.id], to: .done)

        let u1 = try await repo.load(id: t1.id)
        let u2 = try await repo.load(id: t2.id)
        #expect(u1.status == .done)
        #expect(u2.status == .done)
    }

    @Test("bulk change priority")
    func bulkPriority() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let t1 = CodalonTask(projectID: projectID, title: "Task 1", priority: .low)
        let t2 = CodalonTask(projectID: projectID, title: "Task 2", priority: .medium)
        try await repo.save(t1)
        try await repo.save(t2)

        try await service.bulkChangePriority(taskIDs: [t1.id, t2.id], to: .high)

        let u1 = try await repo.load(id: t1.id)
        let u2 = try await repo.load(id: t2.id)
        #expect(u1.priority == .high)
        #expect(u2.priority == .high)
    }

    @Test("bulk assign milestone")
    func bulkMilestone() async throws {
        let repo = MockTaskRepo()
        let service = TaskService(taskRepository: repo)

        let t1 = CodalonTask(projectID: projectID, title: "Task 1")
        let t2 = CodalonTask(projectID: projectID, title: "Task 2")
        try await repo.save(t1)
        try await repo.save(t2)

        try await service.bulkAssignMilestone(taskIDs: [t1.id, t2.id], milestoneID: milestoneID)

        let u1 = try await repo.load(id: t1.id)
        let u2 = try await repo.load(id: t2.id)
        #expect(u1.milestoneID == milestoneID)
        #expect(u2.milestoneID == milestoneID)
    }
}

// MARK: - ViewModel Tests (#36, #70)

@Suite("TaskViewModel Filtering & Sorting")
@MainActor
struct TaskViewModelTests {

    private func makeViewModel() -> TaskViewModel {
        let vm = TaskViewModel(
            taskService: InertTaskService(),
            projectID: projectID
        )
        vm.tasks = CodalonTask.previewList
        return vm
    }

    @Test("filters by status")
    func filterByStatus() {
        let vm = makeViewModel()
        vm.statusFilter = .inProgress
        let filtered = vm.filteredTasks
        #expect(filtered.allSatisfy { $0.status == .inProgress })
    }

    @Test("filters by priority")
    func filterByPriority() {
        let vm = makeViewModel()
        vm.priorityFilter = .high
        let filtered = vm.filteredTasks
        #expect(filtered.allSatisfy { $0.priority == .high })
    }

    @Test("search by title")
    func searchByTitle() {
        let vm = makeViewModel()
        vm.searchQuery = "milestone"
        let filtered = vm.filteredTasks
        #expect(filtered.allSatisfy { $0.title.lowercased().contains("milestone") })
    }

    @Test("sorts by priority descending")
    func sortByPriority() {
        let vm = makeViewModel()
        vm.sortMode = .priority
        let sorted = vm.filteredTasks
        guard sorted.count >= 2 else { return }
        #expect(sorted.first!.priority >= sorted.last!.priority)
    }

    @Test("excludes soft-deleted tasks")
    func excludeDeleted() {
        let vm = makeViewModel()
        var deleted = CodalonTask(projectID: projectID, title: "Deleted")
        deleted.deletedAt = Date()
        vm.tasks.append(deleted)
        let filtered = vm.filteredTasks
        #expect(!filtered.contains { $0.title == "Deleted" })
    }

    @Test("groups by status for board view")
    func groupByStatus() {
        let vm = makeViewModel()
        let grouped = vm.tasksByStatus
        #expect(!grouped.isEmpty)
    }

    @Test("today tasks filters by due date")
    func todayTasks() {
        let vm = makeViewModel()
        let todayTask = CodalonTask(
            projectID: projectID,
            title: "Due Today",
            status: .todo,
            dueDate: Date()
        )
        vm.tasks.append(todayTask)
        #expect(vm.todayTasks.contains { $0.title == "Due Today" })
    }
}

// MARK: - Inert Task Service

private actor InertTaskService: TaskServiceProtocol {
    func create(_ task: CodalonTask) async throws {}
    func update(_ task: CodalonTask) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonTask { CodalonTask(projectID: UUID(), title: "") }
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
