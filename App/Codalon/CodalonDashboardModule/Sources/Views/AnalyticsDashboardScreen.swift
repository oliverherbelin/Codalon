// Issue #235 — Build local analytics dashboard

import SwiftUI
import HelaiaDesign
import HelaiaAnalytics

// MARK: - AnalyticsDashboardViewModel

@Observable
final class AnalyticsDashboardViewModel {

    // MARK: - State

    var summary: AnalyticsSummary?
    var selectedPeriod: AnalyticsPeriod = .week
    var recentEvents: [AnalyticsEvent] = []
    var isLoading = false

    // MARK: - Dependencies

    private let analyticsService: any CodalonAnalyticsServiceProtocol

    // MARK: - Init

    init(analyticsService: any CodalonAnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }

    // MARK: - Load

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        summary = await analyticsService.summary(period: selectedPeriod)
        let all = await analyticsService.allEvents()
        recentEvents = Array(all.suffix(20).reversed())
    }

    func exportCSV() async -> Data? {
        // Export would use LocalAnalyticsService.exportCSV if exposed
        nil
    }
}

// MARK: - Period Picker Option

nonisolated enum AnalyticsPeriodOption: String, CaseIterable, Hashable, Sendable {
    case today
    case week
    case month
    case allTime

    nonisolated var label: String {
        switch self {
        case .today: "Today"
        case .week: "Week"
        case .month: "Month"
        case .allTime: "All Time"
        }
    }

    nonisolated var period: AnalyticsPeriod {
        switch self {
        case .today: .today
        case .week: .week
        case .month: .month
        case .allTime: .allTime
        }
    }

    nonisolated init(from period: AnalyticsPeriod) {
        switch period {
        case .today: self = .today
        case .week: self = .week
        case .month: self = .month
        case .allTime: self = .allTime
        }
    }

    nonisolated static var allOptions: [HelaiaPickerOption<AnalyticsPeriodOption>] {
        allCases.map { HelaiaPickerOption(id: $0, label: $0.label) }
    }
}

// MARK: - AnalyticsDashboardScreen

struct AnalyticsDashboardScreen: View {

    @State private var viewModel: AnalyticsDashboardViewModel
    @State private var periodOption: AnalyticsPeriodOption = .week

    init(analyticsService: any CodalonAnalyticsServiceProtocol) {
        _viewModel = State(wrappedValue: AnalyticsDashboardViewModel(analyticsService: analyticsService))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing._6) {
                HelaiaPageHeader(
                    "Analytics",
                    subtitle: "Local-only usage insights"
                )

                periodPickerSection

                if let summary = viewModel.summary {
                    statsCardsSection(summary)
                    categoryChartSection(summary)
                    topFeaturesSection(summary)
                } else if !viewModel.isLoading {
                    emptyStateSection
                }

                recentEventsSection
                exportSection
            }
            .padding(Spacing._6)
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: periodOption) { _, newValue in
            viewModel.selectedPeriod = newValue.period
            Task { await viewModel.loadData() }
        }
    }

    // MARK: - Period Picker

    @ViewBuilder
    private var periodPickerSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Time Period")
                    .helaiaFont(.headline)

                HelaiaSegmentedPicker(
                    selection: $periodOption,
                    options: AnalyticsPeriodOption.allOptions,
                    label: "Period"
                )
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Stats Cards

    @ViewBuilder
    private func statsCardsSection(_ summary: AnalyticsSummary) -> some View {
        HStack(spacing: Spacing._4) {
            statCard("Total Events", value: "\(summary.totalEvents)")
            statCard("Active Days", value: "\(summary.activeDays)")
            statCard("Categories", value: "\(summary.eventsByCategory.count)")
        }
    }

    @ViewBuilder
    private func statCard(_ title: String, value: String) -> some View {
        HelaiaCard(variant: .outlined) {
            VStack(spacing: Spacing._1) {
                Text(value)
                    .helaiaFont(.title1)
                    .fontWeight(.bold)
                Text(title)
                    .helaiaFont(.caption1)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing._4)
        }
    }

    // MARK: - Category Chart

    @ViewBuilder
    private func categoryChartSection(_ summary: AnalyticsSummary) -> some View {
        if !summary.eventsByCategory.isEmpty {
            HelaiaCard(variant: .outlined) {
                VStack(alignment: .leading, spacing: Spacing._4) {
                    Text("Events by Category")
                        .helaiaFont(.headline)

                    HelaiaBarChart(
                        title: nil,
                        data: summary.eventsByCategory
                            .sorted { $0.value > $1.value }
                            .map { category, count in
                                HelaiaChartDataPoint(
                                    label: category.rawValue,
                                    value: Double(count)
                                )
                            }
                    )
                }
                .padding(Spacing._4)
            }
        }
    }

    // MARK: - Top Features

    @ViewBuilder
    private func topFeaturesSection(_ summary: AnalyticsSummary) -> some View {
        if !summary.topFeatures.isEmpty {
            HelaiaCard(variant: .outlined) {
                VStack(alignment: .leading, spacing: Spacing._3) {
                    Text("Top Features")
                        .helaiaFont(.headline)

                    ForEach(Array(summary.topFeatures.enumerated()), id: \.offset) { _, feature in
                        HelaiaSettingsRow(
                            title: feature.name,
                            icon: "star.fill",
                            variant: .value("\(feature.count) uses")
                        )
                    }
                }
                .padding(Spacing._4)
            }
        }
    }

    // MARK: - Recent Events

    @ViewBuilder
    private var recentEventsSection: some View {
        HelaiaCard(variant: .outlined) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("Recent Events")
                    .helaiaFont(.headline)

                if viewModel.recentEvents.isEmpty {
                    HelaiaEmptyState(
                        icon: "clock",
                        title: "No Recent Events",
                        description: "Recent analytics events will appear here."
                    )
                    .padding(Spacing._4)
                } else {
                    ForEach(viewModel.recentEvents, id: \.id) { event in
                        HelaiaSettingsRow(
                            title: event.name,
                            subtitle: event.category.rawValue,
                            variant: .info(formatDate(event.timestamp))
                        )
                    }
                }
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateSection: some View {
        HelaiaCard(variant: .outlined) {
            HelaiaEmptyState(
                icon: "chart.bar",
                title: "No Analytics Data",
                description: "Analytics data will appear here as you use Codalon."
            )
            .padding(Spacing._6)
        }
    }

    // MARK: - Export

    @ViewBuilder
    private var exportSection: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._4) {
                HelaiaIconView("lock.shield", size: .md, color: .secondary)

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Privacy")
                        .helaiaFont(.headline)
                    Text("All analytics data is stored locally on this device. No data leaves this Mac.")
                        .helaiaFont(.caption1)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(Spacing._4)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Analytics Dashboard") {
    AnalyticsDashboardScreen(analyticsService: PreviewAnalyticsService())
        .frame(width: 800, height: 900)
}
