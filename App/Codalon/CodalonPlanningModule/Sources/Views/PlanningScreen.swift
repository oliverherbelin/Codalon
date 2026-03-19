// Issue #22 — Top-level planning screen

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaShare

// MARK: - PlanningScreen

struct PlanningScreen: View {

    // MARK: - State

    @State private var viewModel: PlanningViewModel
    @State private var viewMode: ViewMode = .list
    @State private var showMilestoneForm = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    var projectName: String = "Project"

    init(viewModel: PlanningViewModel, projectName: String = "Project") {
        self._viewModel = State(initialValue: viewModel)
        self.projectName = projectName
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

            Menu {
                Button {
                    exportRoadmapMarkdown()
                } label: {
                    Label("Export as Markdown", systemImage: "arrow.down.doc")
                }
                Button {
                    exportRoadmapPDF()
                } label: {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(viewModel.filteredMilestones.isEmpty)

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

// MARK: - Export

extension PlanningScreen {

    private func exportRoadmapMarkdown() {
        let content = CodalonExportFormatter.roadmapContent(
            milestones: viewModel.filteredMilestones,
            tasks: viewModel.tasks,
            projectName: projectName
        )
        let format = MarkdownExportFormat()

        Task {
            guard let data = try? await format.export(content),
                  let markdown = String(data: data, encoding: .utf8) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-roadmap.md"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func exportRoadmapPDF() {
        let content = CodalonExportFormatter.roadmapContent(
            milestones: viewModel.filteredMilestones,
            tasks: viewModel.tasks,
            projectName: projectName
        )
        let format = PDFExportFormat()

        Task {
            guard let data = try? await format.export(content) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-roadmap.pdf"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? data.write(to: url, options: .atomic)
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
