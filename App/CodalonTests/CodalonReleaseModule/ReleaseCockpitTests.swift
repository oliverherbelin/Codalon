// Issue #177 — Cockpit UI tests: readiness display, blocker resolution, checklist toggle

import Foundation
import Testing
@testable import Codalon

// MARK: - Cockpit Logic Tests

@Suite("ReleaseCockpit")
@MainActor
struct ReleaseCockpitTests {

    let projectID = ReleasePreviewData.projectID

    // MARK: - Readiness Display

    @Test("readiness score reflects checklist state")
    func readinessReflectsChecklist() {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            checklistItems: [
                CodalonChecklistItem(title: "A", isComplete: true),
                CodalonChecklistItem(title: "B", isComplete: true),
                CodalonChecklistItem(title: "C", isComplete: false),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release)
        // 2/3 * 40 + 30 (no blockers) = ~56.67
        #expect(score > 56 && score < 57)
    }

    @Test("ship-readiness requires score ≥ 80 and zero blockers")
    func shipReadinessRequirements() {
        let readyRelease = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400),
            readinessScore: 85,
            checklistItems: [
                CodalonChecklistItem(title: "Done", isComplete: true),
            ]
        )

        let isReady = readyRelease.readinessScore >= 80
            && readyRelease.blockers.filter({ !$0.isResolved }).isEmpty
        #expect(isReady == true)

        let blockedRelease = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            readinessScore: 90,
            blockers: [CodalonReleaseBlocker(title: "Bug")]
        )

        let isBlocked = blockedRelease.readinessScore >= 80
            && blockedRelease.blockers.filter({ !$0.isResolved }).isEmpty
        #expect(isBlocked == false)
    }

    // MARK: - Blocker Resolution

    @Test("resolving blocker updates count")
    func blockerResolution() async {
        let service = PreviewReleaseService()
        let vm = ReleaseViewModel(
            releaseService: service,
            projectID: projectID
        )

        var release = ReleasePreviewData.draftRelease
        try? await service.save(release)
        vm.selectedRelease = release

        let unresolvedBlocker = release.blockers.first { !$0.isResolved }
        guard let blockerID = unresolvedBlocker?.id else {
            Issue.record("Expected an unresolved blocker")
            return
        }

        await vm.resolveBlocker(blockerID)

        guard let updated = vm.selectedRelease else {
            Issue.record("Expected selected release")
            return
        }
        let activeBlockers = updated.blockers.filter { !$0.isResolved }
        #expect(activeBlockers.count < release.blockers.filter({ !$0.isResolved }).count)
    }

    // MARK: - Checklist Toggle

    @Test("toggling checklist item updates completion")
    func checklistToggle() async {
        let service = PreviewReleaseService()
        let vm = ReleaseViewModel(
            releaseService: service,
            projectID: projectID
        )

        let release = ReleasePreviewData.draftRelease
        try? await service.save(release)
        vm.selectedRelease = release

        let incompleteItem = release.checklistItems.first { !$0.isComplete }
        guard let itemID = incompleteItem?.id else {
            Issue.record("Expected an incomplete checklist item")
            return
        }

        await vm.toggleChecklistItem(itemID)

        guard let updated = vm.selectedRelease else {
            Issue.record("Expected selected release")
            return
        }
        let toggled = updated.checklistItems.first { $0.id == itemID }
        #expect(toggled?.isComplete == true)
    }

    // MARK: - Active Release Detection

    @Test("active release excludes terminal statuses")
    func activeReleaseDetection() {
        let vm = ReleaseViewModel(
            releaseService: PreviewReleaseService(),
            projectID: projectID
        )

        vm.releases = [
            ReleasePreviewData.releasedRelease,
            ReleasePreviewData.draftRelease,
        ]

        #expect(vm.activeRelease?.version == ReleasePreviewData.draftRelease.version)
    }

    // MARK: - Missing Items Detection

    @Test("missing items detects incomplete checklist entries")
    func missingItemsDetection() {
        let release = CodalonRelease(
            projectID: projectID,
            version: "1.0.0",
            checklistItems: [
                CodalonChecklistItem(title: "Screenshots updated", isComplete: false),
                CodalonChecklistItem(title: "Release notes", isComplete: true),
                CodalonChecklistItem(title: "Metadata fields", isComplete: false),
            ]
        )

        let incomplete = release.checklistItems.filter { !$0.isComplete }
        #expect(incomplete.count == 2)
    }
}
