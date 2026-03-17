// Issue #135 — GitHub status widget

import SwiftUI
import HelaiaDesign

// MARK: - GitHubStatusWidget

struct GitHubStatusWidget: View {

    // MARK: - Properties

    let data: GitHubWidgetData?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HelaiaCard(variant: .outlined, padding: false) {
            if let data {
                connectedContent(data)
            } else {
                disconnectedContent
            }
        }
    }

    // MARK: - Connected Content

    @ViewBuilder
    private func connectedContent(_ data: GitHubWidgetData) -> some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            header
            HStack(spacing: CodalonSpacing.zoneGap) {
                metricItem(
                    label: "Open Issues",
                    value: "\(data.openIssueCount)",
                    icon: "circle.fill",
                    color: data.openIssueCount > 0
                        ? SemanticColor.warning(for: colorScheme)
                        : SemanticColor.success(for: colorScheme)
                )
                metricItem(
                    label: "Open PRs",
                    value: "\(data.openPRCount)",
                    icon: "arrow.triangle.merge",
                    color: nil
                )
                metricItem(
                    label: "Commits (7d)",
                    value: "\(data.recentCommitCount)",
                    icon: "arrow.triangle.branch",
                    color: nil
                )
                Spacer()
            }
        }
        .padding(CodalonSpacing.cardPadding)
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "arrow.triangle.branch",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("GITHUB")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()
        }
    }

    @ViewBuilder
    private func metricItem(
        label: String,
        value: String,
        icon: String,
        color: Color?
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing._0_5) {
            Text(label)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
            HStack(spacing: Spacing._1) {
                HelaiaIconView(
                    icon,
                    size: .xs,
                    color: color ?? SemanticColor.textPrimary(for: colorScheme)
                )
                Text(value)
                    .helaiaFont(.buttonSmall)
                    .foregroundStyle(
                        color ?? SemanticColor.textPrimary(for: colorScheme)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Disconnected Content

    @ViewBuilder
    private var disconnectedContent: some View {
        HelaiaEmptyState(
            icon: "arrow.triangle.branch",
            title: "No repository linked",
            description: "Connect a repository in project settings"
        )
    }
}

// MARK: - GitHubWidgetData

struct GitHubWidgetData: Sendable, Equatable {
    let openIssueCount: Int
    let openPRCount: Int
    let recentCommitCount: Int
}

// MARK: - Preview

#Preview("GitHubStatusWidget") {
    VStack(spacing: 16) {
        GitHubStatusWidget(
            data: GitHubWidgetData(
                openIssueCount: 8,
                openPRCount: 2,
                recentCommitCount: 14
            )
        )
        GitHubStatusWidget(data: nil)
            .frame(height: 120)
    }
    .padding()
    .frame(width: 400)
}
