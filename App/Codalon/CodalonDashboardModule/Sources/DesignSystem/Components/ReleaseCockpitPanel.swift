// Issue #51 — ReleaseCockpitPanel

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseCockpitPanel

public struct ReleaseCockpitPanel<Content: View>: View {

    // MARK: - Properties

    private let title: String
    private let icon: String
    private let badgeCount: Int?
    private let content: Content

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(
        title: String,
        icon: String,
        badgeCount: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.badgeCount = badgeCount
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing.Card.padding) {
                panelHeader
                content
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var panelHeader: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                icon,
                size: .md,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text(title)
                .helaiaFont(.headline)
            if let badgeCount, badgeCount > 0 {
                Text("\(badgeCount)")
                    .helaiaFont(.tag)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing._1_5)
                    .padding(.vertical, Spacing._0_5)
                    .background {
                        Capsule().fill(SemanticColor.error(for: colorScheme))
                    }
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("ReleaseCockpitPanel") {
    VStack(spacing: 16) {
        ReleaseCockpitPanel(
            title: "Checklist",
            icon: "checklist",
            badgeCount: 3
        ) {
            VStack(alignment: .leading, spacing: Spacing._2) {
                Text("Screenshot assets")
                    .helaiaFont(.subheadline)
                Text("Privacy manifest")
                    .helaiaFont(.subheadline)
                Text("Release notes")
                    .helaiaFont(.subheadline)
            }
        }

        ReleaseCockpitPanel(title: "Blockers", icon: "xmark.octagon") {
            Text("No blockers")
                .helaiaFont(.subheadline)
                .helaiaForeground(.textSecondary)
        }
    }
    .padding()
    .frame(width: 400)
}
