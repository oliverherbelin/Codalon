// Issue #8 — Shell environment keys

import SwiftUI

// MARK: - Supporting Types

public enum CodalonHealthState: Sendable, Hashable {
    case healthy
    case warning(String)
    case critical(String)
    case noData
}

public enum CodalonDistributionTarget: String, Hashable, Sendable {
    case appStore
    case testFlight
    case gitHubRelease
    case directDownload
    case homebrew
    case none
}

// MARK: - Environment Keys

struct ProjectContextKey: EnvironmentKey {
    static let defaultValue: CodalonContext = .development
}

struct HealthStateKey: EnvironmentKey {
    static let defaultValue: CodalonHealthState = .noData
}

struct ActiveMilestoneIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

struct ActiveReleaseIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

struct ActiveDistributionTargetsKey: EnvironmentKey {
    static let defaultValue: Set<CodalonDistributionTarget> = []
}

// MARK: - EnvironmentValues Extensions

public extension EnvironmentValues {

    var projectContext: CodalonContext {
        get { self[ProjectContextKey.self] }
        set { self[ProjectContextKey.self] = newValue }
    }

    var healthState: CodalonHealthState {
        get { self[HealthStateKey.self] }
        set { self[HealthStateKey.self] = newValue }
    }

    var activeMilestoneID: UUID? {
        get { self[ActiveMilestoneIDKey.self] }
        set { self[ActiveMilestoneIDKey.self] = newValue }
    }

    var activeReleaseID: UUID? {
        get { self[ActiveReleaseIDKey.self] }
        set { self[ActiveReleaseIDKey.self] = newValue }
    }

    var activeDistributionTargets: Set<CodalonDistributionTarget> {
        get { self[ActiveDistributionTargetsKey.self] }
        set { self[ActiveDistributionTargetsKey.self] = newValue }
    }
}
