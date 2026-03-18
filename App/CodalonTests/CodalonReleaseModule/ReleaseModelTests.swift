// Issues #16, #133, #136, #141, #148 — Release model and blocker tests

import Foundation
import Testing
@testable import Codalon

// MARK: - CodalonRelease Entity Tests (#16)

@Suite("CodalonRelease")
@MainActor
struct ReleaseModelTests {

    @Test("default values on init")
    func defaults() {
        let projectID = UUID()
        let release = CodalonRelease(projectID: projectID, version: "1.0.0")

        #expect(release.projectID == projectID)
        #expect(release.version == "1.0.0")
        #expect(release.buildNumber == "1")
        #expect(release.targetDate == nil)
        #expect(release.status == .drafting)
        #expect(release.readinessScore == 0)
        #expect(release.checklistItems.isEmpty)
        #expect(release.blockerCount == 0)
        #expect(release.linkedMilestoneID == nil)
        #expect(release.linkedTaskIDs.isEmpty)
        #expect(release.linkedGitHubIssueRefs.isEmpty)
        #expect(release.blockers.isEmpty)
        #expect(release.deletedAt == nil)
        #expect(release.schemaVersion == 1)
    }

    @Test("custom init populates all fields")
    func customInit() {
        let milestoneID = UUID()
        let taskID = UUID()
        let release = CodalonRelease(
            projectID: UUID(),
            version: "2.1.0",
            buildNumber: "45",
            targetDate: Date(),
            status: .testing,
            readinessScore: 75,
            checklistItems: [CodalonChecklistItem(title: "Done", isComplete: true)],
            blockerCount: 2,
            linkedMilestoneID: milestoneID,
            linkedTaskIDs: [taskID],
            linkedGitHubIssueRefs: ["owner/repo#10"],
            blockers: [CodalonReleaseBlocker(title: "Bug", severity: .error)]
        )

        #expect(release.version == "2.1.0")
        #expect(release.buildNumber == "45")
        #expect(release.status == .testing)
        #expect(release.readinessScore == 75)
        #expect(release.checklistItems.count == 1)
        #expect(release.blockerCount == 2)
        #expect(release.linkedMilestoneID == milestoneID)
        #expect(release.linkedTaskIDs == [taskID])
        #expect(release.linkedGitHubIssueRefs == ["owner/repo#10"])
        #expect(release.blockers.count == 1)
    }

    @Test("equatable compares by value")
    func equatable() {
        let id = UUID()
        let date = Date()
        let a = CodalonRelease(id: id, createdAt: date, updatedAt: date, projectID: UUID(), version: "1.0.0")
        let b = CodalonRelease(id: id, createdAt: date, updatedAt: date, projectID: a.projectID, version: "1.0.0")

        #expect(a == b)
    }
}

// MARK: - Release Status Tests (#148)

@Suite("CodalonReleaseStatus")
@MainActor
struct ReleaseStatusTests {

    @Test("all 10 cases exist")
    func allCases() {
        #expect(CodalonReleaseStatus.allCases.count == 10)
    }

    @Test("cases are correct")
    func caseValues() {
        let cases = CodalonReleaseStatus.allCases
        #expect(cases.contains(.drafting))
        #expect(cases.contains(.readyForQA))
        #expect(cases.contains(.testing))
        #expect(cases.contains(.readyForSubmission))
        #expect(cases.contains(.submitted))
        #expect(cases.contains(.inReview))
        #expect(cases.contains(.approved))
        #expect(cases.contains(.released))
        #expect(cases.contains(.rejected))
        #expect(cases.contains(.cancelled))
    }
}

// MARK: - Blocker Tests (#141)

@Suite("CodalonReleaseBlocker")
@MainActor
struct ReleaseBlockerTests {

    @Test("default values on init")
    func defaults() {
        let blocker = CodalonReleaseBlocker(title: "Bug")

        #expect(blocker.title == "Bug")
        #expect(blocker.source == "")
        #expect(blocker.severity == .warning)
        #expect(blocker.isResolved == false)
    }

    @Test("custom init populates all fields")
    func customInit() {
        let blocker = CodalonReleaseBlocker(
            title: "Crash on launch",
            source: "QA",
            severity: .critical,
            isResolved: true
        )

        #expect(blocker.title == "Crash on launch")
        #expect(blocker.source == "QA")
        #expect(blocker.severity == .critical)
        #expect(blocker.isResolved == true)
    }

    @Test("equatable compares id, title, source, severity, isResolved")
    func equatable() {
        let id = UUID()
        let a = CodalonReleaseBlocker(id: id, title: "Bug", source: "QA", severity: .error, isResolved: false)
        let b = CodalonReleaseBlocker(id: id, title: "Bug", source: "QA", severity: .error, isResolved: false)

        #expect(a == b)
    }

    @Test("different isResolved means not equal")
    func notEqualResolved() {
        let id = UUID()
        let a = CodalonReleaseBlocker(id: id, title: "Bug", severity: .error, isResolved: false)
        let b = CodalonReleaseBlocker(id: id, title: "Bug", severity: .error, isResolved: true)

        #expect(a != b)
    }

    @Test("hashable works in sets")
    func hashable() {
        let blocker = CodalonReleaseBlocker(title: "Bug")
        let set: Set<CodalonReleaseBlocker> = [blocker, blocker]

        #expect(set.count == 1)
    }
}

// MARK: - Checklist Item Tests (#138)

@Suite("CodalonChecklistItem")
@MainActor
struct ChecklistItemTests {

    @Test("default values on init")
    func defaults() {
        let item = CodalonChecklistItem(title: "Test")

        #expect(item.title == "Test")
        #expect(item.isComplete == false)
    }

    @Test("toggle isComplete")
    func toggle() {
        var item = CodalonChecklistItem(title: "Test")
        item.isComplete.toggle()

        #expect(item.isComplete == true)
    }

    @Test("equatable compares all fields")
    func equatable() {
        let id = UUID()
        let a = CodalonChecklistItem(id: id, title: "Test", isComplete: true)
        let b = CodalonChecklistItem(id: id, title: "Test", isComplete: true)

        #expect(a == b)
    }
}
