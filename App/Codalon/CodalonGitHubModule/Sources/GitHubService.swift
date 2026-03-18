// Issues #59, #61, #63, #65, #69, #71 — GitHub service

import Foundation
import HelaiaEngine
import HelaiaGit
import HelaiaKeychain
import HelaiaLogger

// MARK: - Protocol

public protocol GitHubServiceProtocol: Sendable {
    func authenticate(token: String, username: String) async throws
    func isAuthenticated() async -> Bool
    func loadUsername() async throws -> String
    func removeAuth() async throws
    func fetchRepositories(page: Int) async throws -> [GitHubRepo]
    func fetchUser() async throws -> GitHubUser
    func linkRepo(_ repo: CodalonGitHubRepo) async throws
    func unlinkRepo(id: UUID) async throws
    func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo]
}

// MARK: - GitHubUser

nonisolated public struct GitHubUser: Codable, Sendable, Equatable {
    public let login: String
    public let avatarURL: String
    public let name: String?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case name
    }
}

// MARK: - Implementation

public actor GitHubService: GitHubServiceProtocol {

    private let credentialManager: GitCredentialManager
    private let repoRepository: any GitHubRepoRepositoryProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        credentialManager: GitCredentialManager,
        repoRepository: any GitHubRepoRepositoryProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.credentialManager = credentialManager
        self.repoRepository = repoRepository
        self.logger = logger
    }

    // MARK: - Issue #59 — Auth Flow

    public func authenticate(token: String, username: String) async throws {
        try await credentialManager.saveCredential(
            token: token,
            for: .github,
            username: username
        )
        await publish(GitHubAuthenticatedEvent(username: username))
    }

    // MARK: - Issue #61 — Credential Check

    public func isAuthenticated() async -> Bool {
        await credentialManager.hasCredential(for: .github)
    }

    public func loadUsername() async throws -> String {
        try await credentialManager.loadUsername(for: .github)
    }

    public func removeAuth() async throws {
        try await credentialManager.removeCredential(for: .github)
        await publish(GitHubAuthRemovedEvent())
    }

    // MARK: - Issue #63 — Fetch User

    public func fetchUser() async throws -> GitHubUser {
        let token = try await credentialManager.loadCredential(for: .github)
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GitHubServiceError.authFailed
        }

        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }

    // MARK: - Issue #65 — Fetch Repos

    public func fetchRepositories(page: Int) async throws -> [GitHubRepo] {
        let token = try await credentialManager.loadCredential(for: .github)
        let provider = GitHubProvider(token: token, logger: logger)
        return try await provider.repositories(page: page)
    }

    // MARK: - Issue #69 — Link Repo

    public func linkRepo(_ repo: CodalonGitHubRepo) async throws {
        try await repoRepository.save(repo)
        await publish(GitHubRepoLinkedEvent(
            projectID: repo.projectID,
            repoFullName: repo.fullName
        ))
    }

    public func unlinkRepo(id: UUID) async throws {
        try await repoRepository.delete(id: id)
    }

    public func linkedRepos(projectID: UUID) async throws -> [CodalonGitHubRepo] {
        try await repoRepository.fetchByProject(projectID)
    }

    // MARK: - Private

    private func publish<E: HelaiaEvent>(_ event: E) async {
        await MainActor.run {
            EventBus.shared.publish(event)
        }
    }
}

// MARK: - Error

public enum GitHubServiceError: Error, Sendable {
    case authFailed
    case notAuthenticated
}