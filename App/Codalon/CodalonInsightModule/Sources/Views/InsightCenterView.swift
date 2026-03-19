// Issue #178 — Display insight list

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaShare

// MARK: - InsightCenterView

struct InsightCenterView: View {

    // MARK: - State

    @State private var viewModel: InsightViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: InsightViewModel, projectName: String = "Project") {
        self._viewModel = State(initialValue: viewModel)
        self.projectName = projectName
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            header
            filterBar
            insightList
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadInsights()
            await viewModel.runRules()
        }
    }

    var projectName: String = "Project"

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "lightbulb.fill",
                size: .md,
                color: SemanticColor.warning(for: colorScheme)
            )
            Text("Insights")
                .helaiaFont(.headline)
            if !viewModel.actionableInsights.isEmpty {
                Text("\(viewModel.actionableInsights.count) actionable")
                    .helaiaFont(.caption1)
                    .padding(.horizontal, Spacing._1_5)
                    .padding(.vertical, Spacing._0_5)
                    .background {
                        Capsule()
                            .fill(SemanticColor.warning(for: colorScheme).opacity(0.15))
                    }
            }
            Spacer()

            Menu {
                Button {
                    exportInsightsMarkdown()
                } label: {
                    Label("Export as Markdown", systemImage: "arrow.down.doc")
                }
                Button {
                    exportInsightsPDF()
                } label: {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(viewModel.filteredInsights.isEmpty)
        }
    }

    // MARK: - Filter Bar

    @ViewBuilder
    private var filterBar: some View {
        HStack(spacing: Spacing._2) {
            severityMenu
            typeMenu
            Spacer()
            if viewModel.hasActiveFilters {
                HelaiaButton.ghost("Clear") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    @ViewBuilder
    private var severityMenu: some View {
        Menu {
            Button("All Severities") { viewModel.severityFilter = nil }
            Divider()
            ForEach(CodalonSeverity.allCases, id: \.self) { severity in
                Button(severityDisplayName(severity)) {
                    viewModel.severityFilter = severity
                }
            }
        } label: {
            filterChip(
                text: viewModel.severityFilter.map { severityDisplayName($0) } ?? "Severity"
            )
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private var typeMenu: some View {
        Menu {
            Button("All Types") { viewModel.typeFilter = nil }
            Divider()
            ForEach(CodalonInsightType.allCases, id: \.self) { type in
                Button(insightTypeDisplayName(type)) {
                    viewModel.typeFilter = type
                }
            }
        } label: {
            filterChip(
                text: viewModel.typeFilter.map { insightTypeDisplayName($0) } ?? "Type"
            )
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private func filterChip(text: String) -> some View {
        Text(text)
            .helaiaFont(.caption1)
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(SemanticColor.surface(for: colorScheme))
            }
    }

    // MARK: - Insight List

    @ViewBuilder
    private var insightList: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, Spacing._6)
        } else if viewModel.filteredInsights.isEmpty {
            HelaiaEmptyState(
                icon: "lightbulb.slash",
                title: viewModel.hasActiveFilters ? "No matching insights" : "No insights yet",
                description: viewModel.hasActiveFilters
                    ? "Try adjusting your filters"
                    : "Run the rule engine to detect issues"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    // Actionable section
                    if !viewModel.actionableInsights.isEmpty {
                        sectionHeader("Actionable")
                        ForEach(viewModel.actionableInsights, id: \.id) { insight in
                            InsightRowView(insight: insight, isActionable: true)
                        }
                    }

                    // Informational section
                    if !viewModel.informationalInsights.isEmpty {
                        sectionHeader("Informational")
                        ForEach(viewModel.informationalInsights, id: \.id) { insight in
                            InsightRowView(insight: insight, isActionable: false)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .helaiaFont(.tag)
            .tracking(0.5)
            .helaiaForeground(.textSecondary)
            .padding(.top, Spacing._2)
    }
}

// MARK: - Export

extension InsightCenterView {

    private func exportInsightsMarkdown() {
        let content = CodalonExportFormatter.insightsReportContent(
            insights: viewModel.filteredInsights,
            healthScore: Double(viewModel.overallScorePercent) / 100.0,
            projectName: projectName
        )
        let format = MarkdownExportFormat()

        Task {
            guard let data = try? await format.export(content),
                  let markdown = String(data: data, encoding: .utf8) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-insights.md"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func exportInsightsPDF() {
        let content = CodalonExportFormatter.insightsReportContent(
            insights: viewModel.filteredInsights,
            healthScore: Double(viewModel.overallScorePercent) / 100.0,
            projectName: projectName
        )
        let format = PDFExportFormat()

        Task {
            guard let data = try? await format.export(content) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-insights.pdf"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - InsightRowView

struct InsightRowView: View {

    let insight: CodalonInsight
    let isActionable: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HelaiaCard(variant: isActionable ? .outlined : .filled, padding: false) {
            HStack(spacing: CodalonSpacing.zoneGap) {
                severityBar
                content
                Spacer()
                typeLabel
            }
            .padding(Spacing._3)
        }
    }

    @ViewBuilder
    private var severityBar: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(insightSeverityColor(insight.severity, colorScheme: colorScheme))
            .frame(width: 4, height: 44)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    insightTypeIcon(insight.type),
                    size: .xs,
                    color: insightSeverityColor(insight.severity, colorScheme: colorScheme)
                )
                Text(insight.title)
                    .helaiaFont(.buttonSmall)
                    .fontWeight(isActionable ? .semibold : .regular)
            }
            Text(insight.message)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
                .lineLimit(2)
            HStack(spacing: Spacing._2) {
                Text(insightTypeDisplayName(insight.type))
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
                Text(insight.createdAt.formatted(.relative(presentation: .named)))
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var typeLabel: some View {
        if isActionable {
            Text("ACTION")
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.warning(for: colorScheme))
                .padding(.horizontal, Spacing._1_5)
                .padding(.vertical, Spacing._0_5)
                .background {
                    Capsule()
                        .fill(SemanticColor.warning(for: colorScheme).opacity(0.12))
                }
        }
    }
}

// MARK: - Display Helpers (nonisolated free functions)

nonisolated func insightTypeDisplayName(_ type: CodalonInsightType) -> String {
    switch type {
    case .suggestion: "Suggestion"
    case .anomaly: "Anomaly"
    case .trend: "Trend"
    case .reminder: "Reminder"
    }
}

nonisolated func insightTypeIcon(_ type: CodalonInsightType) -> String {
    switch type {
    case .suggestion: "wand.and.stars"
    case .anomaly: "exclamationmark.triangle"
    case .trend: "chart.line.uptrend.xyaxis"
    case .reminder: "bell"
    }
}

nonisolated func insightSeverityColor(_ severity: CodalonSeverity, colorScheme: ColorScheme) -> Color {
    switch severity {
    case .info: SemanticColor.textSecondary(for: colorScheme)
    case .warning: SemanticColor.warning(for: colorScheme)
    case .error: SemanticColor.error(for: colorScheme)
    case .critical: SemanticColor.error(for: colorScheme)
    }
}

// MARK: - Preview

#Preview("InsightCenterView") {
    let projectID = UUID()
    InsightCenterView(
        viewModel: InsightViewModel(
            insightRepository: PreviewInsightRepository(projectID: projectID),
            ruleEngine: PreviewRuleEngine(),
            healthScoreService: PreviewHealthScoreService(),
            projectID: projectID
        )
    )
    .frame(width: 600, height: 500)
}
