// Issue #190 — Dashboard layout: Release Mode Canvas

import SwiftUI
import HelaiaDesign

// MARK: - ReleaseModeCanvas

struct ReleaseModeCanvas: View {

    // MARK: - Properties

    let version: String
    let readinessScore: Double
    let blockerCount: Int
    let targetDate: Date?
    let checklistProgress: Double

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(
        version: String = "—",
        readinessScore: Double = 0,
        blockerCount: Int = 0,
        targetDate: Date? = nil,
        checklistProgress: Double = 0
    ) {
        self.version = version
        self.readinessScore = readinessScore
        self.blockerCount = blockerCount
        self.targetDate = targetDate
        self.checklistProgress = checklistProgress
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let canvasHeight = geo.size.height

            VStack(spacing: CodalonSpacing.zoneGap) {
                // Zone 1 — Release readiness (60%)
                ReleaseReadinessCard(
                    version: version,
                    readinessScore: readinessScore,
                    blockerCount: blockerCount,
                    targetDate: targetDate
                )
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight * 0.60)
                .dashboardWidgetAppearance(delay: 0)

                // Zone 2 — Bottom row (40%)
                HStack(spacing: CodalonSpacing.zoneGap) {
                    // Blockers summary
                    blockersSummary
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.06)

                    // Checklist progress
                    checklistSummary
                        .frame(maxWidth: .infinity)
                        .dashboardWidgetAppearance(delay: 0.12)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(24)
        }
    }

    // MARK: - Blockers Summary

    @ViewBuilder
    private var blockersSummary: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "xmark.octagon.fill",
                        size: .sm,
                        color: blockerCount > 0
                            ? SemanticColor.error(for: colorScheme)
                            : SemanticColor.success(for: colorScheme)
                    )
                    Text("BLOCKERS")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                Text("\(blockerCount) active")
                    .helaiaFont(.title3)
                    .foregroundStyle(
                        blockerCount > 0
                            ? SemanticColor.error(for: colorScheme)
                            : SemanticColor.success(for: colorScheme)
                    )
                if blockerCount == 0 {
                    Text("All clear — ready to ship")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }

    // MARK: - Checklist Summary

    @ViewBuilder
    private var checklistSummary: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                HStack(spacing: Spacing._2) {
                    HelaiaIconView(
                        "checklist",
                        size: .sm,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                    Text("CHECKLIST")
                        .helaiaFont(.tag)
                        .tracking(0.5)
                        .helaiaForeground(.textSecondary)
                    Spacer()
                }
                HStack(spacing: CodalonSpacing.zoneGap) {
                    HelaiaProgressRing(
                        value: checklistProgress,
                        size: 48,
                        lineWidth: 5,
                        label: "\(Int(checklistProgress * 100))%"
                    )
                    Text(checklistProgress >= 1.0 ? "Complete" : "In progress")
                        .helaiaFont(.buttonSmall)
                        .helaiaForeground(.textSecondary)
                }
            }
            .padding(CodalonSpacing.cardPadding)
        }
    }
}

// MARK: - Preview

#Preview("ReleaseModeCanvas — Active") {
    ReleaseModeCanvas(
        version: "1.2.0",
        readinessScore: 0.72,
        blockerCount: 2,
        targetDate: Calendar.current.date(byAdding: .day, value: 7, to: .now),
        checklistProgress: 0.65
    )
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .release)
}

#Preview("ReleaseModeCanvas — Ready") {
    ReleaseModeCanvas(
        version: "1.1.0",
        readinessScore: 1.0,
        blockerCount: 0,
        checklistProgress: 1.0
    )
    .frame(width: 1200, height: 760)
    .environment(\.projectContext, .release)
}
