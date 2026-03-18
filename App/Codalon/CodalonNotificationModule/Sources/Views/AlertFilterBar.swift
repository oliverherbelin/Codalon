// Issue #146 — Alert filter bar

import SwiftUI
import HelaiaDesign

// MARK: - AlertFilterBar

struct AlertFilterBar: View {

    @Bindable var viewModel: AlertViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing._2) {
            severityPicker
            categoryPicker
            readStatePicker
            Spacer()
            if viewModel.hasActiveFilters {
                HelaiaButton.ghost("Clear Filters") {
                    viewModel.clearFilters()
                }
            }
        }
    }

    // MARK: - Severity Filter

    @ViewBuilder
    private var severityPicker: some View {
        Menu {
            Button("All Severities") {
                viewModel.severityFilter = nil
            }
            Divider()
            ForEach(CodalonSeverity.allCases, id: \.self) { severity in
                Button {
                    viewModel.severityFilter = severity
                } label: {
                    Label(severity.displayName, systemImage: severity.iconName)
                }
            }
        } label: {
            filterLabel(
                icon: "exclamationmark.triangle",
                text: viewModel.severityFilter?.displayName ?? "Severity"
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Category Filter

    @ViewBuilder
    private var categoryPicker: some View {
        Menu {
            Button("All Categories") {
                viewModel.categoryFilter = nil
            }
            Divider()
            ForEach(CodalonAlertCategory.allCases, id: \.self) { category in
                Button {
                    viewModel.categoryFilter = category
                } label: {
                    Label(category.displayName, systemImage: category.iconName)
                }
            }
        } label: {
            filterLabel(
                icon: "tag",
                text: viewModel.categoryFilter?.displayName ?? "Category"
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Read State Filter

    @ViewBuilder
    private var readStatePicker: some View {
        Menu {
            Button("All States") {
                viewModel.readStateFilter = nil
            }
            Divider()
            ForEach(CodalonAlertReadState.allCases, id: \.self) { state in
                Button(state.displayName) {
                    viewModel.readStateFilter = state
                }
            }
        } label: {
            filterLabel(
                icon: "line.3.horizontal.decrease.circle",
                text: viewModel.readStateFilter?.displayName ?? "Status"
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Helper

    @ViewBuilder
    private func filterLabel(icon: String, text: String) -> some View {
        HStack(spacing: Spacing._1) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .helaiaFont(.caption1)
        }
        .padding(.horizontal, Spacing._2)
        .padding(.vertical, Spacing._1)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(SemanticColor.surface(for: colorScheme))
        }
    }
}

// MARK: - Preview

#Preview("AlertFilterBar") {
    AlertFilterBar(
        viewModel: AlertViewModel(
            alertRepository: PreviewAlertRepository(),
            dismissalService: PreviewAlertDismissalService(),
            projectID: UUID()
        )
    )
    .padding()
    .frame(width: 600)
}
