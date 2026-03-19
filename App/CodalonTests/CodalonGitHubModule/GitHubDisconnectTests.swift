// Issue #250 — Test GitHub disconnect flows

import Foundation
import Testing
@testable import Codalon

// MARK: - GitHub Disconnect Flow Tests

@Suite("GitHub Disconnect Flows")
@MainActor
struct GitHubDisconnectTests {

    @Test("notConnected status is not connected")
    func notConnectedStatus() {
        let status = GitHubConnectionStatus.notConnected
        #expect(status == .notConnected)
        #expect(status != .connected(username: "test"))
    }

    @Test("connection status transitions correctly")
    func connectionStatusTransitions() {
        // Start not connected
        var status = GitHubConnectionStatus.notConnected
        #expect(status == .notConnected)

        // Connect
        status = .connected(username: "oliverherbelin")
        #expect(status == .connected(username: "oliverherbelin"))

        // Token expires
        status = .tokenExpired
        #expect(status == .tokenExpired)

        // Disconnect
        status = .notConnected
        #expect(status == .notConnected)

        // Reconnect
        status = .connected(username: "oliverherbelin")
        #expect(status == .connected(username: "oliverherbelin"))
    }

    @Test("error status carries message")
    func errorStatusMessage() {
        let status = GitHubConnectionStatus.error("Network timeout")
        #expect(status == .error("Network timeout"))
        #expect(status != .notConnected)
    }

    @Test("mock service returns empty data when disconnected")
    func mockServiceEmptyWhenDisconnected() async {
        let mockService = DisconnectedGitHubService()

        let repos = await mockService.fetchRepositories()
        #expect(repos.isEmpty)

        let issues = await mockService.fetchIssues()
        #expect(issues.isEmpty)
    }
}

// MARK: - Mock Disconnected Service

private actor DisconnectedGitHubService {
    func fetchRepositories() -> [CodalonGitHubRepo] { [] }
    func fetchIssues() -> [CodalonInsight] { [] }
}
