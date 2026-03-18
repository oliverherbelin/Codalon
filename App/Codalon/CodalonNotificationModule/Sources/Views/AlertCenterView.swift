// Issue #139 — Alert center screen

import SwiftUI
import HelaiaDesign

// MARK: - AlertCenterView

struct AlertCenterView: View {

    // MARK: - State

    @State private var viewModel: AlertViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: AlertViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            header
            AlertFilterBar(viewModel: viewModel)
            alertList
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            await viewModel.loadAlerts()
            await viewModel.runAutoDismissals()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "bell.fill",
                size: .md,
                color: SemanticColor.textPrimary(for: colorScheme)
            )
            Text("Alert Center")
                .helaiaFont(.headline)
            if viewModel.unreadCount > 0 {
                MonitoringBadge.alerts(viewModel.unreadCount)
            }
            Spacer()
        }
    }

    // MARK: - Alert List

    @ViewBuilder
    private var alertList: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, Spacing._6)
        } else if viewModel.filteredAlerts.isEmpty {
            HelaiaEmptyState(
                icon: "bell.slash",
                title: viewModel.hasActiveFilters ? "No matching alerts" : "All clear",
                description: viewModel.hasActiveFilters
                    ? "Try adjusting your filters"
                    : "No alerts for this project"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.filteredAlerts, id: \.id) { alert in
                        AlertRowView(
                            alert: alert,
                            onMarkRead: {
                                Task { await viewModel.markRead(id: alert.id) }
                            },
                            onDismiss: {
                                Task { await viewModel.dismiss(id: alert.id) }
                            },
                            onNavigate: {
                                // Route navigation handled by parent
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - AlertRowView

struct AlertRowView: View {

    let alert: CodalonAlert
    let onMarkRead: () -> Void
    let onDismiss: () -> Void
    let onNavigate: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HelaiaCard(variant: alert.readState == .unread ? .outlined : .filled, padding: false) {
            HStack(spacing: CodalonSpacing.zoneGap) {
                severityBar
                content
                Spacer()
                actions
            }
            .padding(Spacing._3)
            .contentShape(Rectangle())
            .onTapGesture {
                if alert.readState == .unread {
                    onMarkRead()
                }
                if alert.actionRoute != nil {
                    onNavigate()
                }
            }
        }
        .opacity(alert.readState == .read ? 0.7 : 1.0)
    }

    @ViewBuilder
    private var severityBar: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(alert.severity.color(for: colorScheme))
            .frame(width: 4, height: 44)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            HStack(spacing: Spacing._1_5) {
                HelaiaIconView(
                    alert.severity.iconName,
                    size: .xs,
                    color: alert.severity.color(for: colorScheme)
                )
                Text(alert.title)
                    .helaiaFont(.buttonSmall)
                    .fontWeight(alert.readState == .unread ? .semibold : .regular)
                if alert.readState == .unread {
                    Circle()
                        .fill(SemanticColor.info(for: colorScheme))
                        .frame(width: 6, height: 6)
                }
            }
            Text(alert.message)
                .helaiaFont(.caption1)
                .helaiaForeground(.textSecondary)
                .lineLimit(2)
            HStack(spacing: Spacing._2) {
                Label(alert.category.displayName, systemImage: alert.category.iconName)
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
                Text(alert.createdAt.formatted(.relative(presentation: .named)))
                    .helaiaFont(.caption2)
                    .helaiaForeground(.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: Spacing._1) {
            if alert.readState == .unread {
                Button {
                    onMarkRead()
                } label: {
                    Image(systemName: "envelope.open")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Mark as read")
            }
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
    }
}

// MARK: - Preview

#Preview("AlertCenterView") {
    AlertCenterView(
        viewModel: AlertViewModel(
            alertRepository: PreviewAlertRepository(),
            dismissalService: PreviewAlertDismissalService(),
            projectID: UUID()
        )
    )
    .frame(width: 600, height: 500)
}
