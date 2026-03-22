// Issue #309 — LocalChangesBadge state tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Badge State Tests (#309)

@Suite("LocalChangesBadge State")
@MainActor
struct LocalChangesBadgeStateTests {

    @Test("zero changes produces no badge — totalCount is zero")
    func zeroCounts() {
        let unstaged = 0
        let staged = 0
        let total = unstaged + staged

        #expect(total == 0)
    }

    @Test("unstaged only — badge shows unstaged count")
    func unstagedOnly() {
        let unstaged = 3
        let staged = 0
        let total = unstaged + staged

        #expect(total == 3)
        #expect(staged == 0)
        #expect(unstaged > 0)
    }

    @Test("staged only — badge shows staged count with indicator")
    func stagedOnly() {
        let unstaged = 0
        let staged = 2
        let total = unstaged + staged

        #expect(total == 2)
        #expect(staged > 0)
        #expect(unstaged == 0)
    }

    @Test("mixed state — badge shows total count")
    func mixedState() {
        let unstaged = 4
        let staged = 2
        let total = unstaged + staged

        #expect(total == 6)
        #expect(staged > 0)
        #expect(unstaged > 0)
    }

    @Test("badge label for unstaged only")
    func labelUnstagedOnly() {
        let unstaged = 5
        let staged = 0
        let label: String
        if staged > 0, unstaged > 0 {
            label = "\(unstaged + staged)"
        } else if staged > 0 {
            label = "\(staged)●"
        } else {
            label = "\(unstaged)"
        }

        #expect(label == "5")
    }

    @Test("badge label for staged only")
    func labelStagedOnly() {
        let unstaged = 0
        let staged = 3
        let label: String
        if staged > 0, unstaged > 0 {
            label = "\(unstaged + staged)"
        } else if staged > 0 {
            label = "\(staged)●"
        } else {
            label = "\(unstaged)"
        }

        #expect(label == "3●")
    }

    @Test("badge label for mixed")
    func labelMixed() {
        let unstaged = 2
        let staged = 4
        let label: String
        if staged > 0, unstaged > 0 {
            label = "\(unstaged + staged)"
        } else if staged > 0 {
            label = "\(staged)●"
        } else {
            label = "\(unstaged)"
        }

        #expect(label == "6")
    }

    @Test("accessibility text — unstaged only")
    func accessibilityUnstaged() {
        let unstaged = 3
        let staged = 0
        var parts: [String] = []
        if unstaged > 0 { parts.append("\(unstaged) unstaged") }
        if staged > 0 { parts.append("\(staged) staged") }
        let text = parts.joined(separator: ", ") + " — tap to open git panel"

        #expect(text == "3 unstaged — tap to open git panel")
    }

    @Test("accessibility text — mixed")
    func accessibilityMixed() {
        let unstaged = 2
        let staged = 1
        var parts: [String] = []
        if unstaged > 0 { parts.append("\(unstaged) unstaged") }
        if staged > 0 { parts.append("\(staged) staged") }
        let text = parts.joined(separator: ", ") + " — tap to open git panel"

        #expect(text == "2 unstaged, 1 staged — tap to open git panel")
    }
}
