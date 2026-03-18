// Issue #84 — Daily focus view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - DailyFocusViewModel

@Observable
final class DailyFocusViewModel {

    // MARK: - State

    var tasks: [CodalonTask] = []
    var isLoading = false
    var errorMessage: String?
    var reducedNoiseEnabled = false

    // MARK: - Dependencies

    private let taskService: any TaskServiceProtocol
    private let projectID: UUID

    // MARK: - Init

    init(taskService: any TaskServiceProtocol, projectID: UUID) {
        self.taskService = taskService
        self.projectID = projectID
    }

    // MARK: - Load

    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        do {
            tasks = try await taskService.fetchByProject(projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Filtered Tasks (reduced noise)

    private var activeTasks: [CodalonTask] {
        var result = tasks.filter {
            $0.deletedAt == nil && $0.status != .done && $0.status != .cancelled
        }
        if reducedNoiseEnabled {
            result = result.filter { $0.priority >= .high }
        }
        return result
    }

    // MARK: - Issue #86 — Top-3 Priorities

    var topPriorities: [CodalonTask] {
        Array(
            activeTasks
                .sorted { $0.priority > $1.priority }
                .prefix(3)
        )
    }

    // MARK: - Issue #88 — Follow-up Needed

    var followUpTasks: [CodalonTask] {
        activeTasks.filter { task in
            task.status == .inReview
                || (task.dueDate != nil && task.dueDate! < Date() && !task.isBlocked)
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    // MARK: - Issue #90 — Waiting on Third Party

    var waitingExternalTasks: [CodalonTask] {
        activeTasks.filter(\.waitingExternal)
            .sorted { $0.priority > $1.priority }
    }

    // MARK: - Issue #92 — Stuck Items

    var stuckTasks: [CodalonTask] {
        let staleThreshold = 7
        return activeTasks.filter { task in
            if task.isBlocked { return true }
            let daysSinceUpdate = Calendar.current.dateComponents(
                [.day], from: task.updatedAt, to: .now
            ).day ?? 0
            return daysSinceUpdate >= staleThreshold
        }
        .sorted { $0.priority > $1.priority }
    }

    // MARK: - Actions

    func changeStatus(taskID: UUID, to status: CodalonTaskStatus) async {
        do {
            try await taskService.changeStatus(taskID: taskID, to: status)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setBlocked(taskID: UUID, isBlocked: Bool) async {
        do {
            try await taskService.setBlocked(taskID: taskID, isBlocked: isBlocked)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setWaitingExternal(taskID: UUID, waiting: Bool) async {
        do {
            try await taskService.setWaitingExternal(taskID: taskID, waiting: waiting)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
