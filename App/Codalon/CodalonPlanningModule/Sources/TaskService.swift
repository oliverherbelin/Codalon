// Issues #42, #44, #46, #48, #50, #52, #54, #56, #58, #60, #62, #64 — Task service

import Foundation
import HelaiaEngine

// MARK: - Protocol

public protocol TaskServiceProtocol: Sendable {
    func create(_ task: CodalonTask) async throws
    func update(_ task: CodalonTask) async throws
    func delete(id: UUID) async throws
    func load(id: UUID) async throws -> CodalonTask
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask]
    func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask]
    func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask]
    func fetchBlocked(projectID: UUID) async throws -> [CodalonTask]
    func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask]
    func fetchWaitingExternal(projectID: UUID) async throws -> [CodalonTask]
    func fetchDeepWork(projectID: UUID) async throws -> [CodalonTask]
    func fetchQuickWins(projectID: UUID) async throws -> [CodalonTask]
    func changeStatus(taskID: UUID, to newStatus: CodalonTaskStatus) async throws
    func changePriority(taskID: UUID, to priority: CodalonPriority) async throws
    func setEstimate(taskID: UUID, estimate: Double?) async throws
    func setDueDate(taskID: UUID, dueDate: Date?) async throws
    func linkToMilestone(taskID: UUID, milestoneID: UUID?) async throws
    func linkToEpic(taskID: UUID, epicID: UUID?) async throws
    func addDependency(taskID: UUID, dependsOn: UUID) async throws
    func removeDependency(taskID: UUID, dependsOn: UUID) async throws
    func setBlocked(taskID: UUID, isBlocked: Bool) async throws
    func setWaitingExternal(taskID: UUID, waiting: Bool) async throws
    func setLaunchCritical(taskID: UUID, isLaunchCritical: Bool) async throws
    func bulkChangeStatus(taskIDs: [UUID], to status: CodalonTaskStatus) async throws
    func bulkChangePriority(taskIDs: [UUID], to priority: CodalonPriority) async throws
    func bulkAssignMilestone(taskIDs: [UUID], milestoneID: UUID?) async throws
    func detectOverdue(projectID: UUID) async throws -> [CodalonTask]
}

// MARK: - Implementation

public actor TaskService: TaskServiceProtocol {

    private let taskRepository: any TaskRepositoryProtocol

    public init(taskRepository: any TaskRepositoryProtocol) {
        self.taskRepository = taskRepository
    }

    // MARK: - CRUD

    public func create(_ task: CodalonTask) async throws {
        try await taskRepository.save(task)
        await publish(TaskCreatedEvent(
            taskID: task.id,
            projectID: task.projectID,
            title: task.title
        ))
    }

    public func update(_ task: CodalonTask) async throws {
        var updated = task
        updated.updatedAt = Date()
        try await taskRepository.save(updated)
        await publish(TaskUpdatedEvent(
            taskID: updated.id,
            projectID: updated.projectID
        ))
    }

    public func delete(id: UUID) async throws {
        let task = try await taskRepository.load(id: id)
        var deleted = task
        deleted.deletedAt = Date()
        deleted.updatedAt = Date()
        try await taskRepository.save(deleted)
        await publish(TaskDeletedEvent(
            taskID: task.id,
            projectID: task.projectID
        ))
    }

    public func load(id: UUID) async throws -> CodalonTask {
        try await taskRepository.load(id: id)
    }

    // MARK: - Fetch

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonTask] {
        try await taskRepository.fetchByProject(projectID)
    }

    public func fetchByMilestone(_ milestoneID: UUID) async throws -> [CodalonTask] {
        try await taskRepository.fetchByMilestone(milestoneID)
    }

    public func fetchByEpic(_ epicID: UUID) async throws -> [CodalonTask] {
        try await taskRepository.fetchByEpic(epicID)
    }

    public func fetchBlocked(projectID: UUID) async throws -> [CodalonTask] {
        try await taskRepository.fetchBlocked(projectID: projectID)
    }

    public func fetchLaunchCritical(projectID: UUID) async throws -> [CodalonTask] {
        try await taskRepository.fetchLaunchCritical(projectID: projectID)
    }

    public func fetchWaitingExternal(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await taskRepository.fetchByProject(projectID)
        return all.filter { $0.waitingExternal && $0.deletedAt == nil }
    }

    // Issue #62 — Deep-work tasks
    public func fetchDeepWork(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await taskRepository.fetchByProject(projectID)
        return all.filter { $0.deletedAt == nil && $0.estimate ?? 0 >= 4.0 && $0.status != .done && $0.status != .cancelled }
    }

    // Issue #64 — Quick-win tasks
    public func fetchQuickWins(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await taskRepository.fetchByProject(projectID)
        return all.filter { $0.deletedAt == nil && $0.estimate ?? 0 > 0 && $0.estimate ?? 0 <= 1.0 && $0.status != .done && $0.status != .cancelled }
    }

    // MARK: - Issue #42 — Status Workflow

    public func changeStatus(taskID: UUID, to newStatus: CodalonTaskStatus) async throws {
        var task = try await taskRepository.load(id: taskID)
        let oldStatus = task.status
        guard Self.isValidTransition(from: oldStatus, to: newStatus) else {
            throw TaskServiceError.invalidTransition(from: oldStatus, to: newStatus)
        }
        task.status = newStatus
        task.updatedAt = Date()
        try await taskRepository.save(task)
        await publish(TaskStatusChangedEvent(
            taskID: task.id,
            projectID: task.projectID,
            oldStatus: oldStatus,
            newStatus: newStatus
        ))
    }

    // MARK: - Issue #44 — Priority

    public func changePriority(taskID: UUID, to priority: CodalonPriority) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.priority = priority
        task.updatedAt = Date()
        try await taskRepository.save(task)
        await publish(TaskUpdatedEvent(taskID: task.id, projectID: task.projectID))
    }

    // MARK: - Issue #46 — Estimates

    public func setEstimate(taskID: UUID, estimate: Double?) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.estimate = estimate
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #48 — Due Dates

    public func setDueDate(taskID: UUID, dueDate: Date?) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.dueDate = dueDate
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #50 — Milestone Link

    public func linkToMilestone(taskID: UUID, milestoneID: UUID?) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.milestoneID = milestoneID
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #52 — Epic Link

    public func linkToEpic(taskID: UUID, epicID: UUID?) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.epicID = epicID
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #54 — Dependencies

    public func addDependency(taskID: UUID, dependsOn: UUID) async throws {
        var task = try await taskRepository.load(id: taskID)
        let dependency = try await taskRepository.load(id: dependsOn)
        if dependency.status != .done {
            task.isBlocked = true
        }
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    public func removeDependency(taskID: UUID, dependsOn: UUID) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #56 — Blocked State

    public func setBlocked(taskID: UUID, isBlocked: Bool) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.isBlocked = isBlocked
        task.updatedAt = Date()
        try await taskRepository.save(task)
        if isBlocked {
            await publish(TaskBlockedEvent(taskID: task.id, projectID: task.projectID))
        }
    }

    // MARK: - Issue #58 — Waiting External

    public func setWaitingExternal(taskID: UUID, waiting: Bool) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.waitingExternal = waiting
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #60 — Launch Critical

    public func setLaunchCritical(taskID: UUID, isLaunchCritical: Bool) async throws {
        var task = try await taskRepository.load(id: taskID)
        task.isLaunchCritical = isLaunchCritical
        task.updatedAt = Date()
        try await taskRepository.save(task)
    }

    // MARK: - Issue #66 — Bulk Actions

    public func bulkChangeStatus(taskIDs: [UUID], to status: CodalonTaskStatus) async throws {
        for id in taskIDs {
            var task = try await taskRepository.load(id: id)
            task.status = status
            task.updatedAt = Date()
            try await taskRepository.save(task)
        }
    }

    public func bulkChangePriority(taskIDs: [UUID], to priority: CodalonPriority) async throws {
        for id in taskIDs {
            var task = try await taskRepository.load(id: id)
            task.priority = priority
            task.updatedAt = Date()
            try await taskRepository.save(task)
        }
    }

    public func bulkAssignMilestone(taskIDs: [UUID], milestoneID: UUID?) async throws {
        for id in taskIDs {
            var task = try await taskRepository.load(id: id)
            task.milestoneID = milestoneID
            task.updatedAt = Date()
            try await taskRepository.save(task)
        }
    }

    // MARK: - Issue #48 — Overdue Detection

    public func detectOverdue(projectID: UUID) async throws -> [CodalonTask] {
        let all = try await taskRepository.fetchByProject(projectID)
        let now = Date()
        return all.filter {
            $0.deletedAt == nil
                && $0.status != .done
                && $0.status != .cancelled
                && ($0.dueDate ?? .distantFuture) < now
        }
    }

    // MARK: - Status Transition Validation (#42)

    nonisolated static func isValidTransition(
        from: CodalonTaskStatus,
        to: CodalonTaskStatus
    ) -> Bool {
        switch from {
        case .backlog: return to == .todo || to == .cancelled
        case .todo: return to == .inProgress || to == .backlog || to == .cancelled
        case .inProgress: return to == .inReview || to == .todo || to == .cancelled
        case .inReview: return to == .done || to == .inProgress || to == .cancelled
        case .done: return to == .todo  // reopen
        case .cancelled: return to == .backlog  // restore
        }
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}

// MARK: - Error

public enum TaskServiceError: Error, Sendable {
    case invalidTransition(from: CodalonTaskStatus, to: CodalonTaskStatus)
}