// Issue #22 — Planning route registration

import SwiftUI
import HelaiaEngine

// MARK: - PlanningRoute

enum PlanningRoute: HelaiaRoute, Sendable {
    case planning(projectID: UUID)
    case milestoneDetail(milestoneID: UUID)

    var routeID: String {
        switch self {
        case .planning(let id):
            "planning.\(id.uuidString)"
        case .milestoneDetail(let id):
            "milestone.\(id.uuidString)"
        }
    }
}
