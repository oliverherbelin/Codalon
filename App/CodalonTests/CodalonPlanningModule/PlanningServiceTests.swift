// Issues #26, #28, #34 — Planning service tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
@MainActor private let milestoneID = UUID(uuidString: "00000002-0002-0002-0002-000000000002")!

// MARK: - Mock Repository

private actor MockMilestoneRepository: MilestoneRepositoryProtocol {
    var stored: [UUID: CodalonMilestone] = [:]

    func save(_ milestone: CodalonMilestone) async throws {
        stored[milestone.id] = milestone
    }

    func load(id: UUID) async throws -> CodalonMilestone {
        guard let m = stored[id] else {
            throw NSError(domain: "test", code: 404)
        }
        return m
    }

    func loadAll() async throws -> [CodalonMilestone] {
        Array(stored.values)
    }

    func delete(id: UUID) async throws {
        stored.removeValue(forKey: id)
    }

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        stored.values.filter { $0.projectID == projectID }
    }

    func fetchByStatus(
        _ status: CodalonMilestoneStatus,
        projectID: UUID
    ) async throws -> [CodalonMilestone] {
        stored.values.filter { $0.projectID == projectID && $0.status == status }
    }

    func fetchOverdue(projectID: UUID) async throws -> [CodalonMilestone] {
        let now = Date()
        return stored.values.filter {
            $0.projectID == projectID
                && $0.status != .completed
                && $0.status != .cancelled
                && ($0.dueDate ?? .distantFuture) < now
        }
    }
}

private actor MockTaskRepository: TaskRepositoryProtocol {
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

    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByStatus(
        _ status: CodalonTaskStatus,
        projectID: UUID
    ) async throws -> [CodalonTask] { [] }
    func fetchByPriority(
        _ priority: CodalonPriority,
        projectID: UUID
    ) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
}

// MARK: - Progress Calculation Tests (#26)

@Suite("Milestone Progress Calculation")
@MainActor
struct MilestoneProgressTests {

    @Test("progress is 0 when no tasks")
    func progressNoTasks() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let milestone = CodalonMilestone(
            id: milestoneID,
            projectID: projectID,
            title: "Test Milestone"
        )
        try await milestoneRepo.save(milestone)

        let progress = try await service.recalculateProgress(milestoneID: milestoneID)
        #expect(progress == 0)
    }

    @Test("progress reflects completed task ratio")
    func progressWithTasks() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let milestone = CodalonMilestone(
            id: milestoneID,
            projectID: projectID,
            title: "Test Milestone"
        )
        try await milestoneRepo.save(milestone)

        let task1 = CodalonTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Task 1",
            status: .done
        )
        let task2 = CodalonTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Task 2",
            status: .inProgress
        )
        let task3 = CodalonTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Task 3",
            status: .done
        )
        try await taskRepo.save(task1)
        try await taskRepo.save(task2)
        try await taskRepo.save(task3)

        let progress = try await service.recalculateProgress(milestoneID: milestoneID)
        #expect(abs(progress - (2.0 / 3.0)) < 0.01)
    }

    @Test("progress is 1.0 when all tasks done")
    func progressAllDone() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let milestone = CodalonMilestone(
            id: milestoneID,
            projectID: projectID,
            title: "Test Milestone"
        )
        try await milestoneRepo.save(milestone)

        let task1 = CodalonTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Task 1",
            status: .done
        )
        let task2 = CodalonTask(
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Task 2",
            status: .done
        )
        try await taskRepo.save(task1)
        try await taskRepo.save(task2)

        let progress = try await service.recalculateProgress(milestoneID: milestoneID)
        #expect(progress == 1.0)
    }
}

// MARK: - Overdue Detection Tests (#28)

@Suite("Milestone Overdue Detection")
@MainActor
struct MilestoneOverdueTests {

    @Test("detects overdue milestone")
    func detectsOverdue() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let overdue = CodalonMilestone(
            projectID: projectID,
            title: "Overdue Milestone",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            status: .active,
            priority: .high
        )
        try await milestoneRepo.save(overdue)

        let result = try await service.detectOverdue(projectID: projectID)
        #expect(result.count == 1)
        #expect(result.first?.title == "Overdue Milestone")
    }

    @Test("does not flag completed milestone as overdue")
    func completedNotOverdue() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let completed = CodalonMilestone(
            projectID: projectID,
            title: "Done Milestone",
            dueDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            status: .completed,
            priority: .medium,
            progress: 1.0
        )
        try await milestoneRepo.save(completed)

        let result = try await service.detectOverdue(projectID: projectID)
        #expect(result.isEmpty)
    }

    @Test("does not flag future milestone as overdue")
    func futureNotOverdue() async throws {
        let milestoneRepo = MockMilestoneRepository()
        let taskRepo = MockTaskRepository()
        let service = PlanningService(
            milestoneRepository: milestoneRepo,
            taskRepository: taskRepo
        )

        let future = CodalonMilestone(
            projectID: projectID,
            title: "Future Milestone",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now),
            status: .planned,
            priority: .medium
        )
        try await milestoneRepo.save(future)

        let result = try await service.detectOverdue(projectID: projectID)
        #expect(result.isEmpty)
    }
}

// MARK: - Roadmap Item Tests (#29)

@Suite("CodalonRoadmapItem")
@MainActor
struct RoadmapItemTests {

    @Test("round-trip encode/decode")
    func roundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let item = CodalonRoadmapItem(
            projectID: projectID,
            milestoneID: milestoneID,
            startDate: Date(timeIntervalSince1970: 1_710_000_000),
            endDate: Date(timeIntervalSince1970: 1_712_000_000),
            sortOrder: 3
        )

        let data = try encoder.encode(item)
        let decoded = try decoder.decode(CodalonRoadmapItem.self, from: data)

        #expect(decoded.projectID == item.projectID)
        #expect(decoded.milestoneID == item.milestoneID)
        #expect(decoded.sortOrder == 3)
    }

    @Test("default values")
    func defaults() {
        let item = CodalonRoadmapItem(
            projectID: projectID,
            milestoneID: milestoneID
        )

        #expect(item.startDate == nil)
        #expect(item.endDate == nil)
        #expect(item.sortOrder == 0)
        #expect(item.deletedAt == nil)
        #expect(item.schemaVersion == 1)
    }
}

// MARK: - Planning ViewModel Tests (#32, #33)

@Suite("PlanningViewModel Filtering & Search")
@MainActor
struct PlanningViewModelTests {

    private func makeViewModel() -> PlanningViewModel {
        let vm = PlanningViewModel(
            planningService: InertPlanningService(),
            taskRepository: InertTaskRepository(),
            projectID: projectID
        )
        vm.milestones = CodalonMilestone.previewList
        return vm
    }

    @Test("filters by status")
    func filterByStatus() {
        let vm = makeViewModel()
        vm.statusFilter = .active
        let filtered = vm.filteredMilestones
        #expect(filtered.allSatisfy { $0.status == .active })
    }

    @Test("filters by priority")
    func filterByPriority() {
        let vm = makeViewModel()
        vm.priorityFilter = .critical
        let filtered = vm.filteredMilestones
        #expect(filtered.allSatisfy { $0.priority == .critical })
    }

    @Test("search filters by title")
    func searchByTitle() {
        let vm = makeViewModel()
        vm.searchQuery = "MVP"
        let filtered = vm.filteredMilestones
        #expect(filtered.allSatisfy { $0.title.lowercased().contains("mvp") })
    }

    @Test("search filters by summary")
    func searchBySummary() {
        let vm = makeViewModel()
        vm.searchQuery = "HelaiaDesign"
        let filtered = vm.filteredMilestones
        #expect(filtered.allSatisfy {
            $0.summary.lowercased().contains("helaiadesign")
        })
    }

    @Test("groups milestones by status for board view")
    func groupByStatus() {
        let vm = makeViewModel()
        let grouped = vm.milestonesByStatus
        #expect(grouped[.completed]?.isEmpty == false)
        #expect(grouped[.active]?.isEmpty == false)
    }

    @Test("sorts by priority")
    func sortByPriority() {
        let vm = makeViewModel()
        vm.sortMode = .priority
        let sorted = vm.filteredMilestones
        guard sorted.count >= 2 else { return }
        #expect(sorted.first!.priority >= sorted.last!.priority)
    }

    @Test("sorts by progress")
    func sortByProgress() {
        let vm = makeViewModel()
        vm.sortMode = .progress
        let sorted = vm.filteredMilestones
        guard sorted.count >= 2 else { return }
        #expect(sorted.first!.progress >= sorted.last!.progress)
    }

    @Test("excludes soft-deleted milestones")
    func excludeDeleted() {
        let vm = makeViewModel()
        var deleted = CodalonMilestone(
            projectID: projectID,
            title: "Deleted"
        )
        deleted.deletedAt = Date()
        vm.milestones.append(deleted)
        let filtered = vm.filteredMilestones
        #expect(!filtered.contains { $0.title == "Deleted" })
    }
}

// MARK: - Inert Services for ViewModel Tests

private actor InertPlanningService: PlanningServiceProtocol {
    func create(_ milestone: CodalonMilestone) async throws {}
    func update(_ milestone: CodalonMilestone) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonMilestone { .previewActive }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] { [] }
    func fetchByStatus(
        _ status: CodalonMilestoneStatus,
        projectID: UUID
    ) async throws -> [CodalonMilestone] { [] }
    func recalculateProgress(milestoneID: UUID) async throws -> Double { 0 }
    func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private actor InertTaskRepository: TaskRepositoryProtocol {
    func save(_ task: CodalonTask) async throws {}
    func load(id: UUID) async throws -> CodalonTask {
        CodalonTask(projectID: UUID(), title: "")
    }
    func loadAll() async throws -> [CodalonTask] { [] }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] { [] }
    func fetchByStatus(
        _ status: CodalonTaskStatus,
        projectID: UUID
    ) async throws -> [CodalonTask] { [] }
    func fetchByPriority(
        _ priority: CodalonPriority,
        projectID: UUID
    ) async throws -> [CodalonTask] { [] }
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] { [] }
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] { [] }
}
