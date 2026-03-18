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
}
