// Issue #192 — Context-aware sidebar view

import SwiftUI
import HelaiaDesign

// MARK: - ContextSidebarView

struct ContextSidebarView: View {

    // MARK: - Properties

    @Binding var selectedSection: String?

    // MARK: - Environment

    @Environment(\.projectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        let sections = ContextSidebarConfig.sections(for: context)

        VStack(alignment: .leading, spacing: Spacing._1) {
            ForEach(sections) { section in
                sidebarRow(section)
            }
            Spacer()
        }
        .padding(.vertical, Spacing._3)
        .padding(.horizontal, Spacing._2)
        .animation(
            CodalonAnimation.animation(
                CodalonAnimation.contextTransition,
                reduceMotion: reduceMotion
            ),
            value: context
        )
    }

    // MARK: - Row

    @ViewBuilder
    private func sidebarRow(_ section: SidebarSection) -> some View {
        let isSelected = selectedSection == section.id
        let tint = context.theme.color(for: colorScheme)

        Button {
            selectedSection = section.id
        } label: {
            HStack(spacing: Spacing._2) {
                HelaiaIconView(
                    section.iconName,
                    size: .sm,
                    color: isSelected
                        ? tint
                        : section.isHighlighted
                            ? SemanticColor.textPrimary(for: colorScheme)
                            : SemanticColor.textTertiary(for: colorScheme)
                )
                Text(section.label)
                    .helaiaFont(section.isHighlighted ? .buttonSmall : .caption1)
                    .foregroundStyle(
                        isSelected
                            ? tint
                            : section.isHighlighted
                                ? SemanticColor.textPrimary(for: colorScheme)
                                : SemanticColor.textTertiary(for: colorScheme)
                    )
                Spacer()
            }
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1_5)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: CodalonRadius.row)
                        .fill(tint.opacity(0.12))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CodalonRadius.row))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("ContextSidebarView — Development") {
    struct Wrapper: View {
        @State private var selected: String? = "dashboard"
        var body: some View {
            ContextSidebarView(selectedSection: $selected)
                .frame(width: 200, height: 600)
                .environment(\.projectContext, .development)
        }
    }
    return Wrapper()
}

#Preview("ContextSidebarView — Release") {
    struct Wrapper: View {
        @State private var selected: String? = "releases"
        var body: some View {
            ContextSidebarView(selectedSection: $selected)
                .frame(width: 200, height: 600)
                .environment(\.projectContext, .release)
        }
    }
    return Wrapper()
}
