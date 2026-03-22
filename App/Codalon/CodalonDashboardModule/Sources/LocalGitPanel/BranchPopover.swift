// Issues #292, #293, #294 — Branch popover: list, checkout, create

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct BranchPopover: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showCreate = false
    @State private var newBranchName = ""
    @State private var branchError: String?
    @State private var pendingCheckoutBranch: String?
    @State private var showDirtyWarning = false

    private var localBranches: [String] {
        viewModel.branches
            .filter { !$0.isRemote }
            .map(\.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Branches")
                    .helaiaFont(.headline)
                    .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                Spacer()
                Button {
                    showCreate.toggle()
                } label: {
                    HelaiaIconView(
                        "plus",
                        size: .xs,
                        color: context.theme.color(for: colorScheme)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._2)

            Divider()

            // Create branch
            if showCreate {
                VStack(alignment: .leading, spacing: Spacing._1_5) {
                    HelaiaTextField(
                        title: "",
                        text: $newBranchName,
                        placeholder: "feature/my-branch"
                    )

                    if let error = branchError {
                        Text(error)
                            .helaiaFont(.caption2)
                            .foregroundStyle(SemanticColor.error(for: colorScheme))
                    }

                    HelaiaButton(
                        "Create & Checkout",
                        variant: .primary,
                        size: .small,
                        fullWidth: true
                    ) {
                        createBranch()
                    }
                    .disabled(newBranchName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(Spacing._3)

                Divider()
            }

            // Branch list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(localBranches, id: \.self) { branch in
                        branchRow(branch)
                    }
                }
            }
            .frame(maxHeight: 240)
        }
        .frame(width: 260)
        // Dirty working tree warning (#302)
        .alert(
            "Uncommitted Changes",
            isPresented: $showDirtyWarning,
            presenting: pendingCheckoutBranch
        ) { branch in
            Button("Checkout Anyway") {
                Task {
                    await viewModel.checkout(branch: branch)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {
                pendingCheckoutBranch = nil
            }
        } message: { _ in
            Text("You have uncommitted changes. They may be lost when switching branches.")
        }
    }

    @ViewBuilder
    private func branchRow(_ branch: String) -> some View {
        let isCurrent = branch == viewModel.currentBranch

        Button {
            guard !isCurrent else { return }
            // Dirty working tree check (#302)
            if viewModel.hasUnstagedChanges || viewModel.hasStagedChanges {
                pendingCheckoutBranch = branch
                showDirtyWarning = true
            } else {
                Task {
                    await viewModel.checkout(branch: branch)
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: Spacing._2) {
                Text(branch)
                    .helaiaFont(.subheadline)
                    .foregroundStyle(
                        isCurrent
                            ? context.theme.color(for: colorScheme)
                            : SemanticColor.textPrimary(for: colorScheme)
                    )

                Spacer()

                if isCurrent {
                    HelaiaIconView(
                        "checkmark",
                        size: .xs,
                        color: context.theme.color(for: colorScheme)
                    )
                }
            }
            .padding(.horizontal, Spacing._3)
            .padding(.vertical, Spacing._1_5)
            .background {
                if isCurrent {
                    context.theme.color(for: colorScheme).opacity(0.06)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
    }

    private func createBranch() {
        let name = newBranchName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        if name.contains(" ") || name.contains("..") {
            branchError = "Invalid branch name"
            return
        }

        Task {
            await viewModel.createBranch(name: name)
            dismiss()
        }
    }
}

#Preview("BranchPopover") {
    BranchPopover(viewModel: LocalGitPanelViewModel())
        .environment(\.projectContext, .development)
}