// Epic 14 — Preview helpers for ASC module

import Foundation

// MARK: - Preview Service (Not Connected)

actor PreviewASCService: ASCServiceProtocol {
    func authenticate(credential: ASCCredential) async throws {}
    func isAuthenticated() async -> Bool { false }
    func removeAuth() async throws {}
    func fetchApps() async throws -> [ASCApp] { [] }
    func linkApp(_ app: ASCApp, projectID: UUID) async throws {}
    func unlinkApp(projectID: UUID) async throws {}
    func linkedApp(projectID: UUID) async throws -> ASCApp? { nil }
    func validateCredentials() async -> ASCConnectionStatus { .notConnected }
    func disconnect(projectID: UUID) async throws {}
    func diagnostics(projectID: UUID) async throws -> ASCDiagnostics {
        ASCDiagnostics(status: .notConnected)
    }
}

// MARK: - Connected Preview Service

actor PreviewASCServiceConnected: ASCServiceProtocol {
    func authenticate(credential: ASCCredential) async throws {}
    func isAuthenticated() async -> Bool { true }
    func removeAuth() async throws {}

    func fetchApps() async throws -> [ASCApp] {
        [
            ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS),
            ASCApp(id: "2", name: "Kitchee", bundleID: "com.helaia.Kitchee", platform: .iOS),
            ASCApp(id: "3", name: "Helaia Companion", bundleID: "com.helaia.Companion", platform: .visionOS),
        ]
    }

    func linkApp(_ app: ASCApp, projectID: UUID) async throws {}
    func unlinkApp(projectID: UUID) async throws {}

    func linkedApp(projectID: UUID) async throws -> ASCApp? {
        ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)
    }

    func validateCredentials() async -> ASCConnectionStatus {
        .connected(appName: "Codalon")
    }

    func disconnect(projectID: UUID) async throws {}

    func diagnostics(projectID: UUID) async throws -> ASCDiagnostics {
        ASCDiagnostics(
            status: .connected(appName: "Codalon"),
            linkedAppName: "Codalon",
            linkedBundleID: "com.helaia.Codalon",
            lastSuccessfulFetch: Date().addingTimeInterval(-300)
        )
    }
}

// MARK: - Expired Credentials Preview Service

actor PreviewASCServiceExpired: ASCServiceProtocol {
    func authenticate(credential: ASCCredential) async throws {}
    func isAuthenticated() async -> Bool { true }
    func removeAuth() async throws {}
    func fetchApps() async throws -> [ASCApp] { throw ASCServiceError.credentialsExpired }
    func linkApp(_ app: ASCApp, projectID: UUID) async throws {}
    func unlinkApp(projectID: UUID) async throws {}
    func linkedApp(projectID: UUID) async throws -> ASCApp? { nil }
    func validateCredentials() async -> ASCConnectionStatus { .credentialsExpired }
    func disconnect(projectID: UUID) async throws {}
    func diagnostics(projectID: UUID) async throws -> ASCDiagnostics {
        ASCDiagnostics(status: .credentialsExpired)
    }
}
