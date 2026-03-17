// Issue #126 — Project summary card

import SwiftUI
import HelaiaDesign

// MARK: - ProjectSummaryCard

struct ProjectSummaryCard: View {

    // MARK: - Properties

    let projectName: String
    let platform: String
    let projectType: String
    let healthScore: Double
    let lastActivity: String

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .elevated, padding: false) {
            HStack(spacing: CodalonSpacing.zoneGap) {
                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text(projectName)
                        .helaiaFont(.headline)
                    HStack(spacing: Spacing._2) {
                        Text(platform)
                            .helaiaFont(.caption1)
                            .helaiaForeground(.textSecondary)
                        Text(projectType)
                            .helaiaFont(.caption1)
                            .helaiaForeground(.textSecondary)
                    }
                    Text(lastActivity)
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textTertiary)
                }
                Spacer()
                HelaiaProgressRing(
                    value: healthScore,
                    size: 48,
                    lineWidth: 4,
                    label: "\(Int(healthScore * 100))"
                )
            }
            .padding(CodalonSpacing.cardPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(projectName), \(platform) \(projectType). Health \(Int(healthScore * 100)) percent. \(lastActivity)"
        )
    }
}

// MARK: - Preview

#Preview("ProjectSummaryCard") {
    VStack(spacing: 16) {
        ProjectSummaryCard(
            projectName: "Codalon",
            platform: "macOS",
            projectType: "App",
            healthScore: 0.82,
            lastActivity: "Active 2 hours ago"
        )
        ProjectSummaryCard(
            projectName: "HelaiaFrameworks",
            platform: "Multiplatform",
            projectType: "Framework",
            healthScore: 0.45,
            lastActivity: "Active 3 days ago"
        )
    }
    .padding()
    .frame(width: 400)
}
