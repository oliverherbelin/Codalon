// Issue #213 — Appearance tab: theme, accent color, density

import SwiftUI
import HelaiaDesign

// MARK: - AppearanceTabView

struct AppearanceTabView: View {

    // MARK: - State

    @State private var themeConfig = HelaiaThemeConfig.default

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Appearance",
                    subtitle: "Customize the look and feel of Codalon."
                )

                HelaiaThemeSettingsView(theme: $themeConfig)
            }
            .padding(Spacing._6)
        }
    }
}

// MARK: - Preview

#Preview("Appearance") {
    AppearanceTabView()
        .frame(width: 500, height: 600)
}
