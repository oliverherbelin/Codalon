// Issue #120 — Project summary calculations

import Foundation

// MARK: - Protocol

public protocol ProjectSummaryServiceProtocol: Sendable {
    func summary(for projectID: UUID) async throws -> ProjectSummary
}

// MARK: - Implementation

public actor ProjectSummaryService: ProjectSummaryServiceProtocol {

    private let projectRepository: any ProjectRepositoryProtocol
    private let taskRepository: any TaskRepositoryProtocol
    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol

    public init(
        projectRepository: any ProjectRepositoryProtocol,
        taskRepository: any TaskRepositoryProtocol,
        milestoneRepository: any MilestoneRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol
    ) {
        self.projectRepository = projectRepository
        self.taskRepository = taskRepository
        self.milestoneRepository = milestoneRepository
        self.releaseRepository = releaseRepository
    }

    public func summary(for projectID: UUID) async throws -> ProjectSummary {
        let tasks = try await taskRepository.fetchByProject(projectID)
        let openTasks = tasks.filter { isOpen($0.status) && $0.deletedAt == nil }

        let milestones = try await milestoneRepository.fetchByProject(projectID)
        let activeMilestones = milestones.filter { $0.deletedAt == nil }

        let activeRelease = try await releaseRepository.fetchActive(projectID: projectID)

        let project = try await projectRepository.load(id: projectID)

        return ProjectSummary(
            projectID: projectID,
            openTaskCount: openTasks.count,
            milestoneCount: activeMilestones.count,
            activeReleaseVersion: activeRelease?.version,
            healthScore: project.healthScore
        )
    }

    private func isOpen(_ status: CodalonTaskStatus) -> Bool {
        switch status {
        case .backlog, .todo, .inProgress, .inReview:
            return true
        case .done, .cancelled:
            return false
        }
    }
}
