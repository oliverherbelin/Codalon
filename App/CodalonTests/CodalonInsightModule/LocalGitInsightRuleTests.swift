// Issues #283, #284 — Uncommitted changes & unpushed commits rule tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Local Git Insight Rule Tests

@Suite("LocalGitInsightRules")
@MainActor
struct LocalGitInsightRuleTests {

    let projectID = UUID()

    // MARK: - Issue #283 — Uncommitted Changes

    @Test("detects unstaged changes")
    func unstagedChanges() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 5,
            localStagedCount: 0,
            localAheadCount: 0
        )
        let rule = UncommittedChangesRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.title == "Uncommitted changes")
        #expect(results.first?.message.contains("5 unstaged") == true)
        #expect(results.first?.severity == .info)
    }

    @Test("detects staged changes")
    func stagedChanges() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 3,
            localAheadCount: 0
        )
        let rule = UncommittedChangesRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.message.contains("3 staged") == true)
    }

    @Test("detects both staged and unstaged")
    func stagedAndUnstaged() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 4,
            localStagedCount: 2,
            localAheadCount: 0
        )
        let rule = UncommittedChangesRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.message.contains("2 staged") == true)
        #expect(results.first?.message.contains("4 unstaged") == true)
    }

    @Test("warning severity when 10+ uncommitted files")
    func warningSeverityForManyChanges() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 8,
            localStagedCount: 3,
            localAheadCount: 0
        )
        let rule = UncommittedChangesRule()
        let results = await rule.evaluate(context: context)

        #expect(results.first?.severity == .warning)
    }

    @Test("no insight when working tree is clean")
    func cleanWorkingTree() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 0,
            localAheadCount: 0
        )
        let rule = UncommittedChangesRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }

    // MARK: - Issue #284 — Unpushed Commits

    @Test("detects unpushed commits")
    func unpushedCommits() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 0,
            localAheadCount: 3
        )
        let rule = UnpushedCommitsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.count == 1)
        #expect(results.first?.title == "Unpushed commits")
        #expect(results.first?.message.contains("3 commits") == true)
        #expect(results.first?.severity == .info)
    }

    @Test("warning severity when 5+ unpushed commits")
    func warningSeverityForManyCommits() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 0,
            localAheadCount: 7
        )
        let rule = UnpushedCommitsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.first?.severity == .warning)
    }

    @Test("singular commit message")
    func singularCommit() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 0,
            localAheadCount: 1
        )
        let rule = UnpushedCommitsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.first?.message.contains("1 commit that") == true)
    }

    @Test("no insight when fully pushed")
    func fullyPushed() async {
        let context = InsightRuleContext(
            projectID: projectID,
            localUnstagedCount: 0,
            localStagedCount: 0,
            localAheadCount: 0
        )
        let rule = UnpushedCommitsRule()
        let results = await rule.evaluate(context: context)

        #expect(results.isEmpty)
    }
}
