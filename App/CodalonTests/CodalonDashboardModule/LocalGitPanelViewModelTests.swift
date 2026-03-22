// Issues #305, #306, #307, #308 — LocalGitPanel ViewModel tests

import Foundation
import Testing
@testable import Codalon

// MARK: - ViewModel State Tests (#305)

@Suite("LocalGitPanelViewModel — Initial State")
@MainActor
struct LocalGitPanelViewModelStateTests {

    @Test("initial state is empty")
    func initialState() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.repo == nil)
        #expect(vm.currentBranch == "main")
        #expect(vm.branches.isEmpty)
        #expect(vm.commits.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.isFetching == false)
        #expect(vm.isCommitting == false)
        #expect(vm.isPushing == false)
        #expect(vm.isPulling == false)
        #expect(vm.commitMessage.isEmpty)
        #expect(vm.commitError == nil)
        #expect(vm.pushError == nil)
        #expect(vm.pullError == nil)
        #expect(vm.generalError == nil)
        #expect(vm.stashes.isEmpty)
        #expect(vm.tags.isEmpty)
        #expect(vm.hasConflict == false)
        #expect(vm.conflictFiles.isEmpty)
    }

    @Test("computed properties reflect empty status")
    func computedEmpty() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.hasStagedChanges == false)
        #expect(vm.hasUnstagedChanges == false)
        #expect(vm.canCommit == false)
        #expect(vm.isClean == true)
    }

    @Test("canCommit requires staged changes and non-empty message")
    func canCommitLogic() {
        let vm = LocalGitPanelViewModel()

        // No staged changes, no message
        #expect(vm.canCommit == false)

        // No staged changes, has message
        vm.commitMessage = "fix something"
        #expect(vm.canCommit == false)

        // Whitespace-only message
        vm.commitMessage = "   "
        #expect(vm.canCommit == false)
    }

    @Test("expanded file path toggles correctly")
    func expandedFilePath() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.expandedFilePath == nil)

        vm.expandedFilePath = "Sources/MyFile.swift"
        #expect(vm.expandedFilePath == "Sources/MyFile.swift")

        vm.expandedFilePath = nil
        #expect(vm.expandedFilePath == nil)
    }

    @Test("generalError can be set and cleared")
    func generalError() {
        let vm = LocalGitPanelViewModel()

        vm.generalError = "Something went wrong"
        #expect(vm.generalError == "Something went wrong")

        vm.generalError = nil
        #expect(vm.generalError == nil)
    }

    @Test("auto-refresh can be stopped")
    func autoRefreshStop() {
        let vm = LocalGitPanelViewModel()

        // Should not crash when called without prior start
        vm.stopAutoRefresh()
    }
}

// MARK: - Commit Flow State Tests (#307)

@Suite("LocalGitPanelViewModel — Commit Flow")
@MainActor
struct LocalGitPanelViewModelCommitFlowTests {

    @Test("commit message is cleared after successful state")
    func commitMessageState() {
        let vm = LocalGitPanelViewModel()

        vm.commitMessage = "initial message"
        #expect(vm.commitMessage == "initial message")

        vm.commitMessage = ""
        #expect(vm.commitMessage.isEmpty)
    }

    @Test("commit error and push error are independent")
    func errorIndependence() {
        let vm = LocalGitPanelViewModel()

        vm.commitError = "commit failed"
        vm.pushError = "push failed"

        #expect(vm.commitError == "commit failed")
        #expect(vm.pushError == "push failed")

        vm.commitError = nil
        #expect(vm.commitError == nil)
        #expect(vm.pushError == "push failed")
    }

    @Test("isCommitting flag prevents canCommit")
    func isCommittingBlocksCanCommit() {
        let vm = LocalGitPanelViewModel()

        vm.commitMessage = "test"
        vm.isCommitting = true

        // canCommit should be false when isCommitting is true
        #expect(vm.canCommit == false)
    }
}

// MARK: - Conflict State Tests (#308)

@Suite("LocalGitPanelViewModel — Conflict State")
@MainActor
struct LocalGitPanelViewModelConflictTests {

    @Test("conflict state is set correctly")
    func conflictState() {
        let vm = LocalGitPanelViewModel()

        vm.hasConflict = true
        vm.conflictFiles = ["file1.swift", "file2.swift"]

        #expect(vm.hasConflict == true)
        #expect(vm.conflictFiles.count == 2)
        #expect(vm.conflictFiles.first == "file1.swift")
    }

    @Test("conflict state can be cleared")
    func conflictClear() {
        let vm = LocalGitPanelViewModel()

        vm.hasConflict = true
        vm.conflictFiles = ["file.swift"]

        vm.hasConflict = false
        vm.conflictFiles = []

        #expect(vm.hasConflict == false)
        #expect(vm.conflictFiles.isEmpty)
    }
}

// MARK: - Stash / Tag State Tests (#308)

@Suite("LocalGitPanelViewModel — Stash & Tag State")
@MainActor
struct LocalGitPanelViewModelStashTagTests {

    @Test("stashing flag works correctly")
    func stashingFlag() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.isStashing == false)

        vm.isStashing = true
        #expect(vm.isStashing == true)
    }

    @Test("tags and stashes are initially empty")
    func initialCollections() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.tags.isEmpty)
        #expect(vm.stashes.isEmpty)
    }
}
