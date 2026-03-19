// Issue #254 — Test release cockpit edge states

import Foundation
import Testing
import HelaiaShare
@testable import Codalon

// MARK: - Cockpit Edge State Tests

@Suite("Release Cockpit Edge States")
@MainActor
struct CockpitEdgeStateTests {

    @Test("release with zero checklist items has zero readiness from checklist")
    func zeroChecklistItems() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            buildNumber: "1",
            status: .drafting,
            readinessScore: 0,
            checklistItems: []
        )

        #expect(release.checklistItems.isEmpty)
        #expect(release.readinessScore == 0)
    }

    @Test("release with zero blockers has clean blocker state")
    func zeroBlockers() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            buildNumber: "1",
            status: .drafting,
            readinessScore: 50,
            blockers: []
        )

        #expect(release.blockers.isEmpty)
        #expect(release.blockerCount == 0)
    }

    @Test("release at 100% readiness exports correctly")
    func fullReadinessExport() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "2.0.0",
            buildNumber: "99",
            status: .readyForSubmission,
            readinessScore: 100,
            checklistItems: [
                CodalonChecklistItem(title: "Code complete", isComplete: true),
                CodalonChecklistItem(title: "QA pass", isComplete: true),
            ]
        )

        let content = CodalonExportFormatter.releaseChecklistContent(release: release)

        #expect(content.body.contains("100%"))
        #expect(content.body.contains("Ready"))
        #expect(content.metadata["readiness"] == "100%")
    }

    @Test("release with zero linked issues exports without issues section")
    func zeroLinkedIssues() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            buildNumber: "1",
            status: .drafting,
            readinessScore: 50
        )

        #expect(release.linkedGitHubIssueRefs.isEmpty)

        let content = CodalonExportFormatter.releaseChecklistContent(release: release)
        #expect(!content.body.contains("Linked GitHub Issues"))
    }

    @Test("release with all blockers resolved shows resolved status")
    func allBlockersResolved() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            buildNumber: "1",
            status: .readyForQA,
            readinessScore: 80,
            blockers: [
                CodalonReleaseBlocker(title: "Bug A", severity: .critical, isResolved: true),
                CodalonReleaseBlocker(title: "Bug B", severity: .warning, isResolved: true),
            ]
        )

        let allResolved = release.blockers.allSatisfy { $0.isResolved }
        #expect(allResolved)

        let content = CodalonExportFormatter.releaseChecklistContent(release: release)
        #expect(content.body.contains("[x] Bug A"))
        #expect(content.body.contains("[x] Bug B"))
    }

    @Test("release with mixed checklist completion shows correct checkboxes")
    func mixedChecklistCompletion() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            buildNumber: "1",
            status: .readyForQA,
            readinessScore: 60,
            checklistItems: [
                CodalonChecklistItem(title: "Screenshots", isComplete: true),
                CodalonChecklistItem(title: "Localizations", isComplete: false),
                CodalonChecklistItem(title: "Metadata", isComplete: true),
            ]
        )

        let complete = release.checklistItems.filter(\.isComplete).count
        let incomplete = release.checklistItems.filter { !$0.isComplete }.count

        #expect(complete == 2)
        #expect(incomplete == 1)
    }

    @Test("view model with no releases shows nil active release")
    func noActiveRelease() {
        let vm = ReleaseViewModel(
            releaseService: EdgeCaseReleaseService(),
            projectID: UUID()
        )

        #expect(vm.activeRelease == nil)
        #expect(vm.selectedRelease == nil)
        #expect(vm.releases.isEmpty)
    }

    @Test("all release status values are valid")
    func allReleaseStatusValues() {
        let statuses = CodalonReleaseStatus.allCases
        #expect(statuses.count == 10)

        for status in statuses {
            #expect(!status.rawValue.isEmpty)
        }
    }
}

// MARK: - Mock Service

private actor EdgeCaseReleaseService: ReleaseServiceProtocol {
    func save(_ release: CodalonRelease) async throws {}
    func load(id: UUID) async throws -> CodalonRelease {
        throw EdgeCaseError.notFound
    }
    func delete(id: UUID) async throws {}
    func fetchByProject(_ projectID: UUID) async throws -> [CodalonRelease] { [] }
    func fetchActive(projectID: UUID) async throws -> CodalonRelease? { nil }
}

private enum EdgeCaseError: Error {
    case notFound
}
