// Issues #36, #66, #68 — Task screen

import SwiftUI
import HelaiaDesign

// MARK: - TaskScreen

struct TaskScreen: View {

    // MARK: - State

    @State private var viewModel: TaskViewModel
    @State private var viewMode: TaskViewMode = .list
    @State private var showTaskEditor = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    init(viewModel: TaskViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if viewModel.hasSelection {
                bulkActionBar
                Divider()
            }
            content
        }
        .task {
            await viewModel.loadTasks()
        }
        .sheet(isPresented: $showTaskEditor) {
            TaskEditorView { task in
                await viewModel.createTask(task)
            }
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: Spacing._3) {
            Text("Tasks")
                .helaiaFont(.title3)

            Spacer()

            HelaiaTextField(
                title: "",
                text: $viewModel.searchQuery,
                placeholder: "Search tasks…"
            )
            .frame(width: 200)

            TaskFilterBar(
                statusFilter: $viewModel.statusFilter,
                priorityFilter: $viewModel.priorityFilter,
                sortMode: $viewModel.sortMode
            )

            HelaiaSegmentedPicker(
                selection: $viewMode,
                options: TaskViewMode.allCases.map {
                    HelaiaPickerOption(id: $0, label: $0.label, icon: $0.iconName)
                }
            )
            .frame(width: 200)

            HelaiaButton("New Task", icon: .sfSymbol("plus")) {
                showTaskEditor = true
            }
            .fixedSize()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Bulk Action Bar (#66)

    @ViewBuilder
    private var bulkActionBar: some View {
        HStack(spacing: Spacing._3) {
            Text("\(viewModel.selectedTaskIDs.count) selected")
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            HelaiaButton.secondary("Mark Done") {
                Task { await viewModel.bulkChangeStatus(to: .done) }
            }
            .fixedSize()

            HelaiaButton.secondary("Set High Priority") {
                Task { await viewModel.bulkChangePriority(to: .high) }
            }
            .fixedSize()

            Spacer()

            HelaiaButton.ghost("Deselect All") {
                viewModel.deselectAll()
            }
            .fixedSize()
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._2)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch viewMode {
            case .list:
                TaskListView(viewModel: viewModel)
            case .board:
                TaskBoardView(viewModel: viewModel)
            case .timeline:
                TaskTimelineView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - TaskViewMode

enum TaskViewMode: String, CaseIterable, Sendable {
    case list
    case board
    case timeline

    nonisolated var label: String {
        switch self {
        case .list: "List"
        case .board: "Board"
        case .timeline: "Timeline"
        }
    }

    nonisolated var iconName: String {
        switch self {
        case .list: "list.bullet"
        case .board: "rectangle.split.3x1"
        case .timeline: "chart.bar.xaxis"
        }
    }
}

// MARK: - Preview

#Preview("TaskScreen") {
    TaskScreen(viewModel: .preview)
}