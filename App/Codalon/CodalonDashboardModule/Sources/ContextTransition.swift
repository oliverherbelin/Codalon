// Issue #196 — Animated context transitions

import SwiftUI
import HelaiaDesign

// MARK: - ContextTransitionModifier

/// Applies animated transitions when the project context changes.
/// Uses CodalonAnimation.contextTransition with crossfade + subtle offset.
struct ContextTransitionModifier: ViewModifier {

    let context: CodalonContext

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .id(context)
            .transition(contextTransition)
            .animation(
                CodalonAnimation.animation(
                    CodalonAnimation.contextTransition,
                    reduceMotion: reduceMotion
                ),
                value: context
            )
    }

    private var contextTransition: AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 6)),
                removal: .opacity.combined(with: .offset(y: -6))
            )
        }
    }
}

// MARK: - View Extension

extension View {

    /// Animates content when the project context changes.
    /// Uses the standard Codalon context transition spring.
    func contextTransition(for context: CodalonContext) -> some View {
        modifier(ContextTransitionModifier(context: context))
    }
}

// MARK: - ContextThemeTintModifier

/// Tints a view's accent color to match the current context theme.
/// Animates the color change on context switch.
struct ContextThemeTintModifier: ViewModifier {

    let context: CodalonContext

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .tint(context.theme.color(for: colorScheme))
            .animation(
                CodalonAnimation.animation(
                    CodalonAnimation.ambientCrossFade,
                    reduceMotion: reduceMotion
                ),
                value: context
            )
    }
}

extension View {

    /// Applies the context theme tint with animated transition.
    func contextThemeTint(for context: CodalonContext) -> some View {
        modifier(ContextThemeTintModifier(context: context))
    }
}

// MARK: - Preview

#Preview("Context Transition") {
    struct Wrapper: View {
        @State private var context: CodalonContext = .development

        var body: some View {
            VStack(spacing: 20) {
                ContextSwitcher(selectedContext: $context)

                Group {
                    switch context {
                    case .development:
                        Text("Development Canvas")
                            .helaiaFont(.headline)
                    case .release:
                        Text("Release Canvas")
                            .helaiaFont(.headline)
                    case .launch:
                        Text("Launch Canvas")
                            .helaiaFont(.headline)
                    case .maintenance:
                        Text("Maintenance Canvas")
                            .helaiaFont(.headline)
                    }
                }
                .contextTransition(for: context)
                .frame(width: 400, height: 200)
                .background {
                    RoundedRectangle(cornerRadius: CodalonRadius.card)
                        .fill(Color.gray.opacity(0.1))
                }
            }
            .padding()
        }
    }

    return Wrapper()
}
