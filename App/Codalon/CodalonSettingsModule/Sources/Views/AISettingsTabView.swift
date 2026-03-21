// Issue #207 — AI settings tab: BYOK, model selection, usage display

import SwiftUI
import HelaiaDesign
import HelaiaAI
import HelaiaEngine
import HelaiaKeychain

// MARK: - AIProvider

enum CodalonAIProvider: String, CaseIterable, Identifiable, Sendable, Hashable {
    case openai
    case anthropic
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: "OpenAI"
        case .anthropic: "Anthropic"
        case .ollama: "Ollama (Local)"
        }
    }

    var iconName: String {
        switch self {
        case .openai: "cloud.fill"
        case .anthropic: "brain.head.profile.fill"
        case .ollama: "desktopcomputer"
        }
    }

    /// Maps to the HelaiaAI provider ID used by AIProviderManager.
    var providerID: String {
        switch self {
        case .openai: "openai"
        case .anthropic: "anthropic"
        case .ollama: "ollama"
        }
    }

    var requiresAPIKey: Bool {
        self != .ollama
    }

    var keychainKey: String? {
        switch self {
        case .anthropic: "com.helaia.ai.anthropic.apiKey"
        case .openai: "com.helaia.ai.openai.apiKey"
        case .ollama: nil
        }
    }
}

// MARK: - AISettingsTabView

struct AISettingsTabView: View {

    // MARK: - State

    @State private var selectedProvider: CodalonAIProvider = .anthropic
    @State private var selectedModelID: String = "claude-sonnet-4-6"
    @State private var availableModels: [AIModel] = []
    @State private var isLoadingModels = false
    @State private var isSavingKey = false
    @State private var apiKeyConfigured: [CodalonAIProvider: Bool] = [
        .openai: false,
        .anthropic: false,
        .ollama: true,
    ]
    @State private var ollamaEndpoint: String = "http://localhost:11434"
    @State private var tokenUsage: Int = 0
    @State private var isEditingKey = false
    @State private var apiKeyInput: String = ""
    @State private var resolvedManager: HelaiaAI.AIProviderManager?
    @State private var resolvedKeychain: (any KeychainServiceProtocol)?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "AI Settings",
                    subtitle: "Configure AI providers and models for code suggestions and insights."
                )

                providerSection
                modelSection
                apiKeySection
                usageSection
            }
            .padding(Spacing._6)
        }
        .task {
            await resolveDependencies()
            await checkKeyStatus()
            await loadModels()
        }
        .onChange(of: selectedProvider) { _, _ in
            Task {
                await checkKeyStatus()
                await loadModels()
            }
        }
    }

    // MARK: - Resolve Dependencies

    private func resolveDependencies() async {
        let container = ServiceContainer.shared
        resolvedManager = await container.resolveOptional(HelaiaAI.AIProviderManager.self)
        resolvedKeychain = await container.resolveOptional(
            (any KeychainServiceProtocol).self
        )
    }

    // MARK: - Check Key Status

    private func checkKeyStatus() async {
        guard let manager = resolvedManager else { return }

        for provider in CodalonAIProvider.allCases {
            let providerID = provider.providerID
            if let aiProvider = await manager.provider(for: providerID) {
                apiKeyConfigured[provider] = await aiProvider.isConfigured
            }
        }
    }

    // MARK: - Save API Key

    private func saveAPIKey() async {
        guard let keychain = resolvedKeychain,
              let keychainKey = selectedProvider.keychainKey,
              !apiKeyInput.isEmpty else { return }

        isSavingKey = true
        defer { isSavingKey = false }

        do {
            try await keychain.save(apiKeyInput, for: keychainKey, options: .standard)
            apiKeyConfigured[selectedProvider] = true
            isEditingKey = false
            apiKeyInput = ""
            await loadModels()
        } catch {
            // Key save failed — keep the editor open
        }
    }

    // MARK: - Load Models

    private func loadModels() async {
        guard let manager = resolvedManager else { return }

        isLoadingModels = true
        defer { isLoadingModels = false }

        let providerID = selectedProvider.providerID
        guard let provider = await manager.provider(for: providerID) else { return }

        do {
            let models = try await provider.availableModels()
            availableModels = models
            // Keep selection if still valid, otherwise pick first
            if !models.contains(where: { $0.id == selectedModelID }),
               let first = models.first {
                selectedModelID = first.id
            }
        } catch {
            availableModels = []
        }
    }

    // MARK: - Provider Section

    @ViewBuilder
    private var providerSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Active Provider")
                    .helaiaFont(.headline)

                HelaiaRadioGroup(
                    selection: $selectedProvider,
                    options: CodalonAIProvider.allCases.map { provider in
                        HelaiaRadioGroup.Option(
                            value: provider,
                            label: provider.displayName
                        )
                    }
                )

                ForEach(CodalonAIProvider.allCases) { provider in
                    if provider == selectedProvider {
                        HStack(spacing: Spacing._2) {
                            HelaiaIconView(provider.iconName, size: .sm)
                            Text(provider.displayName)
                                .helaiaFont(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HelaiaCapsule.tag(
                                provider.requiresAPIKey
                                    ? (apiKeyConfigured[provider] == true ? "Key configured" : "Key required")
                                    : "No key required",
                                icon: apiKeyConfigured[provider] == true ? "checkmark.circle.fill" : "info.circle"
                            )
                        }
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Model Section

    @ViewBuilder
    private var modelSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Model")
                    .helaiaFont(.headline)

                if isLoadingModels {
                    HStack(spacing: Spacing._2) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading models…")
                            .helaiaFont(.body)
                            .foregroundStyle(.secondary)
                    }
                } else if availableModels.isEmpty {
                    Text("No models available. Configure an API key to load models.")
                        .helaiaFont(.body)
                        .foregroundStyle(.secondary)
                } else {
                    HelaiaDropdownPicker(
                        selection: $selectedModelID,
                        options: availableModels.map { model in
                            HelaiaPickerOption(id: model.id, label: model.name)
                        },
                        label: "Model",
                        placeholder: "Select a model"
                    )
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - API Key Section

    @ViewBuilder
    private var apiKeySection: some View {
        if selectedProvider.requiresAPIKey {
            HelaiaCard(variant: .outlined) {
                VStack(alignment: .leading, spacing: Spacing._3) {
                    Text("API Key")
                        .helaiaFont(.headline)

                    if apiKeyConfigured[selectedProvider] == true {
                        HStack {
                            HelaiaIconView("checkmark.seal.fill", size: .sm, color: .green)
                            Text("API key is configured")
                                .helaiaFont(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HelaiaButton.ghost("Update", icon: "pencil") {
                                isEditingKey = true
                                apiKeyInput = ""
                            }
                        }
                    } else {
                        HStack {
                            HelaiaIconView("exclamationmark.circle", size: .sm, color: .orange)
                            Text("No API key configured")
                                .helaiaFont(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            HelaiaButton.ghost("Add Key", icon: "plus") {
                                isEditingKey = true
                                apiKeyInput = ""
                            }
                        }
                    }

                    if isEditingKey {
                        HStack(spacing: Spacing._2) {
                            HelaiaSecureField(
                                title: "API Key",
                                text: $apiKeyInput,
                                placeholder: "Enter API key"
                            )

                            HelaiaButton("Save", icon: "checkmark", variant: .primary, size: .small, isLoading: isSavingKey, fullWidth: false) {
                                Task { await saveAPIKey() }
                            }
                            .disabled(apiKeyInput.isEmpty || isSavingKey)

                            HelaiaButton.ghost("Cancel", icon: "xmark") {
                                isEditingKey = false
                                apiKeyInput = ""
                            }
                        }
                    }
                }
                .padding(Spacing._4)
            }
        } else {
            HelaiaCard(variant: .outlined) {
                VStack(alignment: .leading, spacing: Spacing._3) {
                    Text("Ollama Endpoint")
                        .helaiaFont(.headline)

                    HelaiaTextField(
                        title: "Endpoint URL",
                        text: $ollamaEndpoint,
                        placeholder: "http://localhost:11434"
                    )

                    Text("Ollama runs locally — no API key needed.")
                        .helaiaFont(.caption1)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing._4)
            }
        }
    }

    // MARK: - Usage Section

    @ViewBuilder
    private var usageSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Usage")
                    .helaiaFont(.headline)

                HelaiaSettingsRow(
                    title: "Tokens Used (Session)",
                    icon: "number",
                    iconColor: .orange,
                    variant: .info("\(tokenUsage.formatted())")
                )

                HelaiaSettingsRow(
                    title: "Requests Today",
                    icon: "arrow.up.arrow.down",
                    iconColor: .teal,
                    variant: .info("0")
                )
            }
            .padding(Spacing._4)
        }
    }
}

// MARK: - Preview

#Preview("AI Settings") {
    AISettingsTabView()
        .frame(width: 500, height: 700)
}
