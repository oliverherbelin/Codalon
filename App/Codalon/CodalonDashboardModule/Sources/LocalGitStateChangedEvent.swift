// Issue #176 — Reactive insight refresh after local git state changes

import Foundation
import HelaiaEngine

public struct LocalGitStateChangedEvent: HelaiaEvent {
    public let projectID: UUID
    public let unstagedCount: Int
    public let stagedCount: Int
    public let aheadCount: Int

    public init(
        projectID: UUID,
        unstagedCount: Int,
        stagedCount: Int,
        aheadCount: Int
    ) {
        self.projectID = projectID
        self.unstagedCount = unstagedCount
        self.stagedCount = stagedCount
        self.aheadCount = aheadCount
    }
}
