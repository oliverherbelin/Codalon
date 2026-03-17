// Issue #123 — Dashboard route registration

import SwiftUI
import HelaiaEngine

// MARK: - DashboardRoute

enum DashboardRoute: HelaiaRoute, Sendable {
    case dashboard(projectID: UUID)

    var routeID: String {
        switch self {
        case .dashboard(let id):
            "dashboard.\(id.uuidString)"
        }
    }
}
