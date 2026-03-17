// Issue #53 — ContextSwitcher

import SwiftUI
import HelaiaDesign

// MARK: - ContextSwitcher

public struct ContextSwitcher: View {

    // MARK: - Properties

    @Binding private var selectedContext: CodalonContext

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    public init(selectedContext: Binding<CodalonContext>) {
        self._selectedContext = selectedContext
    }

    // MARK: - Body

    public var body: some View {
        HelaiaMaterial.ultraThin.apply(to:
            HStack(spacing: Spacing._1) {
                ForEach(CodalonContext.allCases, id: \.self) { context in
                    contextButton(context)
                }
            }
            .padding(Spacing._1)
        )
        .clipShape(Capsule())
        .codalonShadow(CodalonShadow.pill)
    }

    // MARK: - Context Button

    @ViewBuilder
    private func contextButton(_ context: CodalonContext) -> some View {
        let isSelected = selectedContext == context
        let tint = context.theme.color(for: colorScheme)

        Button {
            withAnimation(
                CodalonAnimation.animation(
                    CodalonAnimation.contextTransition,
                    reduceMotion: reduceMotion
                )
            ) {
                selectedContext = context
            }
        } label: {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    context.iconName,
                    size: .xs,
                    color: isSelected ? .white : tint
                )
                if isSelected {
                    Text(context.displayName)
                        .helaiaFont(.tag)
                }
            }
            .padding(.horizontal, isSelected ? 14 : 10)
            .padding(.vertical, Spacing._2)
            .foregroundStyle(isSelected ? .white : tint)
            .background {
                if isSelected {
                    Capsule()
                        .fill(tint)
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(HelaiaCapsulePressStyle())
        .accessibilityLabel(context.displayName)
        .accessibilityHint("Switch to \(context.displayName) context")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("ContextSwitcher") {
    struct PreviewWrapper: View {
        @State private var context: CodalonContext = .development

        var body: some View {
            VStack(spacing: 20) {
                ContextSwitcher(selectedContext: $context)
                Text("Active: \(context.displayName)")
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
