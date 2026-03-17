// Issue #49 — DashboardStrip

import SwiftUI
import HelaiaDesign

// MARK: - DashboardStrip

public struct DashboardStrip: View {

    // MARK: - Properties

    private let items: [Item]

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(items: [Item]) {
        self.items = items
    }

    // MARK: - Body

    public var body: some View {
        HelaiaMaterial.ultraThin.apply(to:
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .frame(height: 28)
                            .padding(.horizontal, CodalonSpacing.zoneGap)
                    }
                    stripItem(item)
                }
                Spacer()
            }
            .padding(.horizontal, CodalonSpacing.cardPadding)
            .padding(.vertical, 12)
        )
        .clipShape(RoundedRectangle(cornerRadius: CodalonRadius.row))
    }

    // MARK: - Strip Item

    @ViewBuilder
    private func stripItem(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: Spacing._0_5) {
            Text(item.label)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
            HStack(spacing: Spacing._1) {
                if let icon = item.icon {
                    HelaiaIconView(icon, size: .xs, color: item.color)
                }
                Text(item.value)
                    .helaiaFont(.buttonSmall)
                    .foregroundStyle(
                        item.color ?? SemanticColor.textPrimary(for: colorScheme)
                    )
            }
        }
    }
}

// MARK: - Item

extension DashboardStrip {

    public struct Item: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: String
        public let icon: String?
        public let color: Color?

        public init(
            id: String,
            label: String,
            value: String,
            icon: String? = nil,
            color: Color? = nil
        ) {
            self.id = id
            self.label = label
            self.value = value
            self.icon = icon
            self.color = color
        }
    }
}

// MARK: - Preview

#Preview("DashboardStrip") {
    VStack(spacing: 16) {
        DashboardStrip(items: [
            .init(id: "tasks", label: "Open Tasks", value: "12"),
            .init(id: "blockers", label: "Blockers", value: "2",
                  icon: "xmark.octagon.fill", color: SemanticColor.error(for: .light)),
            .init(id: "health", label: "Health", value: "82%",
                  color: SemanticColor.success(for: .light)),
            .init(id: "release", label: "Release", value: "v1.2.0")
        ])
    }
    .padding()
    .frame(width: 600)
}
