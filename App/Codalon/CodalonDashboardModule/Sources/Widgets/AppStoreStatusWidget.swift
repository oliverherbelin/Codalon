// Issue #140 — App Store status widget

import SwiftUI
import HelaiaDesign

// MARK: - AppStoreStatusWidget

struct AppStoreStatusWidget: View {

    // MARK: - Properties

    let data: AppStoreWidgetData?

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
    private func connectedContent(_ data: AppStoreWidgetData) -> some View {
        VStack(alignment: .leading, spacing: Spacing._3) {
            header
            HStack(spacing: CodalonSpacing.zoneGap) {
                if let build = data.latestBuild {
                    metricItem(label: "Latest Build", value: build)
                }
                metricItem(
                    label: "TestFlight",
                    value: data.testFlightStatus,
                    color: testFlightColor(data.testFlightStatus)
                )
                metricItem(
                    label: "Metadata",
                    value: "\(Int(data.metadataCompleteness * 100))%",
                    color: data.metadataCompleteness >= 1.0
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.warning(for: colorScheme)
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
                "app.badge",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("APP STORE")
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
        color: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing._0_5) {
            Text(label)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
            Text(value)
                .helaiaFont(.buttonSmall)
                .foregroundStyle(
                    color ?? SemanticColor.textPrimary(for: colorScheme)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private func testFlightColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active": SemanticColor.success(for: colorScheme)
        case "processing": SemanticColor.warning(for: colorScheme)
        case "expired": SemanticColor.error(for: colorScheme)
        default: SemanticColor.textSecondary(for: colorScheme)
        }
    }

    // MARK: - Disconnected Content

    @ViewBuilder
    private var disconnectedContent: some View {
        HelaiaEmptyState(
            icon: "app.badge",
            title: "No App Store app linked",
            description: "Connect in project settings"
        )
    }
}

// MARK: - AppStoreWidgetData

struct AppStoreWidgetData: Sendable, Equatable {
    let latestBuild: String?
    let testFlightStatus: String
    let metadataCompleteness: Double
}

// MARK: - Preview

#Preview("AppStoreStatusWidget") {
    VStack(spacing: 16) {
        AppStoreStatusWidget(
            data: AppStoreWidgetData(
                latestBuild: "Build 42",
                testFlightStatus: "Active",
                metadataCompleteness: 0.80
            )
        )
        AppStoreStatusWidget(data: nil)
            .frame(height: 120)
    }
    .padding()
    .frame(width: 400)
}
