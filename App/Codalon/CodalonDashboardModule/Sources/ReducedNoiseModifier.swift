// Issue #200 — Reduced-noise view modifier

import SwiftUI
import HelaiaDesign

// MARK: - Environment Key

struct ReducedNoiseKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var reducedNoise: Bool {
        get { self[ReducedNoiseKey.self] }
        set { self[ReducedNoiseKey.self] = newValue }
    }
}

// MARK: - ReducedNoiseModifier

/// Hides a widget when reduced-noise mode is active and the widget
/// is classified as low-priority for the current context.
struct ReducedNoiseModifier: ViewModifier {

    let widgetID: String

    @Environment(\.projectContext) private var context
    @Environment(\.reducedNoise) private var reducedNoise
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let visible = ReducedNoiseFilter.isVisible(
            widgetID: widgetID,
            context: context,
            reducedNoise: reducedNoise
        )

        if visible {
            content
                .transition(.opacity)
        }
    }
}

extension View {

    /// Conditionally hides this widget in reduced-noise mode
    /// based on the current context.
    func reducedNoiseAware(widgetID: String) -> some View {
        modifier(ReducedNoiseModifier(widgetID: widgetID))
    }
}

