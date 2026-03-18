// Epic 10 — Preview helpers for GitHub module

import Foundation
import HelaiaGit

// MARK: - Preview Service

actor PreviewGitHubService: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws {}
    func isAuthenticated() async -> Bool { false }
    func loadUsername() async throws -> String { "oliverherbelin" }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { [] }
    func fetchUser() async throws -> GitHubUser {
        GitHubUser(login: "oliverherbelin", avatarURL: "", name: "Oliver Herbelin")
    }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] { [] }
    func validateToken() async -> GitHubConnectionStatus { .notConnected }
    func disconnect(projectID: UUID) async throws {}
}

// MARK: - Connected Preview Service

actor PreviewGitHubServiceConnected: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws {}
    func isAuthenticated() async -> Bool { true }
    func loadUsername() async throws -> String { "oliverherbelin" }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { [] }
    func fetchUser() async throws -> GitHubUser {
        GitHubUser(login: "oliverherbelin", avatarURL: "", name: "Oliver Herbelin")
    }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] {
        [
            CodalonGitHubRepo(
                projectID: projectID,
                owner: "oliverherbelin",
                name: "Codalon",
                isPrivate: true,
                defaultBranch: "main"
            )
        ]
    }
    func validateToken() async -> GitHubConnectionStatus { .connected(username: "oliverherbelin") }
    func disconnect(projectID: UUID) async throws {}
}

// MARK: - Expired Token Preview Service

actor PreviewGitHubServiceExpired: GitHubServiceProtocol {
    func authenticate(token: String, username: String) async throws {}
    func isAuthenticated() async -> Bool { true }
    func loadUsername() async throws -> String { "oliverherbelin" }
    func removeAuth() async throws {}
    func fetchRepositories(page: Int) async throws -> [GitHubRepo] { [] }
    func fetchUser() async throws -> GitHubUser {
        throw GitHubServiceError.authFailed
    }
    func linkRepo(_ repo: CodalonGitHubRepo) async throws {}
    func unlinkRepo(id: UUID) async throws {}
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] { [] }
    func validateToken() async -> GitHubConnectionStatus { .tokenExpired }
    func disconnect(projectID: UUID) async throws {}
}
