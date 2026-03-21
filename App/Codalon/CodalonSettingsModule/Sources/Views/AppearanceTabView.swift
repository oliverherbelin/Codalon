// Issue #213 — Appearance tab: theme, accent color, density

import SwiftUI
import HelaiaDesign

// MARK: - AppearanceTabView

struct AppearanceTabView: View {

    // MARK: - Environment

    @Environment(AppearanceState.self) private var appearance
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: - Body

    var body: some View {
        @Bindable var appearance = appearance

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Appearance",
                    subtitle: "Customize the look and feel of Codalon."
                )

                colorSchemeSection
                accentColorSection

                HelaiaCard(variant: .outlined) {
                    VStack(alignment: .leading, spacing: Spacing._3) {
                        Text("Density")
                            .helaiaFont(.headline)

                        HelaiaSegmentedPicker(
                            selection: $appearance.density,
                            options: [
                                HelaiaPickerOption(id: .compact, label: "Compact"),
                                HelaiaPickerOption(id: .regular, label: "Regular"),
                                HelaiaPickerOption(id: .comfortable, label: "Comfortable")
                            ]
                        )
                    }
                    .padding(Spacing._4)
                }

                HelaiaCard(variant: .outlined) {
                    VStack(alignment: .leading, spacing: Spacing._3) {
                        Text("Accessibility")
                            .helaiaFont(.headline)

                        HelaiaSettingsRow(
                            title: "Reduce Motion",
                            subtitle: "Minimize animations throughout the app",
                            icon: "figure.walk.motion",
                            iconColor: .blue,
                            variant: .toggle($appearance.reduceMotion)
                        )

                        HelaiaSettingsRow(
                            title: "High Contrast",
                            subtitle: "Increase contrast for better readability",
                            icon: "circle.lefthalf.filled",
                            iconColor: .gray,
                            variant: .toggle($appearance.isHighContrast)
                        )
                    }
                    .padding(Spacing._4)
                }
            }
            .padding(Spacing._6)
        }
    }

    // MARK: - Color Scheme

    @ViewBuilder
    private var colorSchemeSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Color Scheme")
                    .helaiaFont(.headline)

                HelaiaSegmentedPicker(
                    selection: schemeSelection,
                    options: AppearanceScheme.pickerOptions
                )
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Accent Theme

    @ViewBuilder
    private var accentColorSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Accent Color")
                    .helaiaFont(.headline)

                HStack(spacing: Spacing._3) {
                    ForEach(AppearanceState.selectableThemes, id: \.self) { theme in
                        themeButton(theme)
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Theme Button

    @ViewBuilder
    private func themeButton(_ theme: HelaiaTheme) -> some View {
        let isSelected = appearance.accentTheme == theme

        Button {
            appearance.accentTheme = theme
        } label: {
            VStack(spacing: Spacing._1) {
                Circle()
                    .fill(theme.color(for: effectiveColorScheme))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.needsDarkText ? .black : .white)
                        }
                    }

                Text(theme.displayName)
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var effectiveColorScheme: ColorScheme {
        appearance.colorScheme ?? systemColorScheme
    }

    // MARK: - Helpers

    private var schemeSelection: Binding<AppearanceScheme> {
        Binding(
            get: { AppearanceScheme(from: appearance.colorScheme) },
            set: { appearance.colorScheme = $0.colorScheme }
        )
    }
}

// MARK: - AppearanceScheme

extension AppearanceTabView {

    enum AppearanceScheme: String, Hashable, Sendable {
        case light
        case dark
        case system

        var colorScheme: ColorScheme? {
            switch self {
            case .light: .light
            case .dark: .dark
            case .system: nil
            }
        }

        init(from colorScheme: ColorScheme?) {
            switch colorScheme {
            case .light: self = .light
            case .dark: self = .dark
            case nil: self = .system
            @unknown default: self = .system
            }
        }

        static let pickerOptions: [HelaiaPickerOption<AppearanceScheme>] = [
            HelaiaPickerOption(id: .light, label: "Light"),
            HelaiaPickerOption(id: .dark, label: "Dark"),
            HelaiaPickerOption(id: .system, label: "System")
        ]
    }
}

// MARK: - Preview

#Preview("Appearance") {
    AppearanceTabView()
        .environment(AppearanceState())
        .frame(width: 500, height: 600)
}
