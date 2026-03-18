// Issue #72 — Decision log screen

import SwiftUI
import HelaiaDesign

// MARK: - DecisionLogScreen

struct DecisionLogScreen: View {

    // MARK: - State

    @State private var viewModel: DecisionLogViewModel
    @State private var showEntryForm = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: DecisionLogViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .task {
            await viewModel.loadEntries()
        }
        .sheet(isPresented: $showEntryForm) {
            DecisionLogEntryForm { entry in
                await viewModel.createEntry(entry)
            }
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: Spacing._3) {
            Text("Decision Log")
                .helaiaFont(.title3)

            Spacer()

            HelaiaTextField(
                title: "",
                text: $viewModel.searchQuery,
                placeholder: "Search decisions…"
            )
            .frame(width: 200)

            DecisionLogFilterBar(categoryFilter: $viewModel.categoryFilter)

            HelaiaButton("New Decision", icon: .sfSymbol("plus")) {
                showEntryForm = true
            }
            .fixedSize()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredEntries.isEmpty {
            HelaiaEmptyState(
                icon: "doc.text",
                title: "No decisions logged",
                description: "Record your first decision to build a traceable log",
                actionTitle: "New Decision"
            ) {
                showEntryForm = true
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing._3) {
                    ForEach(viewModel.filteredEntries) { entry in
                        DecisionLogEntryRow(
                            entry: entry,
                            onDelete: { Task { await viewModel.deleteEntry(id: entry.id) } }
                        )
                    }
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }
}

// MARK: - Preview

#Preview("DecisionLogScreen — Empty") {
    DecisionLogScreen(viewModel: DecisionLogViewModel(
        repository: PreviewDecisionLogRepository(),
        projectID: UUID()
    ))
}
