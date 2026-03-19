// Issue #224 — Settings persistence tests

import Foundation
import Testing
import HelaiaCore
@testable import Codalon

// MARK: - Settings Model Tests

@Suite("CodalonSettings")
@MainActor
struct CodalonSettingsTests {

    @Test("default settings have expected values")
    func defaultValues() {
        let settings = CodalonSettings()
        #expect(settings.notificationsEnabled == true)
        #expect(settings.buildAlerts == true)
        #expect(settings.crashAlerts == true)
        #expect(settings.reviewAlerts == true)
        #expect(settings.releaseAlerts == true)
        #expect(settings.milestoneAlerts == true)
        #expect(settings.securityAlerts == true)
        #expect(settings.generalAlerts == false)
        #expect(settings.activeAIProvider == "anthropic")
        #expect(settings.selectedModel == "claude-sonnet-4-6")
        #expect(settings.ollamaEndpoint == "http://localhost:11434")
        #expect(settings.analyticsEnabled == true)
        #expect(settings.colorScheme == nil)
        #expect(settings.density == "regular")
        #expect(settings.reduceMotion == false)
        #expect(settings.highContrast == false)
        #expect(settings.featureFlagOverrides.isEmpty)
    }

    @Test("settings roundtrip through JSON encoding")
    func jsonRoundtrip() throws {
        var settings = CodalonSettings()
        settings.notificationsEnabled = false
        settings.activeAIProvider = "openai"
        settings.selectedModel = "gpt-4o"
        settings.density = "compact"
        settings.featureFlagOverrides = ["ai_assistant": false, "git_sync": true]

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(CodalonSettings.self, from: data)

        #expect(decoded == settings)
        #expect(decoded.notificationsEnabled == false)
        #expect(decoded.activeAIProvider == "openai")
        #expect(decoded.selectedModel == "gpt-4o")
        #expect(decoded.density == "compact")
        #expect(decoded.featureFlagOverrides["ai_assistant"] == false)
        #expect(decoded.featureFlagOverrides["git_sync"] == true)
    }

    @Test("settings equality")
    func equality() {
        let a = CodalonSettings()
        let b = CodalonSettings()
        #expect(a == b)

        var c = CodalonSettings()
        c.notificationsEnabled = false
        #expect(a != c)
    }
}

// MARK: - InMemorySettingsStore Tests

@Suite("InMemorySettingsStore")
@MainActor
struct InMemorySettingsStoreTests {

    @Test("load returns default settings initially")
    func loadDefaults() async {
        let store = InMemorySettingsStore()
        let settings = await store.load()
        #expect(settings == CodalonSettings())
    }

    @Test("save persists settings")
    func saveAndLoad() async {
        let store = InMemorySettingsStore()

        var settings = CodalonSettings()
        settings.notificationsEnabled = false
        settings.activeAIProvider = "openai"
        await store.save(settings)

        let loaded = await store.load()
        #expect(loaded.notificationsEnabled == false)
        #expect(loaded.activeAIProvider == "openai")
    }

    @Test("multiple saves overwrite previous values")
    func multipleWrites() async {
        let store = InMemorySettingsStore()

        var v1 = CodalonSettings()
        v1.density = "compact"
        await store.save(v1)

        var v2 = CodalonSettings()
        v2.density = "comfortable"
        await store.save(v2)

        let loaded = await store.load()
        #expect(loaded.density == "comfortable")
    }

    @Test("can initialize with custom defaults")
    func customDefaults() async {
        var custom = CodalonSettings()
        custom.analyticsEnabled = false
        custom.reduceMotion = true

        let store = InMemorySettingsStore(settings: custom)
        let loaded = await store.load()
        #expect(loaded.analyticsEnabled == false)
        #expect(loaded.reduceMotion == true)
    }
}

// MARK: - SettingsStore File Tests

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {

    @Test("file-based store saves and loads settings")
    func fileRoundtrip() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("codalon-test-\(UUID().uuidString).json")

        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = SettingsStore(fileURL: tempURL)

        var settings = CodalonSettings()
        settings.notificationsEnabled = false
        settings.activeAIProvider = "ollama"
        settings.featureFlagOverrides = ["companion_sync": true]

        try await store.save(settings)

        // Create a fresh store to confirm file persistence
        let store2 = SettingsStore(fileURL: tempURL)
        let loaded = await store2.load()

        #expect(loaded.notificationsEnabled == false)
        #expect(loaded.activeAIProvider == "ollama")
        #expect(loaded.featureFlagOverrides["companion_sync"] == true)
    }

    @Test("load returns defaults when file missing")
    func missingFileReturnsDefaults() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("codalon-nonexistent-\(UUID().uuidString).json")

        let store = SettingsStore(fileURL: tempURL)
        let settings = await store.load()
        #expect(settings == CodalonSettings())
    }

    @Test("reset restores default settings")
    func resetToDefaults() async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("codalon-reset-\(UUID().uuidString).json")

        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = SettingsStore(fileURL: tempURL)

        var settings = CodalonSettings()
        settings.notificationsEnabled = false
        settings.density = "compact"
        try await store.save(settings)

        try await store.reset()

        let loaded = await store.load()
        #expect(loaded == CodalonSettings())
        #expect(loaded.notificationsEnabled == true)
        #expect(loaded.density == "regular")
    }
}

// MARK: - Feature Flag Config Tests

@Suite("CodalonFeatureFlags")
@MainActor
struct CodalonFeatureFlagTests {

    @Test("all flags have non-empty IDs")
    func nonEmptyIDs() {
        for flag in CodalonFeatureFlags.all {
            #expect(!flag.id.isEmpty)
        }
    }

    @Test("all flags have non-empty descriptions")
    func nonEmptyDescriptions() {
        for flag in CodalonFeatureFlags.all {
            #expect(!flag.description.isEmpty)
        }
    }

    @Test("flag IDs are unique")
    func uniqueIDs() {
        let ids = CodalonFeatureFlags.all.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test("feature flag toggle works")
    func toggleFlag() {
        var flag = FeatureFlag(id: "test", isEnabled: false, description: "Test flag")
        #expect(flag.isEnabled == false)
        flag.isEnabled = true
        #expect(flag.isEnabled == true)
    }
}

// MARK: - SettingsTab Tests

@Suite("SettingsTab")
@MainActor
struct SettingsTabTests {

    @Test("all tabs have non-empty labels")
    func nonEmptyLabels() {
        for tab in SettingsTab.allCases {
            #expect(!tab.label.isEmpty)
        }
    }

    @Test("all tabs have non-empty icon names")
    func nonEmptyIcons() {
        for tab in SettingsTab.allCases {
            #expect(!tab.iconName.isEmpty)
        }
    }

    @Test("only debug tab is debug-only")
    func debugOnly() {
        for tab in SettingsTab.allCases {
            if tab == .debug {
                #expect(tab.isDebugOnly == true)
            } else {
                #expect(tab.isDebugOnly == false)
            }
        }
    }

    @Test("tab IDs are unique")
    func uniqueIDs() {
        let ids = SettingsTab.allCases.map(\.id)
        let unique = Set(ids)
        #expect(ids.count == unique.count)
    }
}
