// Issue #41 — ProjectHealthCard

import SwiftUI
import HelaiaDesign

// MARK: - ProjectHealthCard

public struct ProjectHealthCard: View {

    // MARK: - Properties

    private let healthScore: Double
    private let dimensions: [Dimension]

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(healthScore: Double, dimensions: [Dimension] = []) {
        self.healthScore = healthScore
        self.dimensions = dimensions
    }

    // MARK: - Body

    public var body: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing.Card.padding) {
                headerRow
                if !dimensions.isEmpty {
                    dimensionList
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardAccessibilityLabel)
    }

    // MARK: - Accessibility

    private var cardAccessibilityLabel: String {
        var label = "Project health: \(Int(healthScore * 100)) percent, \(healthDescription)"
        for dimension in dimensions {
            label += ". \(dimension.label): \(Int(dimension.value * 100)) percent"
        }
        return label
    }

    // MARK: - Header

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: CodalonSpacing.zoneGap) {
            HelaiaProgressRing(
                value: healthScore,
                size: 56,
                lineWidth: 5,
                label: scoreLabel
            )
            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("Project Health")
                    .helaiaFont(.headline)
                Text(healthDescription)
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Dimensions

    @ViewBuilder
    private var dimensionList: some View {
        VStack(spacing: Spacing._2) {
            ForEach(dimensions) { dimension in
                HStack {
                    Text(dimension.label)
                        .helaiaFont(.subheadline)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                    HelaiaProgressBar(
                        value: dimension.value,
                        height: .thin
                    )
                    .frame(width: 80)
                    Text("\(Int(dimension.value * 100))%")
                        .helaiaFont(.caption1)
                        .codalonMonospaced()
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Computed

    private var scoreLabel: String {
        "\(Int(healthScore * 100))"
    }

    private var healthDescription: String {
        switch healthScore {
        case 0.8...: "Healthy"
        case 0.5...: "Needs Attention"
        default: "Critical"
        }
    }
}

// MARK: - Dimension

extension ProjectHealthCard {

    public struct Dimension: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let value: Double

        public init(id: String, label: String, value: Double) {
            self.id = id
            self.label = label
            self.value = value
        }
    }
}

// MARK: - Preview

#Preview("ProjectHealthCard") {
    VStack(spacing: 20) {
        ProjectHealthCard(
            healthScore: 0.82,
            dimensions: [
                .init(id: "tasks", label: "Tasks", value: 0.75),
                .init(id: "milestones", label: "Milestones", value: 0.90),
                .init(id: "blockers", label: "Blockers", value: 0.60)
            ]
        )
        ProjectHealthCard(healthScore: 0.35)
    }
    .padding()
    .frame(width: 400)
}
