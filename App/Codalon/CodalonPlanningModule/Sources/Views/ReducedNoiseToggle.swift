// Issue #94 — Reduced-noise mode toggle

import SwiftUI
import HelaiaDesign

// MARK: - ReducedNoiseToggle

struct ReducedNoiseToggle: View {

    // MARK: - Properties

    @Binding var isEnabled: Bool

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Body

    var body: some View {
        let tint = context.theme.color(for: colorScheme)

        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                isEnabled ? "eye.slash" : "eye",
                size: .xs,
                color: isEnabled ? tint : SemanticColor.textSecondary(for: colorScheme)
            )

            Text("Focus mode")
                .helaiaFont(.caption1)
                .foregroundStyle(
                    isEnabled ? tint : SemanticColor.textSecondary(for: colorScheme)
                )

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(tint)
                .controlSize(.mini)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus mode: \(isEnabled ? "on" : "off")")
        .accessibilityHint("Hides low and medium priority items")
    }
}

// MARK: - Preview

#Preview("ReducedNoiseToggle") {
    @Previewable @State var enabled = false

    VStack(spacing: 16) {
        ReducedNoiseToggle(isEnabled: $enabled)
        Text("Reduced noise: \(enabled ? "ON" : "OFF")")
            .helaiaFont(.caption1)
    }
    .padding()
    .environment(\.projectContext, .development)
}
