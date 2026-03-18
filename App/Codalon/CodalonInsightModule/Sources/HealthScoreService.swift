// Issue #162 — Health score service

import Foundation
import HelaiaEngine
import HelaiaLogger

// MARK: - Protocol

public protocol HealthScoreServiceProtocol: Sendable {
    func recalculate(projectID: UUID) async throws -> HealthScoreResult
}

// MARK: - Result

public struct HealthScoreResult: Sendable, Equatable {
    public let overallScore: Double
    public let dimensions: [HealthScoreDimension]

    nonisolated public init(overallScore: Double, dimensions: [HealthScoreDimension]) {
        self.overallScore = overallScore
        self.dimensions = dimensions
    }
}

// MARK: - Implementation

public actor HealthScoreService: HealthScoreServiceProtocol {

    private let taskRepository: any TaskRepositoryProtocol
    private let milestoneRepository: any MilestoneRepositoryProtocol
    private let releaseRepository: any ReleaseRepositoryProtocol
    private let alertRepository: any AlertRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        taskRepository: any TaskRepositoryProtocol,
        milestoneRepository: any MilestoneRepositoryProtocol,
        releaseRepository: any ReleaseRepositoryProtocol,
        alertRepository: any AlertRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.taskRepository = taskRepository
        self.milestoneRepository = milestoneRepository
        self.releaseRepository = releaseRepository
        self.alertRepository = alertRepository
        self.logger = logger
    }

    public func recalculate(projectID: UUID) async throws -> HealthScoreResult {
        logger.info("Recalculating health score for project \(projectID)", category: "insight")

        let planning = try await calculatePlanningHealth(projectID: projectID)
        let release = try await calculateReleaseHealth(projectID: projectID)
        let github = HealthScoreDimension(
            id: HealthScoreDimensionID.github,
            label: "GitHub",
            value: 1.0
        )
        let store = HealthScoreDimension(
            id: HealthScoreDimensionID.store,
            label: "App Store",
            value: 1.0
        )

        let dimensions = [planning, release, github, store]
        let totalWeight = dimensions.reduce(0) { $0 + $1.weight }
        let weightedSum = dimensions.reduce(0) { $0 + $1.value * $1.weight }
        let overall = totalWeight > 0 ? weightedSum / totalWeight : 0

        logger.info("Health score: \(Int(overall * 100))%", category: "insight")

        return HealthScoreResult(overallScore: overall, dimensions: dimensions)
    }

    // MARK: - Private

    private func calculatePlanningHealth(projectID: UUID) async throws -> HealthScoreDimension {
        let tasks = try await taskRepository.fetchByProject(projectID)
            .filter { $0.deletedAt == nil }
        let completedTasks = tasks.filter { $0.status == .done }.count
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status != .done && task.status != .cancelled
        }.count

        let milestones = try await milestoneRepository.fetchByProject(projectID)
            .filter { $0.deletedAt == nil }
        let avgProgress = milestones.isEmpty ? 0 : milestones.reduce(0) { $0 + $1.progress } / Double(milestones.count)

        let value = PlanningHealthCalculator.calculate(
            totalTasks: tasks.count,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
            milestoneProgress: avgProgress
        )

        return HealthScoreDimension(
            id: HealthScoreDimensionID.planning,
            label: "Planning",
            value: value
        )
    }

    private func calculateReleaseHealth(projectID: UUID) async throws -> HealthScoreDimension {
        let activeRelease = try await releaseRepository.fetchActive(projectID: projectID)

        guard let release = activeRelease else {
            return HealthScoreDimension(
                id: HealthScoreDimensionID.release,
                label: "Release",
                value: 1.0
            )
        }

        let value = ReleaseHealthCalculator.calculate(
            readinessScore: release.readinessScore,
            blockerCount: release.blockerCount,
            hasTargetDate: release.targetDate != nil
        )

        return HealthScoreDimension(
            id: HealthScoreDimensionID.release,
            label: "Release",
            value: value
        )
    }
}
