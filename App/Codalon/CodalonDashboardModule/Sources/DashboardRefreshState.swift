// Issue #152 — Dashboard refresh actions

import Foundation
import Observation

// MARK: - DashboardRefreshState

@MainActor
@Observable
final class DashboardRefreshState {

    var isRefreshing = false
    var lastRefreshDate: Date?

    private var widgetRefreshStates: [String: Bool] = [:]

    func isWidgetRefreshing(_ widgetID: String) -> Bool {
        widgetRefreshStates[widgetID] ?? false
    }

    func beginWidgetRefresh(_ widgetID: String) {
        widgetRefreshStates[widgetID] = true
        isRefreshing = true
    }

    func endWidgetRefresh(_ widgetID: String) {
        widgetRefreshStates[widgetID] = false
        if widgetRefreshStates.values.allSatisfy({ !$0 }) {
            isRefreshing = false
            lastRefreshDate = Date()
        }
    }

    func beginGlobalRefresh() {
        isRefreshing = true
    }

    func endGlobalRefresh() {
        isRefreshing = false
        lastRefreshDate = Date()
        widgetRefreshStates.removeAll()
    }
}
