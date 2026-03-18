// Issue #181 — ASC credential storage via HelaiaKeychain

import Foundation
import HelaiaKeychain
import HelaiaLogger

// MARK: - Protocol

public protocol ASCCredentialServiceProtocol: Sendable {
    func save(_ credential: ASCCredential) async throws
    func load() async throws -> ASCCredential
    func delete() async throws
    func exists() async -> Bool
}

// MARK: - Implementation

public actor ASCCredentialService: ASCCredentialServiceProtocol {

    private static let keychainKey = "codalon.asc.credential"

    private let keychain: any KeychainServiceProtocol
    private let logger: any HelaiaLoggerProtocol

    public init(
        keychain: any KeychainServiceProtocol,
        logger: any HelaiaLoggerProtocol
    ) {
        self.keychain = keychain
        self.logger = logger
    }

    public func save(_ credential: ASCCredential) async throws {
        logger.info("Saving ASC credentials (keyID: \(credential.keyID))", category: "asc")
        try await keychain.save(
            credential,
            for: Self.keychainKey,
            options: KeychainItemOptions(
                accessibility: .whenUnlockedThisDeviceOnly
            )
        )
        logger.success("ASC credentials saved", category: "asc")
    }

    public func load() async throws -> ASCCredential {
        try await keychain.load(ASCCredential.self, for: Self.keychainKey)
    }

    public func delete() async throws {
        logger.info("Deleting ASC credentials from keychain", category: "asc")
        try await keychain.delete(for: Self.keychainKey)
        logger.success("ASC credentials removed", category: "asc")
    }

    public func exists() async -> Bool {
        await keychain.exists(for: Self.keychainKey)
    }
}
