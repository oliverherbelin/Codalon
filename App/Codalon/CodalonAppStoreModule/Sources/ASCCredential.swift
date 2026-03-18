// Issue #179 — ASC auth model

import Foundation

// MARK: - ASCCredential

public struct ASCCredential: Sendable, Equatable {
    public let issuerID: String
    public let keyID: String
    public let privateKey: String

    nonisolated public init(issuerID: String, keyID: String, privateKey: String) {
        self.issuerID = issuerID
        self.keyID = keyID
        self.privateKey = privateKey
    }
}

extension ASCCredential: Codable {
    private enum CodingKeys: String, CodingKey {
        case issuerID, keyID, privateKey
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.issuerID = try container.decode(String.self, forKey: .issuerID)
        self.keyID = try container.decode(String.self, forKey: .keyID)
        self.privateKey = try container.decode(String.self, forKey: .privateKey)
    }

    nonisolated public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(issuerID, forKey: .issuerID)
        try container.encode(keyID, forKey: .keyID)
        try container.encode(privateKey, forKey: .privateKey)
    }
}

// MARK: - ASCApp

public struct ASCApp: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let bundleID: String
    public let platform: ASCPlatform

    nonisolated public init(id: String, name: String, bundleID: String, platform: ASCPlatform) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platform = platform
    }
}

extension ASCApp: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, bundleID, platform
    }

    nonisolated public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.bundleID = try container.decode(String.self, forKey: .bundleID)
        self.platform = try container.decode(ASCPlatform.self, forKey: .platform)
    }

    nonisolated public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(bundleID, forKey: .bundleID)
        try container.encode(platform, forKey: .platform)
    }
}

// MARK: - ASCPlatform

public enum ASCPlatform: String, Codable, Sendable, Equatable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
    case tvOS = "TV_OS"
    case visionOS = "VISION_OS"

    public var displayName: String {
        switch self {
        case .iOS: "iOS"
        case .macOS: "macOS"
        case .tvOS: "tvOS"
        case .visionOS: "visionOS"
        }
    }
}

// MARK: - ASCConnectionStatus

public enum ASCConnectionStatus: Sendable, Equatable {
    case connected(appName: String)
    case credentialsExpired
    case notConnected
    case error(String)
}

// MARK: - ASCDiagnostics

public struct ASCDiagnostics: Sendable, Equatable {
    public let status: ASCConnectionStatus
    public let linkedAppName: String?
    public let linkedBundleID: String?
    public let lastSuccessfulFetch: Date?

    nonisolated public init(
        status: ASCConnectionStatus,
        linkedAppName: String? = nil,
        linkedBundleID: String? = nil,
        lastSuccessfulFetch: Date? = nil
    ) {
        self.status = status
        self.linkedAppName = linkedAppName
        self.linkedBundleID = linkedBundleID
        self.lastSuccessfulFetch = lastSuccessfulFetch
    }
}
