// Issues #22, #36, #72 — Planning route registration

import SwiftUI
import HelaiaEngine

// MARK: - PlanningRoute

enum PlanningRoute: HelaiaRoute, Sendable {
    case planning(projectID: UUID)
    case milestoneDetail(milestoneID: UUID)
    case tasks(projectID: UUID)
    case taskDetail(taskID: UUID)
    case decisionLog(projectID: UUID)

    var routeID: String {
        switch self {
        case .planning(let id):
            "planning.\(id.uuidString)"
        case .milestoneDetail(let id):
            "milestone.\(id.uuidString)"
        case .tasks(let id):
            "tasks.\(id.uuidString)"
        case .taskDetail(let id):
            "task.\(id.uuidString)"
        case .decisionLog(let id):
            "decisionlog.\(id.uuidString)"
        }
    }
}
