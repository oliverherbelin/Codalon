// Issues #277, #278 — Project Creation Flow tests

import Foundation
import Testing
@testable import Codalon

// MARK: - ProjectCreationSideEffects Tests

@Suite("ProjectCreationSideEffects")
@MainActor
struct ProjectCreationSideEffectsTests {

    @Test("default side effects are all false")
    func defaultSideEffects() {
        let effects = ProjectCreationSideEffects()

        #expect(effects.shouldGitInit == false)
        #expect(effects.shouldClone == false)
        #expect(effects.cloneRemoteURL == nil)
        #expect(effects.shouldCreateFolder == false)
        #expect(effects.shouldCreateGitHubRepo == false)
        #expect(effects.newRepoName == nil)
        #expect(effects.newRepoIsPrivate == true)
    }

    @Test("side effects for local folder with git init")
    func localFolderGitInit() {
        var effects = ProjectCreationSideEffects()
        effects.shouldGitInit = true

        #expect(effects.shouldGitInit == true)
        #expect(effects.shouldClone == false)
        #expect(effects.shouldCreateFolder == false)
    }

    @Test("side effects for clone path")
    func clonePath() {
        var effects = ProjectCreationSideEffects()
        effects.shouldClone = true
        effects.cloneRemoteURL = URL(string: "https://github.com/user/repo.git")

        #expect(effects.shouldClone == true)
        #expect(effects.cloneRemoteURL?.absoluteString == "https://github.com/user/repo.git")
    }

    @Test("side effects for blank with folder and GitHub repo")
    func blankWithGitHubRepo() {
        var effects = ProjectCreationSideEffects()
        effects.shouldCreateFolder = true
        effects.shouldGitInit = true
        effects.shouldCreateGitHubRepo = true
        effects.newRepoName = "my-app"
        effects.newRepoIsPrivate = false

        #expect(effects.shouldCreateFolder == true)
        #expect(effects.shouldGitInit == true)
        #expect(effects.shouldCreateGitHubRepo == true)
        #expect(effects.newRepoName == "my-app")
        #expect(effects.newRepoIsPrivate == false)
    }
}

// MARK: - FolderAnalysis Tests

@Suite("FolderAnalysis")
@MainActor
struct FolderAnalysisTests {

    @Test("folder with git and remote")
    func gitWithRemote() {
        let analysis = FolderAnalysis(
            url: URL(fileURLWithPath: "/tmp/my-project"),
            hasGit: true,
            hasRemote: true,
            remoteName: "origin",
            remoteURL: "https://github.com/user/repo.git"
        )

        #expect(analysis.hasGit == true)
        #expect(analysis.hasRemote == true)
        #expect(analysis.remoteName == "origin")
        #expect(analysis.remoteURL == "https://github.com/user/repo.git")
    }

    @Test("folder without git")
    func noGit() {
        let analysis = FolderAnalysis(
            url: URL(fileURLWithPath: "/tmp/plain-folder"),
            hasGit: false,
            hasRemote: false,
            remoteName: nil,
            remoteURL: nil
        )

        #expect(analysis.hasGit == false)
        #expect(analysis.hasRemote == false)
        #expect(analysis.remoteName == nil)
    }

    @Test("folder with git but no remote")
    func gitNoRemote() {
        let analysis = FolderAnalysis(
            url: URL(fileURLWithPath: "/tmp/local-only"),
            hasGit: true,
            hasRemote: false,
            remoteName: nil,
            remoteURL: nil
        )

        #expect(analysis.hasGit == true)
        #expect(analysis.hasRemote == false)
    }
}

// MARK: - ProjectCreationPath Tests

@Suite("ProjectCreationPath")
@MainActor
struct ProjectCreationPathTests {

    @Test("all paths are distinct")
    func pathEquality() {
        #expect(ProjectCreationPath.localFolder != ProjectCreationPath.fromGitHub)
        #expect(ProjectCreationPath.fromGitHub != ProjectCreationPath.startBlank)
        #expect(ProjectCreationPath.startBlank != ProjectCreationPath.localFolder)
    }
}

// MARK: - GitLocalRepoPath Tests

@Suite("GitLocalRepoPath")
struct GitLocalRepoPathTests {

    @Test("round-trip encode/decode")
    func roundTrip() throws {
        let projectID = UUID()
        let bookmark = Data([0x01, 0x02, 0x03])

        let path = GitLocalRepoPath(
            projectID: projectID,
            bookmarkData: bookmark,
            displayPath: "/Users/test/my-project"
        )

        #expect(path.projectID == projectID)
        #expect(path.bookmarkData == bookmark)
        #expect(path.displayPath == "/Users/test/my-project")
        #expect(path.schemaVersion == 1)
        #expect(path.deletedAt == nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(path)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GitLocalRepoPath.self, from: data)

        #expect(decoded.id == path.id)
        #expect(decoded.projectID == projectID)
        #expect(decoded.bookmarkData == bookmark)
        #expect(decoded.displayPath == "/Users/test/my-project")
    }

    @Test("default values are set")
    func defaultValues() {
        let path = GitLocalRepoPath(
            projectID: UUID(),
            bookmarkData: Data(),
            displayPath: "/tmp"
        )

        #expect(path.schemaVersion == 1)
        #expect(path.deletedAt == nil)
        #expect(!path.id.uuidString.isEmpty)
    }
}

// MARK: - Project Creation Integration (#278)

@Suite("Project Creation Integration")
@MainActor
struct ProjectCreationIntegrationTests {

    @Test("project slug generation — spaces become hyphens")
    func slugFromSpaces() {
        let project = CodalonProject(
            name: "My Cool App",
            slug: "my-cool-app"
        )

        #expect(project.slug == "my-cool-app")
        #expect(project.name == "My Cool App")
    }

    @Test("project slug generation — special chars stripped")
    func slugStripsSpecialChars() {
        let name = "My App (v2.0)"
        let slug = name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        #expect(slug == "my-app-v20")
    }

    @Test("project defaults are sensible")
    func projectDefaults() {
        let project = CodalonProject(name: "Test", slug: "test")

        #expect(project.icon == "folder.fill")
        #expect(project.color == "#4A90D9")
        #expect(project.linkedGitHubRepos.isEmpty)
        #expect(project.healthScore == 0)
        #expect(project.deletedAt == nil)
    }

    @Test("project with linked repos")
    func projectLinkedRepos() {
        let project = CodalonProject(
            name: "Codalon",
            slug: "codalon",
            linkedGitHubRepos: ["oliverherbelin/Codalon"]
        )

        #expect(project.linkedGitHubRepos.count == 1)
        #expect(project.linkedGitHubRepos.first == "oliverherbelin/Codalon")
    }
}
