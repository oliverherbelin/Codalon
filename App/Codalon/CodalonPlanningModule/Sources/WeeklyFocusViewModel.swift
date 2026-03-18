// Issue #82 — Weekly focus view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - WeeklyFocusViewModel

@Observable
final class WeeklyFocusViewModel {

    // MARK: - State

    var tasks: [CodalonTask] = []
    var milestones: [CodalonMilestone] = []
    var recentDecisions: [CodalonDecisionLogEntry] = []
    var isLoading = false
    var errorMessage: String?
    var reducedNoiseEnabled = false

    // MARK: - Dependencies

    private let taskService: any TaskServiceProtocol
    private let planningService: any PlanningServiceProtocol
    private let decisionRepository: any DecisionLogRepositoryProtocol
    private let projectID: UUID

    // MARK: - Init

    init(
        taskService: any TaskServiceProtocol,
        planningService: any PlanningServiceProtocol,
        decisionRepository: any DecisionLogRepositoryProtocol,
        projectID: UUID
    ) {
        self.taskService = taskService
        self.planningService = planningService
        self.decisionRepository = decisionRepository
        self.projectID = projectID
    }

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedTasks = taskService.fetchByProject(projectID)
            async let fetchedMilestones = planningService.fetchByProject(projectID)
            async let fetchedDecisions = decisionRepository.fetchByProject(projectID)

            tasks = try await fetchedTasks
            milestones = try await fetchedMilestones
            recentDecisions = try await fetchedDecisions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Derived State

    private var activeTasks: [CodalonTask] {
        var result = tasks.filter {
            $0.deletedAt == nil && $0.status != .done && $0.status != .cancelled
        }
        if reducedNoiseEnabled {
            result = result.filter { $0.priority >= .high }
        }
        return result
    }

    var activeMilestone: CodalonMilestone? {
        milestones
            .filter { $0.deletedAt == nil && $0.status == .active }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
    }

    var topTasksThisWeek: [CodalonTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) else {
            return Array(activeTasks.sorted { $0.priority > $1.priority }.prefix(5))
        }

        let thisWeek = activeTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            let dayStart = calendar.startOfDay(for: dueDate)
            return dayStart <= weekFromNow
        }
        .sorted { $0.priority > $1.priority }

        if thisWeek.isEmpty {
            return Array(activeTasks.sorted { $0.priority > $1.priority }.prefix(5))
        }
        return Array(thisWeek.prefix(5))
    }

    var overdueCount: Int {
        let now = Date()
        return activeTasks.filter { ($0.dueDate ?? .distantFuture) < now }.count
    }

    var blockedCount: Int {
        activeTasks.filter(\.isBlocked).count
    }

    var completedThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return tasks.filter {
            $0.status == .done && $0.updatedAt >= weekAgo && $0.deletedAt == nil
        }.count
    }

    var latestDecisions: [CodalonDecisionLogEntry] {
        Array(
            recentDecisions
                .filter { $0.deletedAt == nil }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(3)
        )
    }
}
