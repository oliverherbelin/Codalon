// Issue #297 — Tag popover: create, list, delete, push

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct TagPopover: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    @State private var newTagName = ""
    @State private var newTagMessage = ""
    @State private var showCreate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Tags")
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                Spacer()

                HelaiaIconButton(
                    icon: "arrow.up.circle",
                    variant: .ghost,
                    size: 24,
                    help: "Push tags"
                ) {
                    Task { await viewModel.pushTags() }
                }

                HelaiaIconButton(
                    icon: "plus",
                    variant: .ghost,
                    size: 24
                ) {
                    showCreate.toggle()
                }
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._2)

            Divider()

            // Create tag
            if showCreate {
                VStack(spacing: Spacing._1_5) {
                    HelaiaTextField(
                        title: "",
                        text: $newTagName,
                        placeholder: "v1.0.0"
                    )

                    HelaiaTextField(
                        title: "",
                        text: $newTagMessage,
                        placeholder: "Tag message (optional)"
                    )

                    HelaiaButton(
                        "Create Tag",
                        variant: .primary,
                        size: .small,
                        fullWidth: true
                    ) {
                        Task {
                            await viewModel.createTag(
                                name: newTagName,
                                message: newTagMessage.isEmpty ? nil : newTagMessage
                            )
                            newTagName = ""
                            newTagMessage = ""
                            showCreate = false
                        }
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(Spacing._3)

                Divider()
            }

            // Tag list
            if viewModel.tags.isEmpty {
                Text("No tags")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing._4)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.tags, id: \.name) { tag in
                            tagRow(tag)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .frame(width: 260)
    }

    @ViewBuilder
    private func tagRow(_ tag: GitTag) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "tag",
                size: .xs,
                color: SemanticColor.textSecondary(for: colorScheme)
            )

            VStack(alignment: .leading, spacing: Spacing._px) {
                Text(tag.name)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                if let message = tag.message {
                    Text(message)
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task { await viewModel.deleteTag(name: tag.name) }
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

#Preview("TagPopover") {
    TagPopover(viewModel: LocalGitPanelViewModel())
        .environment(\.projectContext, .development)
}