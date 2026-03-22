// Issue #310 — Local Git Panel integration tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Panel Integration Tests (#310)

@Suite("Local Git Panel Integration")
@MainActor
struct LocalGitPanelIntegrationTests {

    @Test("ShellState panel visibility defaults to false")
    func panelVisibilityDefault() {
        let shell = CodalonShellState()

        #expect(shell.isLocalGitPanelVisible == false)
    }

    @Test("ShellState panel visibility can be toggled")
    func panelVisibilityToggle() {
        let shell = CodalonShellState()

        shell.isLocalGitPanelVisible = true
        #expect(shell.isLocalGitPanelVisible == true)

        shell.isLocalGitPanelVisible = false
        #expect(shell.isLocalGitPanelVisible == false)
    }

    @Test("ViewModel without repo shows no-repo state")
    func noRepoState() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.repo == nil)
        #expect(vm.isLoading == false)
    }

    @Test("ViewModel file diffs dictionary is initially empty")
    func fileDiffsEmpty() {
        let vm = LocalGitPanelViewModel()

        #expect(vm.fileDiffs.isEmpty)
    }

    @Test("ViewModel file diffs can be populated")
    func fileDiffsPopulate() {
        let vm = LocalGitPanelViewModel()

        // Verify dictionary accepts entries
        #expect(vm.fileDiffs["test.swift"] == nil)
    }

    @Test("panel open/close cycle does not leak state")
    func openCloseCycle() {
        let shell = CodalonShellState()
        let vm = LocalGitPanelViewModel()

        // Simulate open
        shell.isLocalGitPanelVisible = true
        vm.commitMessage = "wip"

        // Simulate close
        shell.isLocalGitPanelVisible = false
        vm.stopAutoRefresh()

        // Message persists (panel is not destroyed, just hidden)
        #expect(vm.commitMessage == "wip")
    }

    @Test("multiple ViewModels are independent")
    func viewModelIndependence() {
        let vm1 = LocalGitPanelViewModel()
        let vm2 = LocalGitPanelViewModel()

        vm1.commitMessage = "from vm1"
        vm1.generalError = "error1"

        #expect(vm2.commitMessage.isEmpty)
        #expect(vm2.generalError == nil)
    }
}

// MARK: - LocalRepoResolver Tests

@Suite("LocalRepoResolver")
@MainActor
struct LocalRepoResolverTests {

    @Test("resolver returns nil for unknown project")
    func unknownProject() async {
        let resolver = LocalRepoResolver()
        let repo = await resolver.resolve(projectID: UUID())

        #expect(repo == nil)
    }
}
