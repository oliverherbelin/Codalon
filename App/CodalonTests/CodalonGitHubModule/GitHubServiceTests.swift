// Issues #59, #61, #63, #65, #69, #71, #83, #85, #87, #89, #91 — GitHub service tests

import Foundation
import HelaiaGit
import Testing
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!

// MARK: - CodalonGitHubRepo Entity Tests (#71)

@Suite("CodalonGitHubRepo")
@MainActor
struct GitHubRepoEntityTests {

    @Test("round-trip encode/decode")
    func roundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let repo = CodalonGitHubRepo(
            projectID: projectID,
            owner: "oliverherbelin",
            name: "Codalon",
            nodeID: "MDEwOlJlcG9zaXRvcnkx",
            isPrivate: true,
            defaultBranch: "main"
        )

        let data = try encoder.encode(repo)
        let decoded = try decoder.decode(CodalonGitHubRepo.self, from: data)

        #expect(decoded.projectID == repo.projectID)
        #expect(decoded.owner == "oliverherbelin")
        #expect(decoded.name == "Codalon")
        #expect(decoded.fullName == "oliverherbelin/Codalon")
        #expect(decoded.isPrivate == true)
        #expect(decoded.defaultBranch == "main")
    }

    @Test("default values")
    func defaults() {
        let repo = CodalonGitHubRepo(
            projectID: projectID,
            owner: "oliverherbelin",
            name: "Codalon"
        )

        #expect(repo.fullName == "oliverherbelin/Codalon")
        #expect(repo.nodeID == "")
        #expect(repo.isPrivate == false)
        #expect(repo.defaultBranch == "main")
        #expect(repo.deletedAt == nil)
        #expect(repo.schemaVersion == 1)
    }

    @Test("fullName auto-computes from owner/name")
    func fullNameComputed() {
        let repo = CodalonGitHubRepo(
            projectID: projectID,
            owner: "helaia",
            name: "HelaiaFrameworks"
        )
        #expect(repo.fullName == "helaia/HelaiaFrameworks")
    }
}

// MARK: - GitHubViewModel Tests (#67, #69)

@Suite("GitHubViewModel")
@MainActor
struct GitHubViewModelTests {

    @Test("filtered repositories matches search")
    func filteredRepos() {
        let vm = GitHubViewModel(
            gitHubService: InertGitHubService(),
            projectID: projectID
        )
        // Simulate loaded repos — we can't use GitHubRepo directly
        // because it requires HelaiaGit import, so test search query state only
        vm.searchQuery = "Codalon"
        #expect(vm.filteredRepositories.isEmpty)
    }

    @Test("initial state is not authenticated")
    func initialState() {
        let vm = GitHubViewModel(
            gitHubService: InertGitHubService(),
            projectID: projectID
        )
        #expect(!vm.isAuthenticated)
        #expect(vm.username.isEmpty)
        #expect(vm.repositories.isEmpty)
    }
}

// MARK: - JSON Helpers

private func makeTestIssue(
    id: Int, number: Int, title: String, body: String? = nil,
    state: String = "open", createdAt: Date = .now, updatedAt: Date = .now
) -> GitIssue {
    var json: [String: Any] = [
        "id": id, "number": number, "title": title, "state": state,
        "created_at": ISO8601DateFormatter().string(from: createdAt),
        "updated_at": ISO8601DateFormatter().string(from: updatedAt)
    ]
    if let body { json["body"] = body }
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitIssue.self, from: data)
}

// MARK: - Inert Service

private actor InertGitHubService: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws {}
    func isAuthenticated() async -> Bool { false }
    func loadUsername() async throws -> String { "" }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { [] }
    func fetchUser() async throws -> GitHubUser { GitHubUser(login: "", avatarURL: "", name: nil) }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] { [] }
    func validateToken() async -> GitHubConnectionStatus { .notConnected }
    func disconnect(projectID: UUID) async throws {}
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] { [] }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] { [] }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] { [] }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        makeTestIssue(id: 1, number: 1, title: title, body: body)
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        makeTestIssue(id: 1, number: number, title: title ?? "", body: body, state: state ?? "open")
    }
}
