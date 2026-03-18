// Issue #144 — Readiness score calculation tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Readiness Calculator Tests (#144)

@Suite("ReleaseReadinessCalculator")
@MainActor
struct ReleaseReadinessTests {

    @Test("empty release scores 30 (no blockers = full blocker resolution)")
    func emptyRelease() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0"
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: empty = 0, blockers: empty = 1.0 * 30 = 30, issues: 0, date: 0
        #expect(score == 30)
    }

    @Test("all checklist complete with no blockers scores 40")
    func checklistOnlyComplete() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            checklistItems: [
                CodalonChecklistItem(title: "A", isComplete: true),
                CodalonChecklistItem(title: "B", isComplete: true),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: 1.0 * 40 = 40, blockers: empty = 1.0 * 30 = 30
        // No issues, no date → 40 + 30 = 70
        #expect(score == 70)
    }

    @Test("half checklist complete")
    func halfChecklist() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            checklistItems: [
                CodalonChecklistItem(title: "A", isComplete: true),
                CodalonChecklistItem(title: "B", isComplete: false),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: 0.5 * 40 = 20, blockers: empty = 1.0 * 30 = 30
        #expect(score == 50)
    }

    @Test("all blockers resolved contributes 30 points")
    func allBlockersResolved() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            blockers: [
                CodalonReleaseBlocker(title: "Bug", severity: .critical, isResolved: true),
                CodalonReleaseBlocker(title: "Crash", severity: .error, isResolved: true),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: empty = 0, blockers: 1.0 * 30 = 30
        #expect(score == 30)
    }

    @Test("unresolved blockers reduce score")
    func unresolvedBlockers() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            blockers: [
                CodalonReleaseBlocker(title: "Bug", severity: .critical, isResolved: true),
                CodalonReleaseBlocker(title: "Crash", severity: .error, isResolved: false),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: 0, blockers: 0.5 * 30 = 15
        #expect(score == 15)
    }

    @Test("target date adds 10 points")
    func targetDateBonus() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400)
        )

        let score = ReleaseReadinessCalculator.score(for: release)

        // Checklist: 0, blockers: empty = 30, issues: 0, date: 10
        #expect(score == 40)
    }

    @Test("closed issue ratio contributes up to 20 points")
    func closedIssueRatio() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0"
        )

        let score = ReleaseReadinessCalculator.score(for: release, closedIssueRatio: 0.5)

        // Checklist: 0, blockers: empty = 30, issues: 0.5 * 20 = 10, date: 0
        #expect(score == 40)
    }

    @Test("perfect release scores 100")
    func perfectRelease() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            targetDate: Date().addingTimeInterval(86400),
            checklistItems: [
                CodalonChecklistItem(title: "A", isComplete: true),
                CodalonChecklistItem(title: "B", isComplete: true),
            ],
            blockers: [
                CodalonReleaseBlocker(title: "Fixed", severity: .warning, isResolved: true),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release, closedIssueRatio: 1.0)

        // 40 + 30 + 20 + 10 = 100
        #expect(score == 100)
    }

    @Test("score is capped at 100")
    func cappedAt100() {
        let release = CodalonRelease(
            projectID: UUID(),
            version: "1.0.0",
            targetDate: Date(),
            checklistItems: [
                CodalonChecklistItem(title: "A", isComplete: true),
            ],
            blockers: [
                CodalonReleaseBlocker(title: "Fixed", severity: .info, isResolved: true),
            ]
        )

        let score = ReleaseReadinessCalculator.score(for: release, closedIssueRatio: 1.0)

        #expect(score <= 100)
    }
}
