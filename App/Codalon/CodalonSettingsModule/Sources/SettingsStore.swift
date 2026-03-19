// Issues #204, #224 — Settings persistence store

import Foundation

// MARK: - CodalonSettings

/// Persisted settings values for the app.
public struct CodalonSettings: Sendable, Equatable {

    // MARK: - Notifications
    public var notificationsEnabled: Bool
    public var buildAlerts: Bool
    public var crashAlerts: Bool
    public var reviewAlerts: Bool
    public var releaseAlerts: Bool
    public var milestoneAlerts: Bool
    public var securityAlerts: Bool
    public var generalAlerts: Bool

    // MARK: - AI
    public var activeAIProvider: String
    public var selectedModel: String
    public var ollamaEndpoint: String

    // MARK: - Analytics
    public var analyticsEnabled: Bool

    // MARK: - Appearance
    public var colorScheme: String?
    public var density: String
    public var reduceMotion: Bool
    public var highContrast: Bool

    // MARK: - Feature Flags
    public var featureFlagOverrides: [String: Bool]

    // MARK: - Init

    nonisolated public init(
        notificationsEnabled: Bool = true,
        buildAlerts: Bool = true,
        crashAlerts: Bool = true,
        reviewAlerts: Bool = true,
        releaseAlerts: Bool = true,
        milestoneAlerts: Bool = true,
        securityAlerts: Bool = true,
        generalAlerts: Bool = false,
        activeAIProvider: String = "anthropic",
        selectedModel: String = "claude-sonnet-4-6",
        ollamaEndpoint: String = "http://localhost:11434",
        analyticsEnabled: Bool = true,
        colorScheme: String? = nil,
        density: String = "regular",
        reduceMotion: Bool = false,
        highContrast: Bool = false,
        featureFlagOverrides: [String: Bool] = [:]
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.buildAlerts = buildAlerts
        self.crashAlerts = crashAlerts
        self.reviewAlerts = reviewAlerts
        self.releaseAlerts = releaseAlerts
        self.milestoneAlerts = milestoneAlerts
        self.securityAlerts = securityAlerts
        self.generalAlerts = generalAlerts
        self.activeAIProvider = activeAIProvider
        self.selectedModel = selectedModel
        self.ollamaEndpoint = ollamaEndpoint
        self.analyticsEnabled = analyticsEnabled
        self.colorScheme = colorScheme
        self.density = density
        self.reduceMotion = reduceMotion
        self.highContrast = highContrast
        self.featureFlagOverrides = featureFlagOverrides
    }
}

// MARK: - Codable

extension CodalonSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case notificationsEnabled, buildAlerts, crashAlerts, reviewAlerts
        case releaseAlerts, milestoneAlerts, securityAlerts, generalAlerts
        case activeAIProvider, selectedModel, ollamaEndpoint
        case analyticsEnabled, colorScheme, density, reduceMotion, highContrast
        case featureFlagOverrides
    }

    nonisolated public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = try c.decode(Bool.self, forKey: .notificationsEnabled)
        buildAlerts = try c.decode(Bool.self, forKey: .buildAlerts)
        crashAlerts = try c.decode(Bool.self, forKey: .crashAlerts)
        reviewAlerts = try c.decode(Bool.self, forKey: .reviewAlerts)
        releaseAlerts = try c.decode(Bool.self, forKey: .releaseAlerts)
        milestoneAlerts = try c.decode(Bool.self, forKey: .milestoneAlerts)
        securityAlerts = try c.decode(Bool.self, forKey: .securityAlerts)
        generalAlerts = try c.decode(Bool.self, forKey: .generalAlerts)
        activeAIProvider = try c.decode(String.self, forKey: .activeAIProvider)
        selectedModel = try c.decode(String.self, forKey: .selectedModel)
        ollamaEndpoint = try c.decode(String.self, forKey: .ollamaEndpoint)
        analyticsEnabled = try c.decode(Bool.self, forKey: .analyticsEnabled)
        colorScheme = try c.decodeIfPresent(String.self, forKey: .colorScheme)
        density = try c.decode(String.self, forKey: .density)
        reduceMotion = try c.decode(Bool.self, forKey: .reduceMotion)
        highContrast = try c.decode(Bool.self, forKey: .highContrast)
        featureFlagOverrides = try c.decode([String: Bool].self, forKey: .featureFlagOverrides)
    }

    nonisolated public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try c.encode(buildAlerts, forKey: .buildAlerts)
        try c.encode(crashAlerts, forKey: .crashAlerts)
        try c.encode(reviewAlerts, forKey: .reviewAlerts)
        try c.encode(releaseAlerts, forKey: .releaseAlerts)
        try c.encode(milestoneAlerts, forKey: .milestoneAlerts)
        try c.encode(securityAlerts, forKey: .securityAlerts)
        try c.encode(generalAlerts, forKey: .generalAlerts)
        try c.encode(activeAIProvider, forKey: .activeAIProvider)
        try c.encode(selectedModel, forKey: .selectedModel)
        try c.encode(ollamaEndpoint, forKey: .ollamaEndpoint)
        try c.encode(analyticsEnabled, forKey: .analyticsEnabled)
        try c.encodeIfPresent(colorScheme, forKey: .colorScheme)
        try c.encode(density, forKey: .density)
        try c.encode(reduceMotion, forKey: .reduceMotion)
        try c.encode(highContrast, forKey: .highContrast)
        try c.encode(featureFlagOverrides, forKey: .featureFlagOverrides)
    }
}

// MARK: - SettingsStoreProtocol

public protocol SettingsStoreProtocol: Sendable {
    func load() async -> CodalonSettings
    func save(_ settings: CodalonSettings) async throws
}

// MARK: - SettingsStore

/// Actor-isolated settings persistence using JSON file storage.
public actor SettingsStore: SettingsStoreProtocol {

    private let fileURL: URL
    private var cached: CodalonSettings?

    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? SettingsStore.defaultURL
    }

    public func load() -> CodalonSettings {
        if let cached {
            return cached
        }

        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(CodalonSettings.self, from: data)
        else {
            let defaults = CodalonSettings()
            cached = defaults
            return defaults
        }

        cached = settings
        return settings
    }

    public func save(_ settings: CodalonSettings) throws {
        let data = try JSONEncoder().encode(settings)
        try data.write(to: fileURL, options: .atomic)
        cached = settings
    }

    /// Resets all settings to defaults.
    public func reset() throws {
        let defaults = CodalonSettings()
        try save(defaults)
    }

    // MARK: - Default URL

    nonisolated private static var defaultURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let codalonDir = appSupport.appendingPathComponent("Codalon", isDirectory: true)
        try? FileManager.default.createDirectory(at: codalonDir, withIntermediateDirectories: true)
        return codalonDir.appendingPathComponent("settings.json")
    }
}

// MARK: - InMemorySettingsStore (for tests)

public actor InMemorySettingsStore: SettingsStoreProtocol {
    private var settings: CodalonSettings

    public init(settings: CodalonSettings = CodalonSettings()) {
        self.settings = settings
    }

    public func load() -> CodalonSettings {
        settings
    }

    public func save(_ settings: CodalonSettings) {
        self.settings = settings
    }
}
