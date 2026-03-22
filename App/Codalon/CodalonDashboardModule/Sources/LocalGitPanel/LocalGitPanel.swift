// Issues #281, #282 — Local Git Panel shell and header

import SwiftUI
import HelaiaDesign
import HelaiaEngine
import HelaiaGit

// MARK: - LocalGitPanel

struct LocalGitPanel: View {

    @Environment(CodalonShellState.self) private var shellState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = LocalGitPanelViewModel()
    @State private var showBranchPopover = false
    @State private var showStashPopover = false
    @State private var showTagPopover = false

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Spacer()
            } else if viewModel.repo == nil {
                noRepoState
            } else {
                panelContent
            }
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background {
            ZStack {
                HelaiaMaterial.regular.apply(to: Color.clear)
                context.theme.color(for: colorScheme).opacity(0.03)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(SemanticColor.border(for: colorScheme))
                .frame(width: BorderWidth.hairline)
        }
        .helaiaShadow(.xl, colorScheme: colorScheme)
        .task {
            if let projectID = shellState.selectedProjectID {
                await viewModel.load(projectID: projectID)
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .accessibilityLabel("Local Git Panel")
    }

    // MARK: - Header (#282)

    @ViewBuilder
    private var panelHeader: some View {
        HStack(spacing: Spacing._2) {
            // Branch pill
            Button {
                showBranchPopover = true
            } label: {
                HStack(spacing: Spacing._1) {
                    HelaiaIconView(
                        "arrow.triangle.branch",
                        size: .xs,
                        color: context.theme.color(for: colorScheme)
                    )
                    Text(viewModel.currentBranch)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                }
                .padding(.horizontal, Spacing._2)
                .padding(.vertical, Spacing._1)
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(SemanticColor.surface(for: colorScheme))
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showBranchPopover) {
                BranchPopover(viewModel: viewModel)
                    .environment(\.colorScheme, colorScheme)
            }

            Spacer()

            // Fetch indicator
            if viewModel.isFetching {
                ProgressView()
                    .controlSize(.mini)
            }

            // Pull button
            Button {
                Task { await viewModel.pull() }
            } label: {
                HelaiaIconView(
                    "arrow.down",
                    size: .xs,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPulling)
            .help("Pull")

            // More menu
            HelaiaMenuButton(
                "",
                icon: "ellipsis",
                variant: .ghost,
                size: .small,
                fullWidth: false,
                actions: moreMenuActions
            )
            .popover(isPresented: $showStashPopover) {
                StashPopover(viewModel: viewModel)
                    .environment(\.colorScheme, colorScheme)
            }
            .popover(isPresented: $showTagPopover) {
                TagPopover(viewModel: viewModel)
                    .environment(\.colorScheme, colorScheme)
            }

            // Close button
            Button {
                shellState.isLocalGitPanelVisible = false
            } label: {
                HelaiaIconView(
                    "xmark",
                    size: .xs,
                    weight: .semibold,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing._3)
        .padding(.vertical, Spacing._2)
    }

    // MARK: - More Menu Actions

    private var moreMenuActions: [HelaiaMenuAction] {
        var actions: [HelaiaMenuAction] = [
            HelaiaMenuAction("Stash…", icon: "archivebox") {
                showStashPopover = true
            },
            HelaiaMenuAction("Tags…", icon: "tag") {
                Task { await viewModel.refreshTags() }
                showTagPopover = true
            },
            HelaiaMenuAction("Rebase onto…", icon: "arrow.triangle.merge") {
                if let main = viewModel.branches.first(where: {
                    $0.name == "main" || $0.name == "master"
                }) {
                    Task { await viewModel.rebase(onto: main.name) }
                }
            }
        ]
        if viewModel.hasConflict {
            actions.append(
                HelaiaMenuAction("Abort Rebase", icon: "xmark.circle", role: .destructive) {
                    Task { await viewModel.abortRebase() }
                }
            )
        }
        return actions
    }

    // MARK: - Panel Content

    @ViewBuilder
    private var panelContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Working Tree Zone (#283)
                WorkingTreeZone(viewModel: viewModel)

                // Staged Zone (#284)
                StagedZone(viewModel: viewModel)
            }
        }

        // Conflict banner (#301)
        if viewModel.hasConflict {
            conflictBanner
        }

        // Error banner
        if let error = viewModel.generalError {
            errorBanner(error)
        }

        Divider()

        // Commit Composer (#288)
        CommitComposer(viewModel: viewModel)
    }

    // MARK: - No Repo

    @ViewBuilder
    private var noRepoState: some View {
        VStack(spacing: Spacing._3) {
            HelaiaIconView(
                "arrow.triangle.branch",
                size: .xl,
                color: SemanticColor.textTertiary(for: colorScheme)
            )
            Text("No local repository")
                .helaiaFont(.subheadline)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
            Text("Link a folder in project settings")
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Conflict Banner (#301)

    @ViewBuilder
    private var conflictBanner: some View {
        HStack(spacing: Spacing._1_5) {
            HelaiaIconView(
                "exclamationmark.triangle.fill",
                size: .xs,
                color: SemanticColor.error(for: colorScheme)
            )
            Text("Merge conflicts — resolve before committing")
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.error(for: colorScheme))
            Spacer()
        }
        .padding(.horizontal, Spacing._3)
        .padding(.vertical, Spacing._2)
        .background(SemanticColor.error(for: colorScheme).opacity(0.08))
    }

    // MARK: - Error Banner

    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing._1_5) {
            HelaiaIconView(
                "exclamationmark.circle.fill",
                size: .xs,
                color: SemanticColor.error(for: colorScheme)
            )
            Text(message)
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.error(for: colorScheme))
                .lineLimit(2)
            Spacer()
            Button {
                viewModel.generalError = nil
            } label: {
                HelaiaIconView(
                    "xmark",
                    size: .custom(8),
                    color: SemanticColor.textTertiary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing._3)
        .padding(.vertical, Spacing._1_5)
        .background(SemanticColor.error(for: colorScheme).opacity(0.05))
    }
}

// MARK: - Preview

#Preview("LocalGitPanel") {
    HStack(spacing: 0) {
        LocalGitPanel()
        Spacer()
    }
    .frame(width: 800, height: 600)
    .environment(CodalonShellState())
    .environment(\.projectContext, .development)
}

#Preview("LocalGitPanel — No Repo") {
    LocalGitPanel()
        .frame(width: 320, height: 600)
        .environment(CodalonShellState())
        .environment(\.projectContext, .development)
}