// Epics 10, 11 — Preview helpers for GitHub module

import Foundation
import HelaiaGit

// MARK: - JSON Factory Helpers

private nonisolated func issueJSON(
    id: Int, number: Int, title: String, body: String?,
    state: String, createdAt: Date, updatedAt: Date
) -> GitIssue {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var json: [String: Any] = [
        "id": id, "number": number, "title": title, "state": state,
        "created_at": formatter.string(from: createdAt),
        "updated_at": formatter.string(from: updatedAt)
    ]
    if let body { json["body"] = body }
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitIssue.self, from: data)
}

private nonisolated func prJSON(
    id: Int, number: Int, title: String, body: String?,
    state: String, headRef: String, baseRef: String,
    createdAt: Date, updatedAt: Date
) -> GitPullRequest {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var json: [String: Any] = [
        "id": id, "number": number, "title": title, "state": state,
        "head_ref": headRef, "base_ref": baseRef,
        "created_at": formatter.string(from: createdAt),
        "updated_at": formatter.string(from: updatedAt)
    ]
    if let body { json["body"] = body }
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitPullRequest.self, from: data)
}

private nonisolated func milestoneDTO(
    id: Int, number: Int, title: String, description: String?,
    state: String, dueOn: Date?, createdAt: Date, updatedAt: Date,
    openIssues: Int, closedIssues: Int
) -> GitHubMilestoneDTO {
    GitHubMilestoneDTO(
        id: id, number: number, title: title, description: description,
        state: state, dueOn: dueOn, createdAt: createdAt, updatedAt: updatedAt,
        openIssues: openIssues, closedIssues: closedIssues
    )
}

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
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] { [] }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] { [] }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] { [] }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        issueJSON(id: 1, number: 1, title: title, body: body, state: "open", createdAt: .now, updatedAt: .now)
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        issueJSON(id: 1, number: number, title: title ?? "", body: body, state: state ?? "open", createdAt: .now, updatedAt: .now)
    }
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
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] {
        [
            issueJSON(id: 1, number: 42, title: "Fix login flow", body: "Description", state: "open", createdAt: .now.addingTimeInterval(-86400), updatedAt: .now),
            issueJSON(id: 2, number: 41, title: "Add dark mode", body: nil, state: "closed", createdAt: .now.addingTimeInterval(-172800), updatedAt: .now.addingTimeInterval(-86400))
        ]
    }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] {
        [
            milestoneDTO(
                id: 1, number: 1, title: "v1.0", description: "First release",
                state: "open", dueOn: .now.addingTimeInterval(604800),
                createdAt: .now.addingTimeInterval(-604800), updatedAt: .now,
                openIssues: 5, closedIssues: 12
            )
        ]
    }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] {
        [
            prJSON(id: 1, number: 10, title: "Feature: dashboard", body: nil, state: "open", headRef: "feature/dashboard", baseRef: "main", createdAt: .now.addingTimeInterval(-3600), updatedAt: .now)
        ]
    }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        issueJSON(id: 99, number: 99, title: title, body: body, state: "open", createdAt: .now, updatedAt: .now)
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        issueJSON(id: 1, number: number, title: title ?? "", body: body, state: state ?? "open", createdAt: .now, updatedAt: .now)
    }
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
    func fetchIssues(owner: String, repo: String, state: String) async throws -> [GitIssue] {
        throw GitHubServiceError.authFailed
    }
    func fetchMilestones(owner: String, repo: String) async throws -> [GitHubMilestoneDTO] {
        throw GitHubServiceError.authFailed
    }
    func fetchPullRequests(owner: String, repo: String, state: String) async throws -> [GitPullRequest] {
        throw GitHubServiceError.authFailed
    }
    func createIssue(owner: String, repo: String, title: String, body: String?) async throws -> GitIssue {
        throw GitHubServiceError.authFailed
    }
    func updateIssue(owner: String, repo: String, number: Int, title: String?, body: String?, state: String?) async throws -> GitIssue {
        throw GitHubServiceError.authFailed
    }
}
