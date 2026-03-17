// Issue #8 — Ambient layer stub (solid color per context)

import SwiftUI

struct AmbientLayer: View {

    @Environment(\.projectContext) private var context

    var body: some View {
        contextColor
            .ignoresSafeArea()
    }

    private var contextColor: Color {
        switch context {
        case .development: return Color(hex: "#1A1E2E")
        case .release: return Color(hex: "#1E1A10")
        case .launch: return Color(hex: "#101E1A")
        }
    }
}

// MARK: - Hex Color Initializer

private extension Color {

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
