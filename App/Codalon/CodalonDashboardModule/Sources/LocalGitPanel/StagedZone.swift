// Issue #284 — STAGED zone with file list, Unstage All

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct StagedZone: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Zone header
            HStack(spacing: Spacing._1_5) {
                Text("STAGED")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                Text("\(viewModel.status.stagedFiles.count)")
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))

                Spacer()

                if !viewModel.status.stagedFiles.isEmpty {
                    Button("Unstage All") {
                        Task { await viewModel.unstageAll() }
                    }
                    .helaiaFont(.caption2)
                    .foregroundStyle(context.theme.color(for: colorScheme))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Staged, \(viewModel.status.stagedFiles.count) files")

            if viewModel.status.stagedFiles.isEmpty {
                emptyState
            } else {
                fileList
            }
        }
    }

    @ViewBuilder
    private var fileList: some View {
        ForEach(viewModel.status.stagedFiles, id: \.path) { file in
            FileChangeRow(
                filePath: file.path.path,
                changeType: file.status,
                isStaged: true,
                isExpanded: viewModel.expandedFilePath == file.path.path,
                diff: viewModel.fileDiffs[file.path.path],
                onToggleStage: {
                    // Unstage individual file — refresh will pick up changes
                    Task { await viewModel.refreshStatus() }
                },
                onToggleExpand: {
                    if viewModel.expandedFilePath == file.path.path {
                        viewModel.expandedFilePath = nil
                    } else {
                        viewModel.expandedFilePath = file.path.path
                        Task { await viewModel.loadDiff(for: file.path.path) }
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: Spacing._1) {
            HelaiaIconView(
                "tray",
                size: .xs,
                color: SemanticColor.textTertiary(for: colorScheme)
            )
            Text("Stage files to commit")
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing._4)
    }
}

#Preview("StagedZone") {
    StagedZone(viewModel: LocalGitPanelViewModel())
        .frame(width: 320)
        .environment(\.projectContext, .development)
}