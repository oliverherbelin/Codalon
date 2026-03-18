// Issue #190 — Dashboard layout: Maintenance Mode Canvas

import SwiftUI
import HelaiaDesign

// MARK: - MaintenanceModeCanvas

struct MaintenanceModeCanvas: View {

    // MARK: - Properties

    let healthScore: Double?
    let openBugCount: Int
    let lastReleaseVersion: String?
    let daysSinceLastRelease: Int?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(
        healthScore: Double? = nil,
        openBugCount: Int = 0,
        lastReleaseVersion: String? = nil,
        daysSinceLastRelease: Int? = nil
    ) {
        self.healthScore = healthScore
        self.openBugCount = openBugCount
        self.lastReleaseVersion = lastReleaseVersion
        self.daysSinceLastRelease = daysSinceLastRelease
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let canvasHeight = geo.size.height

            VStack(spacing: CodalonSpacing.zoneGap) {
                // Zone 1 — Maintenance summary (60%)
                maintenanceSummary
                    .frame(maxWidth: .infinity)
                    .frame(height: canvasHeight * 0.60)
                    .dashboardWidgetAppearance(delay: 0)

                // Zone 2 — Bottom row (40%)
                HStack(spacing: CodalonSpacing.zoneGap) {
                    healthCard
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.06)

                    bugsCard
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.12)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(24)
        }
    }

    // MARK: - Maintenance Summary

    @ViewBuilder
    private var maintenanceSummary: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            VStack(alignment: .leading, spacing: Spacing.Card.padding) {
                HStack(spacing: Spacing._3) {
                    HelaiaIconView(
                        "wrench.and.screwdriver.fill",
                        size: .md,
                        color: CodalonContext.maintenance.theme.color(for: colorScheme)
                    )
                    VStack(alignment: .leading, spacing: Spacing._1) {
                        Text("Maintenance Mode")
                            .helaiaFont(.headline)
                        if let version = lastReleaseVersion, let days = daysSinceLastRelease {
                            Text("Last release: v\(version) (\(days)d ago)")
                                .helaiaFont(.subheadline)
                                .helaiaForeground(.textSecondary)
                        }
                    }
                    Spacer()
                }
                Text("No active milestones or releases. Focus on bug fixes, dependency updates, and project health.")
                    .helaiaFont(.footnote)
                    .helaiaForeground(.textSecondary)
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Health Card

    @ViewBuilder
    private var healthCard: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "heart.text.square.fill",
                        size: .sm,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                    Text("HEALTH")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                if let healthScore {
                    HStack(spacing: CodalonSpacing.zoneGap) {
                        HelaiaProgressRing(
                            value: healthScore,
                            size: 48,
                            lineWidth: 5,
                            label: "\(Int(healthScore * 100))%"
                        )
                        Text(healthScoreLabel)
                            .helaiaFont(.buttonSmall)
                            .foregroundStyle(healthScoreColor)
                    }
                } else {
                    Text("No data")
                        .helaiaFont(.footnote)
                        .helaiaForeground(.textTertiary)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    private var healthScoreLabel: String {
        guard let score = healthScore else { return "—" }
        switch score {
        case 0.8...: return "Healthy"
        case 0.6..<0.8: return "Needs Attention"
        default: return "At Risk"
        }
    }

    private var healthScoreColor: Color {
        guard let score = healthScore else { return SemanticColor.textSecondary(for: colorScheme) }
        switch score {
        case 0.8...: return SemanticColor.success(for: colorScheme)
        case 0.6..<0.8: return SemanticColor.warning(for: colorScheme)
        default: return SemanticColor.error(for: colorScheme)
        }
    }

    // MARK: - Bugs Card

    @ViewBuilder
    private var bugsCard: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "ladybug.fill",
                        size: .sm,
                        color: openBugCount > 0
                            ? SemanticColor.warning(for: colorScheme)
                            : SemanticColor.success(for: colorScheme)
                    )
                    Text("OPEN BUGS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                Text("\(openBugCount)")
                    .helaiaFont(.title3)
                    .codalonMonospaced()
                    .foregroundStyle(
                        openBugCount > 0
                            ? SemanticColor.warning(for: colorScheme)
                            : SemanticColor.success(for: colorScheme)
                    )
                if openBugCount == 0 {
                    Text("No open bugs — clean slate")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }
}

// MARK: - Preview

#Preview("MaintenanceModeCanvas — Active") {
    MaintenanceModeCanvas(
        healthScore: 0.85,
        openBugCount: 3,
        lastReleaseVersion: "1.2.0",
        daysSinceLastRelease: 14
    )
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .maintenance)
}

#Preview("MaintenanceModeCanvas — Clean") {
    MaintenanceModeCanvas(healthScore: 0.95)
        .frame(width: 1200, height: 760)
        .environment(\.projectContext, .maintenance)
}
