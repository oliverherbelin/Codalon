// Issue #204 — Settings screen with tab navigation

import SwiftUI
import HelaiaDesign

// MARK: - SettingsTab

enum SettingsTab: String, CaseIterable, Identifiable, Sendable {
    case integrations
    case ai
    case notifications
    case appearance
    case analytics
    case featureFlags
    case diagnostics
    case versions
    case debug

    var id: String { rawValue }

    var label: String {
        switch self {
        case .integrations: "Integrations"
        case .ai: "AI"
        case .notifications: "Notifications"
        case .appearance: "Appearance"
        case .analytics: "Analytics"
        case .featureFlags: "Feature Flags"
        case .diagnostics: "Diagnostics"
        case .versions: "About"
        case .debug: "Debug"
        }
    }

    var iconName: String {
        switch self {
        case .integrations: "link"
        case .ai: "brain"
        case .notifications: "bell.fill"
        case .appearance: "paintbrush.fill"
        case .analytics: "chart.bar.fill"
        case .featureFlags: "flag.fill"
        case .diagnostics: "stethoscope"
        case .versions: "info.circle.fill"
        case .debug: "ant.fill"
        }
    }

    var isDebugOnly: Bool {
        self == .debug
    }
}

// MARK: - SettingsView

struct SettingsView: View {

    // MARK: - State

    @State private var selectedTab: SettingsTab = .integrations

    // MARK: - Environment

    @Environment(AppearanceState.self) private var appearance
    @Environment(\.colorScheme) private var systemColorScheme

    private var colorScheme: ColorScheme {
        appearance.colorScheme ?? systemColorScheme
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 700, minHeight: 500)
        .helaiaDesignTokens(
            HelaiaDesignTokens(
                theme: appearance.accentTheme,
                themeMode: appearance.themeMode,
                themeConfig: appearance.themeConfig(for: colorScheme)
            )
        )
        .helaiaThemeConfig(appearance.themeConfig(for: colorScheme))
        .navigationTitle("")
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HelaiaPageHeader("Settings", showDivider: false)
                .padding(.horizontal, Spacing._3)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    ForEach(visibleTabs) { tab in
                        sidebarRow(tab)
                    }
                }
                .padding(.horizontal, Spacing._2)
            }
        }
        .padding(.vertical, Spacing._3)
        .frame(width: 200)
    }

    @ViewBuilder
    private func sidebarRow(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: Spacing._2) {
                HelaiaIconView(
                    tab.iconName,
                    size: .sm,
                    color: isSelected
                        ? SemanticColor.textPrimary(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme)
                )
                .frame(width: 20, alignment: .center)
                Text(tab.label)
                    .helaiaFont(isSelected ? .bodyEmphasized : .body)
                    .foregroundStyle(
                        isSelected
                            ? SemanticColor.textPrimary(for: colorScheme)
                            : SemanticColor.textSecondary(for: colorScheme)
                    )
                Spacer()
            }
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1_5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColor.surface(for: colorScheme))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var visibleTabs: [SettingsTab] {
        #if DEBUG
        SettingsTab.allCases
        #else
        SettingsTab.allCases.filter { !$0.isDebugOnly }
        #endif
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .integrations:
            IntegrationsTabView()
        case .ai:
            AISettingsTabView()
        case .notifications:
            NotificationsTabView()
        case .appearance:
            AppearanceTabView()
        case .analytics:
            AnalyticsTabView()
        case .featureFlags:
            FeatureFlagTabView()
        case .diagnostics:
            DiagnosticsTabView()
        case .versions:
            VersionsTabView()
        case .debug:
            DebugToolsTabView()
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
}
