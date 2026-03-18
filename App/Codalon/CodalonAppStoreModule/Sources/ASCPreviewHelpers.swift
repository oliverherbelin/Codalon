// Epics 14, 15 — Preview helpers for ASC module

import Foundation

// MARK: - Default Stubs for Epic 15 methods

private protocol ASCServiceEpic15Defaults: ASCServiceProtocol {}

extension ASCServiceEpic15Defaults {
    func fetchVersions(appID: String) async throws -> [ASCVersion] { [] }
    func fetchBuilds(appID: String) async throws -> [ASCBuild] { [] }
    func fetchTestFlightBuilds(appID: String) async throws -> [ASCTestFlightBuild] { [] }
    func fetchReleaseNotes(versionID: String) async throws -> [ASCReleaseNotes] { [] }
    func updateReleaseNotes(localizationID: String, whatsNew: String) async throws {}
    func fetchMetadataStatus(appID: String) async throws -> ASCMetadataStatus { ASCMetadataStatus(fields: []) }
    func fetchLocalizationStatus(versionID: String) async throws -> ASCLocalizationStatus { ASCLocalizationStatus(locales: []) }
    func detectMissingMetadata(appID: String) async throws -> [ASCMetadataField] { [] }
    func detectMissingLocalizations(versionID: String, threshold: Double) async throws -> [ASCLocaleCompleteness] { [] }
    func mapReadinessToRelease(appID: String, versionID: String, releaseID: UUID) async throws {}
}

// MARK: - Preview Service (Not Connected)

actor PreviewASCService: ASCServiceEpic15Defaults {
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

actor PreviewASCServiceConnected: ASCServiceEpic15Defaults {
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

    func fetchVersions(appID: String) async throws -> [ASCVersion] {
        [
            ASCVersion(id: "v1", versionString: "1.0", platform: .macOS, state: .prepareForSubmission),
            ASCVersion(id: "v2", versionString: "0.9", platform: .macOS, state: .readyForSale),
        ]
    }

    func fetchBuilds(appID: String) async throws -> [ASCBuild] {
        [
            ASCBuild(id: "b1", version: "1.0", buildNumber: "42", uploadedDate: Date(), processingState: .valid),
            ASCBuild(id: "b2", version: "1.0", buildNumber: "41", uploadedDate: Date().addingTimeInterval(-86400), processingState: .valid),
        ]
    }

    func fetchTestFlightBuilds(appID: String) async throws -> [ASCTestFlightBuild] {
        [
            ASCTestFlightBuild(id: "tf1", buildNumber: "42", version: "1.0", betaState: .inBetaTesting, expirationDate: Date().addingTimeInterval(7776000), testerGroups: ["Internal"]),
        ]
    }

    func fetchMetadataStatus(appID: String) async throws -> ASCMetadataStatus {
        ASCMetadataStatus(fields: [
            ASCMetadataField(id: "name", label: "App Name", isComplete: true, value: "Codalon"),
            ASCMetadataField(id: "subtitle", label: "Subtitle", isComplete: true, value: "Dev Command Center"),
            ASCMetadataField(id: "description", label: "Description", isComplete: true),
            ASCMetadataField(id: "keywords", label: "Keywords", isComplete: true),
            ASCMetadataField(id: "supportUrl", label: "Support URL", isComplete: true),
            ASCMetadataField(id: "marketingUrl", label: "Marketing URL", isComplete: false),
            ASCMetadataField(id: "privacyPolicyUrl", label: "Privacy Policy URL", isComplete: true),
        ])
    }
}

// MARK: - Expired Credentials Preview Service

actor PreviewASCServiceExpired: ASCServiceEpic15Defaults {
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
