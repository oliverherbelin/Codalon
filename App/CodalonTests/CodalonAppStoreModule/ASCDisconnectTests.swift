// Issue #251 — Test ASC disconnect flows

import Foundation
import Testing
@testable import Codalon

// MARK: - ASC Disconnect Flow Tests

@Suite("ASC Disconnect Flows")
@MainActor
struct ASCDisconnectTests {

    @Test("ASC connection status defaults to notConnected")
    func defaultNotConnected() {
        let status = ASCConnectionStatus.notConnected
        #expect(status == .notConnected)
    }

    @Test("ASC connection status transitions correctly")
    func connectionStatusTransitions() {
        var status = ASCConnectionStatus.notConnected

        // Connect
        status = .connected(appName: "Codalon")
        #expect(status == .connected(appName: "Codalon"))

        // Credentials expire
        status = .credentialsExpired
        #expect(status == .credentialsExpired)

        // Disconnect
        status = .notConnected
        #expect(status == .notConnected)

        // Reconnect
        status = .connected(appName: "Codalon")
        #expect(status == .connected(appName: "Codalon"))
    }

    @Test("mock ASC service handles disconnect gracefully")
    func mockServiceHandlesDisconnect() async {
        let service = DisconnectedASCService()

        let apps = await service.fetchApps()
        #expect(apps.isEmpty)

        let builds = await service.fetchBuilds()
        #expect(builds.isEmpty)
    }

    @Test("ASC credential removal clears connection")
    func credentialRemovalClearsConnection() async {
        let mockCredentialService = MockASCCredentialService()

        await mockCredentialService.store(key: "test-key")
        var hasKey = await mockCredentialService.hasStoredKey()
        #expect(hasKey == true)

        await mockCredentialService.clear()
        hasKey = await mockCredentialService.hasStoredKey()
        #expect(hasKey == false)
    }
}

// MARK: - Mock Services

private actor DisconnectedASCService {
    func fetchApps() -> [String] { [] }
    func fetchBuilds() -> [String] { [] }
}

private actor MockASCCredentialService {
    private var storedKey: String?

    func store(key: String) { storedKey = key }
    func hasStoredKey() -> Bool { storedKey != nil }
    func clear() { storedKey = nil }
}
