// Issue #43 — ReleaseReadinessCard

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseReadinessCard

public struct ReleaseReadinessCard: View {

    // MARK: - Properties

    private let version: String
    private let readinessScore: Double
    private let blockerCount: Int
    private let targetDate: Date?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(
        version: String,
        readinessScore: Double,
        blockerCount: Int,
        targetDate: Date? = nil
    ) {
        self.version = version
        self.readinessScore = readinessScore
        self.blockerCount = blockerCount
        self.targetDate = targetDate
    }

    // MARK: - Body

    public var body: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing.Card.padding) {
                headerRow
                metricsRow
            }
            .padding(CodalonSpacing.cardPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardAccessibilityLabel)
    }

    // MARK: - Accessibility

    private var cardAccessibilityLabel: String {
        var label = "Release readiness for version \(version): \(Int(readinessScore * 100)) percent"
        label += ". \(blockerCount) blocker\(blockerCount == 1 ? "" : "s")"
        if let targetDate {
            label += ". Target: \(targetDate.formatted(.dateTime.month().day()))"
        }
        return label
    }

    // MARK: - Header

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: CodalonSpacing.zoneGap) {
            HelaiaProgressRing(
                value: readinessScore,
                size: 56,
                lineWidth: 5,
                label: "\(Int(readinessScore * 100))%"
            )
            VStack(alignment: .leading, spacing: Spacing._1) {
                Text("Release Readiness")
                    .helaiaFont(.headline)
                Text("v\(version)")
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Metrics

    @ViewBuilder
    private var metricsRow: some View {
        HStack(spacing: CodalonSpacing.zoneGap) {
            metricItem(
                label: "Blockers",
                value: "\(blockerCount)",
                color: blockerCount > 0
                    ? SemanticColor.error(for: colorScheme)
                    : SemanticColor.success(for: colorScheme)
            )
            if let targetDate {
                metricItem(
                    label: "Target",
                    value: targetDate.formatted(.dateTime.month().day()),
                    color: nil
                )
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func metricItem(label: String, value: String, color: Color?) -> some View {
        VStack(alignment: .leading, spacing: Spacing._0_5) {
            Text(label)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
            Text(value)
                .helaiaFont(.buttonSmall)
                .foregroundStyle(color ?? SemanticColor.textPrimary(for: colorScheme))
        }
    }
}

// MARK: - Preview

#Preview("ReleaseReadinessCard") {
    VStack(spacing: 20) {
        ReleaseReadinessCard(
            version: "1.2.0",
            readinessScore: 0.72,
            blockerCount: 2,
            targetDate: Calendar.current.date(byAdding: .day, value: 14, to: .now)
        )
        ReleaseReadinessCard(
            version: "1.1.0",
            readinessScore: 1.0,
            blockerCount: 0
        )
    }
    .padding()
    .frame(width: 400)
}
