// Issues #36, #42, #44, #46, #48, #50, #52, #54, #56, #58, #60, #62, #64, #66, #68, #70 — Task view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - TaskViewModel

@Observable
final class TaskViewModel {

    // MARK: - State

    var tasks: [CodalonTask] = []
    var isLoading = false
    var errorMessage: String?
    var selectedTaskIDs: Set<UUID> = []

    // MARK: - Filters

    var statusFilter: CodalonTaskStatus?
    var priorityFilter: CodalonPriority?
    var searchQuery: String = ""
    var sortMode: TaskSortMode = .priority
    var groupMode: TaskGroupMode = .status
    var showBlocked = false
    var showLaunchCritical = false
    var showWaitingExternal = false
    var showDeepWork = false
    var showQuickWins = false

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

    // MARK: - CRUD

    func createTask(_ task: CodalonTask) async {
        do {
            try await taskService.create(task)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTask(_ task: CodalonTask) async {
        do {
            try await taskService.update(task)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(id: UUID) async {
        do {
            try await taskService.delete(id: id)
            selectedTaskIDs.remove(id)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #42 — Status Change

    func changeStatus(taskID: UUID, to status: CodalonTaskStatus) async {
        do {
            try await taskService.changeStatus(taskID: taskID, to: status)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #44 — Priority

    func changePriority(taskID: UUID, to priority: CodalonPriority) async {
        do {
            try await taskService.changePriority(taskID: taskID, to: priority)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #50 — Milestone Link

    func linkToMilestone(taskID: UUID, milestoneID: UUID?) async {
        do {
            try await taskService.linkToMilestone(taskID: taskID, milestoneID: milestoneID)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #52 — Epic Link

    func linkToEpic(taskID: UUID, epicID: UUID?) async {
        do {
            try await taskService.linkToEpic(taskID: taskID, epicID: epicID)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #56 — Blocked

    func setBlocked(taskID: UUID, isBlocked: Bool) async {
        do {
            try await taskService.setBlocked(taskID: taskID, isBlocked: isBlocked)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #58 — Waiting External

    func setWaitingExternal(taskID: UUID, waiting: Bool) async {
        do {
            try await taskService.setWaitingExternal(taskID: taskID, waiting: waiting)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #60 — Launch Critical

    func setLaunchCritical(taskID: UUID, isLaunchCritical: Bool) async {
        do {
            try await taskService.setLaunchCritical(taskID: taskID, isLaunchCritical: isLaunchCritical)
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #66 — Bulk Actions

    func bulkChangeStatus(to status: CodalonTaskStatus) async {
        let ids = Array(selectedTaskIDs)
        do {
            try await taskService.bulkChangeStatus(taskIDs: ids, to: status)
            selectedTaskIDs.removeAll()
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bulkChangePriority(to priority: CodalonPriority) async {
        let ids = Array(selectedTaskIDs)
        do {
            try await taskService.bulkChangePriority(taskIDs: ids, to: priority)
            selectedTaskIDs.removeAll()
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bulkAssignMilestone(milestoneID: UUID?) async {
        let ids = Array(selectedTaskIDs)
        do {
            try await taskService.bulkAssignMilestone(taskIDs: ids, milestoneID: milestoneID)
            selectedTaskIDs.removeAll()
            await loadTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Selection

    func toggleSelection(taskID: UUID) {
        if selectedTaskIDs.contains(taskID) {
            selectedTaskIDs.remove(taskID)
        } else {
            selectedTaskIDs.insert(taskID)
        }
    }

    func selectAll() {
        selectedTaskIDs = Set(filteredTasks.map(\.id))
    }

    func deselectAll() {
        selectedTaskIDs.removeAll()
    }

    var hasSelection: Bool { !selectedTaskIDs.isEmpty }

    // MARK: - Filtered & Sorted

    var filteredTasks: [CodalonTask] {
        var result = tasks.filter { $0.deletedAt == nil }

        if let statusFilter {
            result = result.filter { $0.status == statusFilter }
        }
        if let priorityFilter {
            result = result.filter { $0.priority == priorityFilter }
        }
        if showBlocked {
            result = result.filter(\.isBlocked)
        }
        if showLaunchCritical {
            result = result.filter(\.isLaunchCritical)
        }
        if showWaitingExternal {
            result = result.filter(\.waitingExternal)
        }
        if showDeepWork {
            result = result.filter { $0.estimate ?? 0 >= 4.0 && $0.status != .done && $0.status != .cancelled }
        }
        if showQuickWins {
            result = result.filter { $0.estimate ?? 0 > 0 && $0.estimate ?? 0 <= 1.0 && $0.status != .done && $0.status != .cancelled }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                    || $0.summary.lowercased().contains(query)
            }
        }

        switch sortMode {
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .dueDate:
            result.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .status:
            result.sort { $0.status.sortOrder < $1.status.sortOrder }
        case .estimate:
            result.sort { ($0.estimate ?? 0) > ($1.estimate ?? 0) }
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        }

        return result
    }

    // MARK: - Grouped

    var tasksByStatus: [CodalonTaskStatus: [CodalonTask]] {
        var grouped: [CodalonTaskStatus: [CodalonTask]] = [:]
        for status in CodalonTaskStatus.allCases {
            grouped[status] = filteredTasks.filter { $0.status == status }
        }
        return grouped
    }

    // MARK: - Issue #70 — Today/Next/Later

    var todayTasks: [CodalonTask] {
        let calendar = Calendar.current
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDateInToday(dueDate) && task.status != .done && task.status != .cancelled
        }
    }

    var nextTasks: [CodalonTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) else { return [] }
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            let dayStart = calendar.startOfDay(for: dueDate)
            return dayStart > today && dayStart <= weekFromNow && task.status != .done && task.status != .cancelled
        }
    }

    var laterTasks: [CodalonTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) else { return [] }
        return filteredTasks.filter { task in
            guard let dueDate = task.dueDate else { return true }
            let dayStart = calendar.startOfDay(for: dueDate)
            return dayStart > weekFromNow && task.status != .done && task.status != .cancelled
        }.filter { $0.status != .done && $0.status != .cancelled }
    }

    // MARK: - Overdue

    var overdueTasks: [CodalonTask] {
        let now = Date()
        return filteredTasks.filter {
            $0.status != .done && $0.status != .cancelled
                && ($0.dueDate ?? .distantFuture) < now
        }
    }
}

// MARK: - TaskSortMode

enum TaskSortMode: String, CaseIterable, Sendable {
    case priority
    case dueDate
    case status
    case estimate
    case title

    nonisolated var label: String {
        switch self {
        case .priority: "Priority"
        case .dueDate: "Due Date"
        case .status: "Status"
        case .estimate: "Estimate"
        case .title: "Title"
        }
    }
}

// MARK: - TaskGroupMode

enum TaskGroupMode: String, CaseIterable, Sendable {
    case status
    case priority
    case milestone
    case epic

    nonisolated var label: String {
        switch self {
        case .status: "Status"
        case .priority: "Priority"
        case .milestone: "Milestone"
        case .epic: "Epic"
        }
    }
}

// MARK: - CodalonTaskStatus Sort Order

extension CodalonTaskStatus {
    nonisolated var sortOrder: Int {
        switch self {
        case .backlog: 0
        case .todo: 1
        case .inProgress: 2
        case .inReview: 3
        case .done: 4
        case .cancelled: 5
        }
    }
}