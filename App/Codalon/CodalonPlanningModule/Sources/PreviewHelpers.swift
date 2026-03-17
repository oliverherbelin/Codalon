// Epic 6 — Preview data for planning views

import Foundation

// MARK: - CodalonMilestone Preview Data

extension CodalonMilestone {

    static let previewPlanned = CodalonMilestone(
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
        title: "Beta Release",
        summary: "First public beta with core features",
        dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now),
        status: .planned,
        priority: .high,
        progress: 0.0
    )

    static let previewActive = CodalonMilestone(
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
        title: "MVP Launch",
        summary: "Minimum viable product for App Store submission",
        dueDate: Calendar.current.date(byAdding: .day, value: 14, to: .now),
        status: .active,
        priority: .critical,
        progress: 0.65
    )

    static let previewCompleted = CodalonMilestone(
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
        title: "Architecture Setup",
        summary: "Module scaffold, DI, routing, persistence layer",
        dueDate: Calendar.current.date(byAdding: .day, value: -10, to: .now),
        status: .completed,
        priority: .medium,
        progress: 1.0
    )

    static let previewOverdue = CodalonMilestone(
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
        title: "Design System Integration",
        summary: "Align all components with HelaiaDesign",
        dueDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
        status: .active,
        priority: .high,
        progress: 0.40
    )

    static let previewList: [CodalonMilestone] = [
        .previewActive,
        .previewPlanned,
        .previewOverdue,
        .previewCompleted,
    ]
}

// MARK: - CodalonTask Preview Data

extension CodalonTask {

    static let previewList: [CodalonTask] = [
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Create milestone list view",
            status: .done,
            priority: .high
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Add progress calculation",
            status: .inProgress,
            priority: .medium
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Implement overdue detection",
            status: .todo,
            priority: .high,
            isBlocked: true
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Write unit tests",
            status: .backlog,
            priority: .low
        ),
    ]
}

// MARK: - PlanningViewModel Preview

extension PlanningViewModel {

    static var preview: PlanningViewModel {
        let vm = PlanningViewModel(
            planningService: PreviewPlanningService(),
            taskRepository: PreviewTaskRepository(),
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
        )
        vm.milestones = CodalonMilestone.previewList
        vm.tasks = [
            CodalonMilestone.previewActive.id: CodalonTask.previewList,
        ]
        return vm
    }
}

// MARK: - Preview Services

private actor PreviewPlanningService: PlanningServiceProtocol {
    func create(_ milestone: CodalonMilestone) async throws {}
    func update(_ milestone: CodalonMilestone) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonMilestone { .previewActive }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        CodalonMilestone.previewList
    }
    func fetchByStatus(
        _ status: CodalonMilestoneStatus,
        projectID: UUID
    ) async throws -> [CodalonMilestone] {
        CodalonMilestone.previewList.filter { $0.status == status }
    }
    func recalculateProgress(milestoneID: UUID) async throws -> Double { 0.65 }
    func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone] { [] }
}

private actor PreviewTaskRepository: TaskRepositoryProtocol {
    func save(_ task: CodalonTask) async throws {}
    func load(id: UUID) async throws -> CodalonTask { CodalonTask.previewList[0] }
    func loadAll() async throws -> [CodalonTask] { CodalonTask.previewList }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] {
        CodalonTask.previewList
    }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] {
        CodalonTask.previewList
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
