// Issue #8 — Shell state

import Foundation
import Observation

public enum CodalonInspectorSelection: Hashable, Sendable {
    case task(UUID)
    case milestone(UUID)
    case commit(String)
    case release(UUID)
    case crash(String)
    case review(String)
    case feedback(String)
    case project
}

@MainActor
@Observable
public final class CodalonShellState {

    public var activeContext: CodalonContext {
        didSet {
            UserDefaults.standard.set(
                activeContext.rawValue,
                forKey: Self.contextKey
            )
        }
    }
    public var healthState: CodalonHealthState = .noData
    public var activeMilestoneID: UUID?
    public var activeReleaseID: UUID?
    public var activeDistributionTargets: Set<CodalonDistributionTarget> = []
    public var isInspectorVisible = false
    public var inspectorSelection: CodalonInspectorSelection?
    public var isProjectSwitcherVisible = false
    public var projectName: String?
    public var projectIcon: String?
    public var projectColor: String?
    public var selectedProjectID: UUID?
    public var proposedContext: CodalonContext?

    private static let contextKey = "codalon.activeContext"

    public init() {
        if let raw = UserDefaults.standard.string(forKey: Self.contextKey),
           let restored = CodalonContext(rawValue: raw) {
            self.activeContext = restored
        } else {
            self.activeContext = .development
        }
    }
}
