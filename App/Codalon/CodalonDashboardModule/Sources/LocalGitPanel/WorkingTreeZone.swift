// Issue #283 — WORKING TREE zone with file list, Stage All

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct WorkingTreeZone: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Zone header
            HStack(spacing: Spacing._1_5) {
                Text("WORKING TREE")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

                Text("\(fileCount)")
                    .helaiaFont(.tag)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))

                Spacer()

                if fileCount > 0 {
                    Button("Stage All") {
                        Task { await viewModel.stageAll() }
                    }
                    .helaiaFont(.caption2)
                    .foregroundStyle(context.theme.color(for: colorScheme))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Working tree, \(fileCount) files")

            if fileCount == 0 {
                emptyState
            } else {
                fileList
            }
        }
    }

    private var fileCount: Int {
        viewModel.status.unstagedFiles.count + viewModel.status.untrackedFiles.count
    }

    @ViewBuilder
    private var fileList: some View {
        ForEach(viewModel.status.unstagedFiles, id: \.path) { file in
            FileChangeRow(
                filePath: file.path.path,
                changeType: file.status,
                isStaged: false,
                isExpanded: viewModel.expandedFilePath == file.path.path,
                diff: viewModel.fileDiffs[file.path.path],
                onToggleStage: {
                    Task { await viewModel.stageFiles([file.path]) }
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

        ForEach(viewModel.status.untrackedFiles, id: \.self) { url in
            FileChangeRow(
                filePath: url.path,
                changeType: .added,
                isStaged: false,
                isExpanded: false,
                diff: nil,
                onToggleStage: {
                    Task { await viewModel.stageFiles([url]) }
                },
                onToggleExpand: {}
            )
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        Text("No changes")
            .helaiaFont(.caption1)
            .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing._4)
    }
}

#Preview("WorkingTreeZone") {
    WorkingTreeZone(viewModel: LocalGitPanelViewModel())
        .frame(width: 320)
        .environment(\.projectContext, .development)
}