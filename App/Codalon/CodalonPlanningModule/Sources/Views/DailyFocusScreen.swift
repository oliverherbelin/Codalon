// Issue #84 — Daily focus screen

import SwiftUI
import HelaiaDesign

// MARK: - DailyFocusScreen

struct DailyFocusScreen: View {

    // MARK: - State

    @State private var viewModel: DailyFocusViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(viewModel: DailyFocusViewModel) {
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
            await viewModel.loadTasks()
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: Spacing._3) {
            VStack(alignment: .leading, spacing: Spacing._0_5) {
                Text("Today")
                    .helaiaFont(.title3)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .helaiaFont(.caption1)
                    .helaiaForeground(.textSecondary)
            }

            Spacer()

            ReducedNoiseToggle(isEnabled: $viewModel.reducedNoiseEnabled)
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
        } else {
            ScrollView {
                VStack(spacing: CodalonSpacing.zoneGap) {
                    // Issue #86 — Top-3 priorities
                    TopPrioritiesCard(
                        tasks: viewModel.topPriorities,
                        onStatusChange: { id, status in
                            Task { await viewModel.changeStatus(taskID: id, to: status) }
                        }
                    )

                    HStack(alignment: .top, spacing: CodalonSpacing.zoneGap) {
                        // Issue #92 — Stuck items
                        StuckItemsSection(
                            tasks: viewModel.stuckTasks,
                            onUnblock: { id in
                                Task { await viewModel.setBlocked(taskID: id, isBlocked: false) }
                            }
                        )
                        .frame(maxWidth: .infinity)

                        // Issue #88 — Follow-up needed
                        FollowUpSection(
                            tasks: viewModel.followUpTasks,
                            onStatusChange: { id, status in
                                Task { await viewModel.changeStatus(taskID: id, to: status) }
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }

                    // Issue #90 — Waiting on third party
                    WaitingExternalSection(
                        tasks: viewModel.waitingExternalTasks,
                        onClearWaiting: { id in
                            Task { await viewModel.setWaitingExternal(taskID: id, waiting: false) }
                        }
                    )
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
    }
}

// MARK: - Preview

#Preview("DailyFocusScreen") {
    let vm = DailyFocusViewModel(
        taskService: PreviewTaskService(),
        projectID: UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
    )
    vm.tasks = CodalonTask.previewList

    return DailyFocusScreen(viewModel: vm)
        .frame(width: 900, height: 700)
        .environment(\.projectContext, .development)
}
