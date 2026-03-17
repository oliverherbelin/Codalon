// Issue #22 — Top-level planning screen

import SwiftUI
import HelaiaDesign

// MARK: - PlanningScreen

struct PlanningScreen: View {

    // MARK: - State

    @State private var viewModel: PlanningViewModel
    @State private var viewMode: ViewMode = .list
    @State private var showMilestoneForm = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: PlanningViewModel) {
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
            await viewModel.loadMilestones()
        }
        .sheet(isPresented: $showMilestoneForm) {
            MilestoneFormView { milestone in
                await viewModel.createMilestone(milestone)
            }
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: Spacing._3) {
            Text("Planning")
                .helaiaFont(.title3)

            Spacer()

            PlanningSearchBar(query: $viewModel.searchQuery)

            PlanningFilterBar(
                statusFilter: $viewModel.statusFilter,
                priorityFilter: $viewModel.priorityFilter,
                sortMode: $viewModel.sortMode
            )

            HelaiaSegmentedPicker(
                selection: $viewMode,
                options: ViewMode.allCases.map {
                    HelaiaPickerOption(id: $0, label: $0.label, icon: $0.iconName)
                }
            )
            .frame(width: 220)

            HelaiaButton("New Milestone", icon: .sfSymbol("plus")) {
                showMilestoneForm = true
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
        } else if viewModel.filteredMilestones.isEmpty {
            HelaiaEmptyState(
                icon: "flag.fill",
                title: "No milestones yet",
                description: "Create your first milestone to start planning",
                actionTitle: "New Milestone"
            ) {
                showMilestoneForm = true
            }
        } else {
            switch viewMode {
            case .list:
                MilestoneListView(viewModel: viewModel)
            case .board:
                RoadmapBoardView(viewModel: viewModel)
            case .timeline:
                RoadmapTimelineView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - ViewMode

extension PlanningScreen {

    enum ViewMode: String, CaseIterable, Sendable {
        case list
        case board
        case timeline

        var label: String {
            switch self {
            case .list: "List"
            case .board: "Board"
            case .timeline: "Timeline"
            }
        }

        var iconName: String {
            switch self {
            case .list: "list.bullet"
            case .board: "rectangle.split.3x1"
            case .timeline: "chart.bar.xaxis"
            }
        }
    }
}

// MARK: - Preview

#Preview("PlanningScreen — Empty") {
    PlanningScreen(viewModel: .preview)
}
