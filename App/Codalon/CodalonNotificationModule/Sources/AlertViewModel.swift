// Issues #139, #143, #146 — Alert center view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - AlertViewModel

@Observable
final class AlertViewModel {

    // MARK: - State

    var alerts: [CodalonAlert] = []
    var isLoading = false
    var errorMessage: String?

    // Issue #143 — Unread handling
    var unreadCount = 0

    // Issue #146 — Filters
    var severityFilter: CodalonSeverity?
    var categoryFilter: CodalonAlertCategory?
    var readStateFilter: CodalonAlertReadState?
    var searchQuery = ""

    // MARK: - Dependencies

    private let alertRepository: any AlertRepositoryProtocol
    private let dismissalService: any AlertDismissalServiceProtocol
    let projectID: UUID

    // MARK: - Init

    init(
        alertRepository: any AlertRepositoryProtocol,
        dismissalService: any AlertDismissalServiceProtocol,
        projectID: UUID
    ) {
        self.alertRepository = alertRepository
        self.dismissalService = dismissalService
        self.projectID = projectID
    }

    // MARK: - Load

    func loadAlerts() async {
        isLoading = true
        do {
            alerts = try await alertRepository.fetchByProject(projectID)
            unreadCount = alerts.filter { $0.readState == .unread }.count
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Issue #143 — Mark Read / Unread

    func markRead(id: UUID) async {
        do {
            try await alertRepository.markRead(id: id)
            if let index = alerts.firstIndex(where: { $0.id == id }) {
                alerts[index].readState = .read
            }
            unreadCount = alerts.filter { $0.readState == .unread }.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismiss(id: UUID) async {
        do {
            try await alertRepository.dismiss(id: id)
            if let index = alerts.firstIndex(where: { $0.id == id }) {
                alerts[index].readState = .dismissed
            }
            unreadCount = alerts.filter { $0.readState == .unread }.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runAutoDismissals() async {
        do {
            let count = try await dismissalService.evaluateDismissals(projectID: projectID)
            if count > 0 {
                await loadAlerts()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Issue #146 — Filtered + Sorted

    /// Alerts sorted by severity (descending) then date (newest first),
    /// with active filters applied.
    var filteredAlerts: [CodalonAlert] {
        var result = alerts

        // Exclude dismissed unless explicitly filtering for them
        if readStateFilter != .dismissed {
            result = result.filter { $0.readState != .dismissed }
        }

        if let severityFilter {
            result = result.filter { $0.severity == severityFilter }
        }

        if let categoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }

        if let readStateFilter {
            result = result.filter { $0.readState == readStateFilter }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                    || $0.message.lowercased().contains(query)
            }
        }

        // Sort: severity descending, then newest first
        return result.sorted { lhs, rhs in
            if lhs.severity != rhs.severity {
                return lhs.severity > rhs.severity
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var hasActiveFilters: Bool {
        severityFilter != nil || categoryFilter != nil || readStateFilter != nil || !searchQuery.isEmpty
    }

    func clearFilters() {
        severityFilter = nil
        categoryFilter = nil
        readStateFilter = nil
        searchQuery = ""
    }

    // MARK: - Issue #153 — Route

    func route(for alert: CodalonAlert) -> AlertRoute? {
        AlertRoute.parse(alert.actionRoute)
    }
}
