// Issue #153 — Alert-to-route linking

import Foundation

// MARK: - AlertRoute

/// Parsed representation of an alert's actionRoute string.
public enum AlertRoute: Sendable, Equatable {
    case release(projectID: UUID, releaseID: UUID)
    case milestone(projectID: UUID, milestoneID: UUID)
    case build(projectID: UUID)
    case appStore(projectID: UUID)
    case insight(projectID: UUID, insightID: UUID)
    case settings
    case unknown(String)

    // MARK: - Parse

    /// Parses an actionRoute string into a typed route.
    /// Format: "type/param1/param2"
    public static func parse(_ route: String?) -> AlertRoute? {
        guard let route, !route.isEmpty else { return nil }

        let parts = route.split(separator: "/").map(String.init)
        guard !parts.isEmpty else { return nil }

        switch parts[0] {
        case "release":
            guard parts.count >= 3,
                  let projectID = UUID(uuidString: parts[1]),
                  let releaseID = UUID(uuidString: parts[2])
            else { return .unknown(route) }
            return .release(projectID: projectID, releaseID: releaseID)

        case "milestone":
            guard parts.count >= 3,
                  let projectID = UUID(uuidString: parts[1]),
                  let milestoneID = UUID(uuidString: parts[2])
            else { return .unknown(route) }
            return .milestone(projectID: projectID, milestoneID: milestoneID)

        case "build":
            guard parts.count >= 2,
                  let projectID = UUID(uuidString: parts[1])
            else { return .unknown(route) }
            return .build(projectID: projectID)

        case "appstore":
            guard parts.count >= 2,
                  let projectID = UUID(uuidString: parts[1])
            else { return .unknown(route) }
            return .appStore(projectID: projectID)

        case "insight":
            guard parts.count >= 3,
                  let projectID = UUID(uuidString: parts[1]),
                  let insightID = UUID(uuidString: parts[2])
            else { return .unknown(route) }
            return .insight(projectID: projectID, insightID: insightID)

        case "settings":
            return .settings

        default:
            return .unknown(route)
        }
    }

    // MARK: - Encode

    /// Encodes this route back to a string for storage.
    public var routeString: String {
        switch self {
        case let .release(projectID, releaseID):
            "release/\(projectID.uuidString)/\(releaseID.uuidString)"
        case let .milestone(projectID, milestoneID):
            "milestone/\(projectID.uuidString)/\(milestoneID.uuidString)"
        case let .build(projectID):
            "build/\(projectID.uuidString)"
        case let .appStore(projectID):
            "appstore/\(projectID.uuidString)"
        case let .insight(projectID, insightID):
            "insight/\(projectID.uuidString)/\(insightID.uuidString)"
        case .settings:
            "settings"
        case let .unknown(raw):
            raw
        }
    }
}
