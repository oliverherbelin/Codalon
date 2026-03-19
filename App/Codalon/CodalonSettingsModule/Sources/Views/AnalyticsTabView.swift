// Issue #211 — Analytics tab: toggle, local event counts

import SwiftUI
import HelaiaDesign
import HelaiaAnalytics

// MARK: - AnalyticsTabView

struct AnalyticsTabView: View {

    // MARK: - Dependencies

    private let analyticsService: (any CodalonAnalyticsServiceProtocol)?

    // MARK: - State

    @State private var analyticsEnabled = true
    @State private var totalEvents: Int = 0
    @State private var activeDays: Int = 0
    @State private var categoryBreakdown: [(category: String, count: Int)] = []

    // MARK: - Init

    init(analyticsService: (any CodalonAnalyticsServiceProtocol)? = nil) {
        self.analyticsService = analyticsService
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Analytics",
                    subtitle: "Local-only usage analytics. No data leaves this device."
                )

                toggleSection
                summarySection
                privacySection
            }
            .padding(Spacing._6)
        }
        .task {
            await loadAnalyticsData()
        }
    }

    // MARK: - Toggle Section

    @ViewBuilder
    private var toggleSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaSettingsRow(
                title: "Enable Local Analytics",
                subtitle: "Track feature usage on this device",
                icon: "chart.bar.fill",
                iconColor: .blue,
                variant: .toggle($analyticsEnabled)
            )
            .padding(Spacing._4)
        }
    }

    // MARK: - Summary Section

    @ViewBuilder
    private var summarySection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._4) {
                Text("Usage Summary")
                    .helaiaFont(.headline)

                HStack(spacing: Spacing._4) {
                    HelaiaCard(variant: .outlined) {
                        VStack(spacing: Spacing._1) {
                            Text("\(totalEvents)")
                                .helaiaFont(.title1)
                                .fontWeight(.bold)
                            Text("Total Events")
                                .helaiaFont(.caption1)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    HelaiaCard(variant: .outlined) {
                        VStack(spacing: Spacing._1) {
                            Text("\(activeDays)")
                                .helaiaFont(.title1)
                                .fontWeight(.bold)
                            Text("Active Days")
                                .helaiaFont(.caption1)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if !categoryBreakdown.isEmpty {
                    Text("By Category")
                        .helaiaFont(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(categoryBreakdown, id: \.category) { item in
                        HelaiaSettingsRow(
                            title: item.category,
                            variant: .info("\(item.count)")
                        )
                    }
                } else {
                    HelaiaEmptyState(
                        icon: "chart.bar",
                        title: "No Data Yet",
                        description: "Analytics data will appear here as you use Codalon."
                    )
                }
            }
            .padding(Spacing._4)
        }
        .opacity(analyticsEnabled ? 1.0 : 0.5)
    }

    // MARK: - Privacy Section

    @ViewBuilder
    private var privacySection: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView("lock.shield", size: .lg, color: .secondary)

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Privacy")
                        .helaiaFont(.headline)
                    Text("All analytics data is stored locally on this device. Sensitive properties (passwords, tokens, keys) are automatically filtered. You can export data as CSV or clear it anytime.")
                        .helaiaFont(.caption1)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Data Loading

    private func loadAnalyticsData() async {
        guard let service = analyticsService else { return }

        let summary = await service.summary(period: .allTime)
        totalEvents = summary.totalEvents
        activeDays = summary.activeDays
        categoryBreakdown = summary.eventsByCategory
            .map { (category: $0.key.rawValue, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Preview

#Preview("Analytics") {
    AnalyticsTabView()
        .frame(width: 500, height: 600)
}
