// Issue #296 — Stash popover: save, pop, drop, list

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct StashPopover: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    @State private var stashMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Stash")
                .helaiaFont(.headline)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                .padding(.horizontal, Spacing._3)
                .padding(.vertical, Spacing._2)

            Divider()

            // Save stash
            VStack(spacing: Spacing._1_5) {
                HelaiaTextField(
                    title: "",
                    text: $stashMessage,
                    placeholder: "Stash message (optional)"
                )

                HelaiaButton(
                    "Stash Changes",
                    icon: "archivebox",
                    variant: .secondary,
                    size: .small,
                    isLoading: viewModel.isStashing,
                    fullWidth: true
                ) {
                    Task {
                        await viewModel.stashSave(
                            message: stashMessage.isEmpty ? "WIP" : stashMessage
                        )
                        stashMessage = ""
                    }
                }
                .disabled(!viewModel.hasUnstagedChanges && !viewModel.hasStagedChanges)
            }
            .padding(Spacing._3)

            if !viewModel.stashes.isEmpty {
                Divider()

                // Stash list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.stashes, id: \.index) { stash in
                            stashRow(stash)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .frame(width: 280)
        .task { await viewModel.refreshStashes() }
    }

    @ViewBuilder
    private func stashRow(_ stash: GitStash) -> some View {
        HStack(spacing: Spacing._2) {
            VStack(alignment: .leading, spacing: Spacing._px) {
                Text("stash@{\(stash.index)}")
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                Text(stash.message)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer()

            HelaiaButton(
                "Pop",
                variant: .ghost,
                size: .small
            ) {
                Task { await viewModel.stashPop(index: stash.index) }
            }

            Button {
                Task { await viewModel.stashDrop(index: stash.index) }
            } label: {
                HelaiaIconView(
                    "trash",
                    size: .custom(10),
                    color: SemanticColor.error(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing._3)
        .padding(.vertical, Spacing._1_5)
    }
}

#Preview("StashPopover") {
    StashPopover(viewModel: LocalGitPanelViewModel())
        .environment(\.projectContext, .development)
}