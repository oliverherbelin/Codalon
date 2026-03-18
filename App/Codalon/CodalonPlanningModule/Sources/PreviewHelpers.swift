// Epics 6, 7, 8 — Preview data for planning views

import Foundation
import HelaiaEngine

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
            priority: .high,
            estimate: 3.0
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Add progress calculation",
            status: .inProgress,
            priority: .medium,
            estimate: 2.0,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Implement overdue detection",
            status: .todo,
            priority: .high,
            estimate: 4.0,
            dueDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            isBlocked: true
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Write unit tests",
            status: .backlog,
            priority: .low,
            estimate: 0.5
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Design system alignment",
            status: .inReview,
            priority: .critical,
            estimate: 6.0,
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: .now),
            isLaunchCritical: true
        ),
        CodalonTask(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            title: "Waiting on API access",
            status: .todo,
            priority: .medium,
            waitingExternal: true
        ),
    ]
}

// MARK: - CodalonDecisionLogEntry Preview Data

extension CodalonDecisionLogEntry {

    static let previewList: [CodalonDecisionLogEntry] = [
        CodalonDecisionLogEntry(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            category: .architecture,
            title: "Use actor-based services",
            note: "All services use Swift actors for thread safety under strict concurrency."
        ),
        CodalonDecisionLogEntry(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            category: .scope,
            title: "Defer companion app to post-MVP",
            note: "CodalonCompanion will ship after the macOS cockpit reaches v1.0."
        ),
        CodalonDecisionLogEntry(
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!,
            category: .design,
            title: "HelaiaDesign is the design system",
            note: "All UI components must use HelaiaDesign. No custom components that diverge."
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

// MARK: - TaskViewModel Preview

extension TaskViewModel {

    static var preview: TaskViewModel {
        let vm = TaskViewModel(
            taskService: PreviewTaskService(),
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
        )
        vm.tasks = CodalonTask.previewList
        return vm
    }
}

// MARK: - DecisionLogViewModel Preview

extension DecisionLogViewModel {

    static var preview: DecisionLogViewModel {
        let vm = DecisionLogViewModel(
            repository: PreviewDecisionLogRepository(),
            projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
        )
        vm.entries = CodalonDecisionLogEntry.previewList
        return vm
    }
}

// MARK: - Preview Services

actor PreviewTaskService: TaskServiceProtocol {
    func create(_ task: CodalonTask) async throws {}
    func update(_ task: CodalonTask) async throws {}
    func delete(id: UUID) async throws {}
    func load(id: UUID) async throws -> CodalonTask { CodalonTask.previewList[0] }
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] { CodalonTask.previewList }
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] { CodalonTask.previewList }
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

actor PreviewDecisionLogRepository: DecisionLogRepositoryProtocol {
    func save(_ entry: CodalonDecisionLogEntry) async throws {}
    func load(id: UUID) async throws -> CodalonDecisionLogEntry { CodalonDecisionLogEntry.previewList[0] }
    func loadAll() async throws -> [CodalonDecisionLogEntry] { CodalonDecisionLogEntry.previewList }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonDecisionLogEntry] { CodalonDecisionLogEntry.previewList }
    func fetchByCategory(_ category: CodalonDecisionCategory, projectID: UUID) async throws -> [CodalonDecisionLogEntry] { [] }
    func fetchByRelatedObject(_ objectID: UUID) async throws -> [CodalonDecisionLogEntry] { [] }
}

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
