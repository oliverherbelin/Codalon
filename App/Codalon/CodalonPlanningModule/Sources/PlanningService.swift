// Issues #26, #28 — Planning service (milestone progress, overdue detection)

import Foundation
import HelaiaEngine

// MARK: - Protocol

public protocol PlanningServiceProtocol: Sendable {
    func create(_ milestone: CodalonMilestone) async throws
    func update(_ milestone: CodalonMilestone) async throws
    func delete(id: UUID) async throws
    func load(id: UUID) async throws -> CodalonMilestone
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone]
    func fetchByStatus(
        _ status: CodalonMilestoneStatus,
        projectID: UUID
    ) async throws -> [CodalonMilestone]
    func recalculateProgress(milestoneID: UUID) async throws -> Double
    func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone]
}

// MARK: - Implementation

public actor PlanningService: PlanningServiceProtocol {

    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let taskRepository: any TaskRepositoryProtocol

    public init(
        milestoneRepository: any MilestoneRepositoryProtocol,
        taskRepository: any TaskRepositoryProtocol
    ) {
        self.milestoneRepository = milestoneRepository
        self.taskRepository = taskRepository
    }

    // MARK: - CRUD

    public func create(_ milestone: CodalonMilestone) async throws {
        try await milestoneRepository.save(milestone)
        await publish(MilestoneCreatedEvent(
            milestoneID: milestone.id,
            projectID: milestone.projectID,
            title: milestone.title
        ))
    }

    public func update(_ milestone: CodalonMilestone) async throws {
        var updated = milestone
        updated.updatedAt = Date()
        try await milestoneRepository.save(updated)

        if updated.status == .completed {
            await publish(MilestoneCompletedEvent(
                milestoneID: updated.id,
                projectID: updated.projectID
            ))
        } else {
            await publish(MilestoneUpdatedEvent(
                milestoneID: updated.id,
                projectID: updated.projectID
            ))
        }
    }

    public func delete(id: UUID) async throws {
        try await milestoneRepository.delete(id: id)
    }

    public func load(id: UUID) async throws -> CodalonMilestone {
        try await milestoneRepository.load(id: id)
    }

    public func fetchByProject(_ projectID: UUID) async throws -> [CodalonMilestone] {
        try await milestoneRepository.fetchByProject(projectID)
    }

    public func fetchByStatus(
        _ status: CodalonMilestoneStatus,
        projectID: UUID
    ) async throws -> [CodalonMilestone] {
        try await milestoneRepository.fetchByStatus(status, projectID: projectID)
    }

    // MARK: - Issue #26 — Progress Calculation

    public func recalculateProgress(milestoneID: UUID) async throws -> Double {
        let tasks = try await taskRepository.fetchByMilestone(milestoneID)
        guard !tasks.isEmpty else { return 0 }

        let completedCount = tasks.filter { $0.status == .done }.count
        let progress = Double(completedCount) / Double(tasks.count)

        var milestone = try await milestoneRepository.load(id: milestoneID)
        milestone.progress = progress
        milestone.updatedAt = Date()
        try await milestoneRepository.save(milestone)

        return progress
    }

    // MARK: - Issue #28 — Overdue Detection

    public func detectOverdue(projectID: UUID) async throws -> [CodalonMilestone] {
        let overdue = try await milestoneRepository.fetchOverdue(projectID: projectID)

        for milestone in overdue {
            guard let dueDate = milestone.dueDate else { continue }
            await publish(MilestoneOverdueDetectedEvent(
                milestoneID: milestone.id,
                projectID: milestone.projectID,
                dueDate: dueDate
            ))
        }

        return overdue
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}
