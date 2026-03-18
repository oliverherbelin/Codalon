// Issue #151 — Release event tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Release Event Tests (#151)

@Suite("Release Events")
@MainActor
struct ReleaseEventTests {

    @Test("ReleaseCreatedEvent stores fields")
    func createdEvent() {
        let releaseID = UUID()
        let projectID = UUID()
        let event = ReleaseCreatedEvent(
            releaseID: releaseID,
            version: "1.0.0",
            projectID: projectID
        )

        #expect(event.releaseID == releaseID)
        #expect(event.version == "1.0.0")
        #expect(event.projectID == projectID)
    }

    @Test("ReleaseUpdatedEvent stores fields")
    func updatedEvent() {
        let releaseID = UUID()
        let event = ReleaseUpdatedEvent(
            releaseID: releaseID,
            version: "1.0.0"
        )

        #expect(event.releaseID == releaseID)
        #expect(event.version == "1.0.0")
    }

    @Test("ReleaseStatusChangedEvent stores old and new status")
    func statusChangedEvent() {
        let releaseID = UUID()
        let event = ReleaseStatusChangedEvent(
            releaseID: releaseID,
            oldStatus: .drafting,
            newStatus: .testing
        )

        #expect(event.releaseID == releaseID)
        #expect(event.oldStatus == .drafting)
        #expect(event.newStatus == .testing)
    }

    @Test("ReleaseReadinessChangedEvent stores old and new score")
    func readinessChangedEvent() {
        let releaseID = UUID()
        let event = ReleaseReadinessChangedEvent(
            releaseID: releaseID,
            oldScore: 35,
            newScore: 70
        )

        #expect(event.releaseID == releaseID)
        #expect(event.oldScore == 35)
        #expect(event.newScore == 70)
    }

    @Test("events have timestamp")
    func timestamps() {
        let before = Date.now
        let event = ReleaseCreatedEvent(
            releaseID: UUID(),
            version: "1.0.0",
            projectID: UUID()
        )
        let after = Date.now

        #expect(event.timestamp >= before)
        #expect(event.timestamp <= after)
    }
}
