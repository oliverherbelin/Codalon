// Issue #154 — Animated dashboard transitions

import SwiftUI
import HelaiaDesign

// MARK: - DashboardTransition

struct DashboardTransition: ViewModifier {

    let isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 8)
            .animation(
                CodalonAnimation.animation(
                    CodalonAnimation.cardInteraction,
                    reduceMotion: reduceMotion
                ),
                value: isVisible
            )
    }
}

extension View {

    func dashboardTransition(isVisible: Bool) -> some View {
        modifier(DashboardTransition(isVisible: isVisible))
    }
}

// MARK: - DashboardWidgetAppearance

struct DashboardWidgetAppearance: ViewModifier {

    let delay: Double

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(
                        CodalonAnimation.cardInteraction.delay(delay)
                    ) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {

    func dashboardWidgetAppearance(delay: Double = 0) -> some View {
        modifier(DashboardWidgetAppearance(delay: delay))
    }
}
