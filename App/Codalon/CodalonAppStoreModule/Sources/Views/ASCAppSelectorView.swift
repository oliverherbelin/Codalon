// Issue #187 — ASC app selector

import SwiftUI
import HelaiaDesign

// MARK: - ASCAppSelectorView

struct ASCAppSelectorView: View {

    // MARK: - State

    @State private var viewModel: ASCViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: ASCViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            header
            searchBar
            appsList
        }
        .padding(CodalonSpacing.cardPadding)
        .task {
            if viewModel.apps.isEmpty {
                await viewModel.loadApps()
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing._1) {
            Text("Select App")
                .helaiaFont(.title3)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))

            Text("Choose which App Store Connect app to link to this project.")
                .helaiaFont(.body)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
        }
    }

    // MARK: - Search

    @ViewBuilder
    private var searchBar: some View {
        HelaiaTextField(
            title: "",
            text: $viewModel.searchQuery,
            placeholder: "Search apps..."
        )
    }

    // MARK: - Apps List

    @ViewBuilder
    private var appsList: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 100)
        } else if viewModel.filteredApps.isEmpty {
            HelaiaEmptyState(
                icon: "app.dashed",
                title: "No apps found",
                description: viewModel.searchQuery.isEmpty
                    ? "No apps available in this App Store Connect account"
                    : "No apps matching your search"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._2) {
                    ForEach(viewModel.filteredApps) { app in
                        appRow(app)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }

    // MARK: - App Row

    @ViewBuilder
    private func appRow(_ app: ASCApp) -> some View {
        let linked = viewModel.isAppLinked(app)

        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    platformIcon(app.platform),
                    size: .md,
                    color: linked
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._0_5) {
                    Text(app.name)
                        .helaiaFont(.headline)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    Text(app.bundleID)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                    Text(app.platform.displayName)
                        .helaiaFont(.tag)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }

                Spacer()

                if linked {
                    HStack(spacing: Spacing._2) {
                        HelaiaIconView(
                            "checkmark.circle.fill",
                            size: .sm,
                            color: SemanticColor.success(for: colorScheme)
                        )
                        Text("Linked")
                            .helaiaFont(.caption1)
                            .foregroundStyle(SemanticColor.success(for: colorScheme))
                    }
                } else {
                    HelaiaButton("Link", icon: .sfSymbol("link.badge.plus")) {
                        Task { await viewModel.linkApp(app) }
                    }
                    .fixedSize()
                }
            }
        }
    }

    private func platformIcon(_ platform: ASCPlatform) -> String {
        switch platform {
        case .iOS: "iphone"
        case .macOS: "laptopcomputer"
        case .tvOS: "appletv"
        case .visionOS: "visionpro"
        }
    }
}

// MARK: - Preview

#Preview("ASCAppSelectorView") {
    let vm = ASCViewModel(
        ascService: PreviewASCServiceConnected(),
        projectID: UUID()
    )
    vm.isAuthenticated = true
    vm.apps = [
        ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS),
        ASCApp(id: "2", name: "Kitchee", bundleID: "com.helaia.Kitchee", platform: .iOS),
        ASCApp(id: "3", name: "Helaia Companion", bundleID: "com.helaia.Companion", platform: .visionOS),
    ]
    vm.linkedApp = ASCApp(id: "1", name: "Codalon", bundleID: "com.helaia.Codalon", platform: .macOS)

    return ASCAppSelectorView(viewModel: vm)
        .frame(width: 500, height: 600)
}

#Preview("ASCAppSelectorView — Empty") {
    ASCAppSelectorView(viewModel: ASCViewModel(
        ascService: PreviewASCService(),
        projectID: UUID()
    ))
    .frame(width: 500, height: 300)
}
