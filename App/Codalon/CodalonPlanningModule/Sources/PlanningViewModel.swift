// Issues #22, #23, #26, #28, #32, #33 — Planning view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - PlanningViewModel

@Observable
final class PlanningViewModel {

    // MARK: - State

    var milestones: [CodalonMilestone] = []
    var tasks: [UUID: [CodalonTask]] = [:]
    var isLoading = false
    var errorMessage: String?

    // MARK: - Filters (#32)

    var statusFilter: CodalonMilestoneStatus?
    var priorityFilter: CodalonPriority?
    var sortMode: SortMode = .dueDate
    var searchQuery: String = ""

    // MARK: - Dependencies

    private let planningService: any PlanningServiceProtocol
    private let taskRepository: any TaskRepositoryProtocol
    private let projectID: UUID

    // MARK: - Init

    init(
        planningService: any PlanningServiceProtocol,
        taskRepository: any TaskRepositoryProtocol,
        projectID: UUID
    ) {
        self.planningService = planningService
        self.taskRepository = taskRepository
        self.projectID = projectID
    }

    // MARK: - Load

    func loadMilestones() async {
        isLoading = true
        errorMessage = nil
        do {
            milestones = try await planningService.fetchByProject(projectID)
            await detectOverdue()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadTasks(for milestoneID: UUID) async {
        do {
            let milestoneTasks = try await taskRepository.fetchByMilestone(milestoneID)
            tasks[milestoneID] = milestoneTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #26 — Recalculate Progress

    func recalculateProgress(for milestoneID: UUID) async {
        do {
            let progress = try await planningService.recalculateProgress(milestoneID: milestoneID)
            if let index = milestones.firstIndex(where: { $0.id == milestoneID }) {
                milestones[index].progress = progress
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #28 — Overdue Detection

    func detectOverdue() async {
        _ = try? await planningService.detectOverdue(projectID: projectID)
    }

    // MARK: - CRUD

    func createMilestone(_ milestone: CodalonMilestone) async {
        do {
            try await planningService.create(milestone)
            await loadMilestones()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateMilestone(_ milestone: CodalonMilestone) async {
        do {
            try await planningService.update(milestone)
            await loadMilestones()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMilestone(id: UUID) async {
        do {
            try await planningService.delete(id: id)
            await loadMilestones()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #32 — Filtered & Sorted Results

    var filteredMilestones: [CodalonMilestone] {
        var result = milestones.filter { $0.deletedAt == nil }

        if let statusFilter {
            result = result.filter { $0.status == statusFilter }
        }
        if let priorityFilter {
            result = result.filter { $0.priority == priorityFilter }
        }

        // Issue #33 — Search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                    || $0.summary.lowercased().contains(query)
            }
        }

        switch sortMode {
        case .dueDate:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .progress:
            result.sort { $0.progress > $1.progress }
        }

        return result
    }

    // MARK: - Grouped by Status (#30 — Board View)

    var milestonesByStatus: [CodalonMilestoneStatus: [CodalonMilestone]] {
        let filtered = filteredMilestones
        var grouped: [CodalonMilestoneStatus: [CodalonMilestone]] = [:]
        for status in CodalonMilestoneStatus.allCases {
            grouped[status] = filtered.filter { $0.status == status }
        }
        return grouped
    }
}

// MARK: - SortMode

extension PlanningViewModel {

    enum SortMode: String, CaseIterable, Sendable {
        case dueDate
        case priority
        case progress

        var label: String {
            switch self {
            case .dueDate: "Due Date"
            case .priority: "Priority"
            case .progress: "Progress"
            }
        }
    }
}
