// Issue #190 — Dashboard layout: Launch Mode Canvas

import SwiftUI
import HelaiaDesign

// MARK: - LaunchModeCanvas

struct LaunchModeCanvas: View {

    // MARK: - Properties

    let version: String
    let daysSinceLaunch: Int
    let crashRate: Double?
    let reviewCount: Int
    let averageRating: Double?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(
        version: String = "—",
        daysSinceLaunch: Int = 0,
        crashRate: Double? = nil,
        reviewCount: Int = 0,
        averageRating: Double? = nil
    ) {
        self.version = version
        self.daysSinceLaunch = daysSinceLaunch
        self.crashRate = crashRate
        self.reviewCount = reviewCount
        self.averageRating = averageRating
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let canvasHeight = geo.size.height

            VStack(spacing: CodalonSpacing.zoneGap) {
                // Zone 1 — Launch summary (60%)
                launchSummary
                    .frame(maxWidth: .infinity)
                    .frame(height: canvasHeight * 0.60)
                    .dashboardWidgetAppearance(delay: 0)

                // Zone 2 — Metrics row (40%)
                HStack(spacing: CodalonSpacing.zoneGap) {
                    crashRateCard
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.06)

                    reviewsCard
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.12)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(24)
        }
    }

    // MARK: - Launch Summary

    @ViewBuilder
    private var launchSummary: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing.Card.padding) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView(
                        "antenna.radiowaves.left.and.right",
                        size: .md,
                        color: CodalonContext.launch.theme.color(for: colorScheme)
                    )
                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("Post-Launch Monitoring")
                            .helaiaFont(.headline)
                        Text("v\(version) — Day \(daysSinceLaunch)")
                            .helaiaFont(.subheadline)
                            .helaiaForeground(.textSecondary)
                    }
                    Spacer()
                }
                Text("Monitor crash rates, reviews, and user feedback during the post-launch window.")
                    .helaiaFont(.footnote)
                    .helaiaForeground(.textSecondary)
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Crash Rate Card

    @ViewBuilder
    private var crashRateCard: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "exclamationmark.triangle.fill",
                        size: .sm,
                        color: crashRateColor
                    )
                    Text("CRASH RATE")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                if let crashRate {
                    Text(String(format: "%.2f%%", crashRate * 100))
                        .helaiaFont(.title3)
                        .codalonMonospaced()
                        .foregroundStyle(crashRateColor)
                } else {
                    Text("No data")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textTertiary)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    private var crashRateColor: Color {
        guard let crashRate else { return SemanticColor.textSecondary(for: colorScheme) }
        if crashRate < 0.01 { return SemanticColor.success(for: colorScheme) }
        if crashRate < 0.03 { return SemanticColor.warning(for: colorScheme) }
        return SemanticColor.error(for: colorScheme)
    }

    // MARK: - Reviews Card

    @ViewBuilder
    private var reviewsCard: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "star.fill",
                        size: .sm,
                        color: SemanticColor.warning(for: colorScheme)
                    )
                    Text("REVIEWS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                HStack(spacing: CodalonSpacing.zoneGap) {
                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("\(reviewCount)")
                            .helaiaFont(.title3)
                            .codalonMonospaced()
                        Text("reviews")
                            .helaiaFont(.caption1)
                            .helaiaForeground(.textSecondary)
                    }
                    if let averageRating {
                        VStack(alignment: .leading, spacing: Spacing._1) {
                            Text(String(format: "%.1f", averageRating))
                                .helaiaFont(.title3)
                                .codalonMonospaced()
                            Text("avg rating")
                                .helaiaFont(.caption1)
                                .helaiaForeground(.textSecondary)
                        }
                    }
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }
}

// MARK: - Preview

#Preview("LaunchModeCanvas — Active") {
    LaunchModeCanvas(
        version: "1.2.0",
        daysSinceLaunch: 3,
        crashRate: 0.008,
        reviewCount: 42,
        averageRating: 4.6
    )
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .launch)
}

#Preview("LaunchModeCanvas — No Data") {
    LaunchModeCanvas()
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .launch)
}
