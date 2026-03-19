// Issue #215 — Feature flag tab: toggle experimental features

import SwiftUI
import HelaiaDesign
import HelaiaCore

// MARK: - FeatureFlagTabView

struct FeatureFlagTabView: View {

    // MARK: - State

    @State private var flags: [FeatureFlag] = CodalonFeatureFlags.all
    @State private var showResetConfirmation = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Feature Flags",
                    subtitle: "Toggle experimental features. Changes take effect immediately."
                )

                flagsSection
                resetSection
            }
            .padding(Spacing._6)
        }
        .helaiaAlert(
            "Reset All Flags?",
            message: "All feature flags will be restored to their default values.",
            style: .destructive,
            isPresented: $showResetConfirmation,
            actions: [
                HelaiaAlertAction("Reset", role: .destructive) {
                    resetAllFlags()
                },
                HelaiaAlertAction("Cancel", role: .cancel),
            ]
        )
    }

    // MARK: - Flags Section

    @ViewBuilder
    private var flagsSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                ForEach(flags.indices, id: \.self) { index in
                    HelaiaSettingsRow(
                        title: flagDisplayName(flags[index].id),
                        subtitle: flags[index].description,
                        icon: "flag.fill",
                        iconColor: flags[index].isEnabled ? .green : .gray,
                        variant: .toggle(
                            Binding(
                                get: { flags[index].isEnabled },
                                set: { flags[index].isEnabled = $0 }
                            )
                        )
                    )
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Reset Section

    @ViewBuilder
    private var resetSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaSettingsRow(
                title: "Reset All Flags",
                subtitle: "Restore default values",
                icon: "arrow.counterclockwise",
                iconColor: .orange,
                variant: .button,
                isDestructive: true
            ) {
                showResetConfirmation = true
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Helpers

    private func flagDisplayName(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func resetAllFlags() {
        flags = CodalonFeatureFlags.all
    }
}

// MARK: - CodalonFeatureFlags

enum CodalonFeatureFlags {
    static let all: [FeatureFlag] = [
        FeatureFlag(id: "ai_assistant", isEnabled: true, description: "AI-powered code suggestions and insights"),
        FeatureFlag(id: "git_sync", isEnabled: true, description: "Background sync with GitHub repositories"),
        FeatureFlag(id: "analytics", isEnabled: true, description: "Local usage analytics collection"),
        FeatureFlag(id: "context_detection", isEnabled: true, description: "Automatic context switching based on project state"),
        FeatureFlag(id: "reduced_noise", isEnabled: false, description: "Hide low-priority widgets based on context"),
        FeatureFlag(id: "companion_sync", isEnabled: false, description: "Sync data with Codalon Companion (experimental)"),
    ]
}

// MARK: - Preview

#Preview("Feature Flags") {
    FeatureFlagTabView()
        .frame(width: 500, height: 600)
}
