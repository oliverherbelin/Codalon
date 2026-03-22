// Issues #288, #289, #290 — Commit composer footer with 4 states

import SwiftUI
import HelaiaDesign
import HelaiaGit

struct CommitComposer: View {

    let viewModel: LocalGitPanelViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    @State private var showPushAfterCommit = false
    @State private var showIssuePicker = false
    @State private var issueSearchText = ""

    private var state: ComposerState {
        if viewModel.isCommitting { return .committing }
        if !viewModel.hasStagedChanges { return .dormant }
        if viewModel.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty {
            return .activeNoMessage
        }
        return .activeWithMessage
    }

    private enum ComposerState {
        case dormant, activeNoMessage, activeWithMessage, committing
    }

    var body: some View {
        VStack(spacing: Spacing._2) {
            // Commit message
            TextEditor(text: Binding(
                get: { viewModel.commitMessage },
                set: { viewModel.commitMessage = $0 }
            ))
            .helaiaFont(.caption1)
            .frame(height: 52)
            .scrollContentBackground(.hidden)
            .background(SemanticColor.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(
                        SemanticColor.border(for: colorScheme),
                        lineWidth: BorderWidth.thin
                    )
            }
            .overlay(alignment: .topLeading) {
                if viewModel.commitMessage.isEmpty {
                    Text("Commit message…")
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                        .padding(.horizontal, Spacing._1)
                        .padding(.vertical, Spacing._1)
                        .allowsHitTesting(false)
                }
            }
            .disabled(state == .dormant)
            .opacity(state == .dormant ? 0.5 : 1)
            .overlay(alignment: .bottomTrailing) {
                if viewModel.hasAIProvider {
                    Button {
                        Task { await viewModel.generateCommitMessage() }
                    } label: {
                        if viewModel.isGeneratingCommitMessage {
                            ProgressView()
                                .controlSize(.mini)
                                .frame(width: 20, height: 20)
                        } else {
                            HelaiaIconView(
                                "sparkles",
                                size: .custom(12),
                                color: context.theme.color(for: colorScheme)
                            )
                            .frame(width: 20, height: 20)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(state == .dormant || viewModel.isGeneratingCommitMessage)
                    .opacity(state == .dormant ? 0.5 : 1)
                    .padding(Spacing._1)
                }
            }

            // AI error
            if let aiError = viewModel.aiCommitError {
                Text(aiError)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
                    .lineLimit(2)
            }

            // Issue linking
            if viewModel.hasLinkedRepo {
                HStack(spacing: Spacing._1) {
                    HelaiaButton(
                        "Link issue",
                        icon: "link",
                        variant: .ghost,
                        size: .small
                    ) {
                        showIssuePicker.toggle()
                        if showIssuePicker && viewModel.linkableIssues.isEmpty {
                            Task { await viewModel.fetchLinkableIssues() }
                        }
                    }
                    .disabled(state == .dormant)
                    .popover(isPresented: $showIssuePicker, arrowEdge: .top) {
                        issuePickerContent
                    }

                    Spacer()
                }
            }

            // Error
            if let error = viewModel.commitError {
                Text(error)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
                    .lineLimit(2)
            }

            // Action buttons
            HStack(spacing: Spacing._2) {
                // Commit button
                HelaiaButton(
                    viewModel.isCommitting ? "Committing…" : "Commit",
                    icon: "checkmark.circle",
                    variant: .primary,
                    size: .small,
                    isLoading: viewModel.isCommitting,
                    fullWidth: true
                ) {
                    if showPushAfterCommit {
                        Task { await viewModel.commitAndPush() }
                    } else {
                        Task { await viewModel.commit() }
                    }
                }
                .disabled(!viewModel.canCommit || viewModel.hasConflict)

                // Push toggle
                HelaiaMenuButton(
                    "",
                    variant: .ghost,
                    size: .small,
                    fullWidth: false,
                    actions: commitMenuActions
                )
            }

            // Push status
            if viewModel.isPushing {
                HStack(spacing: Spacing._1) {
                    ProgressView().controlSize(.mini)
                    Text("Pushing…")
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }
            } else if viewModel.aheadCount > 0 {
                HStack(spacing: Spacing._1) {
                    HelaiaIconView(
                        "arrow.up",
                        size: .custom(10),
                        color: context.theme.color(for: colorScheme)
                    )
                    Text("\(viewModel.aheadCount) commit\(viewModel.aheadCount == 1 ? "" : "s") ahead")
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }
            }

            if let error = viewModel.pushError {
                Text(error)
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .padding(Spacing._3)
    }

    // MARK: - Commit Menu Actions

    private var canPush: Bool {
        viewModel.aheadCount > 0 && !viewModel.isPushing
    }

    private var canCommitAndPush: Bool {
        viewModel.canCommit && !viewModel.isPushing
    }

    private var commitMenuActions: [HelaiaMenuAction] {
        [
            HelaiaMenuAction("Commit", icon: "checkmark.circle") {
                showPushAfterCommit = false
                Task { await viewModel.commit() }
            },
            HelaiaMenuAction("Commit & Push", icon: "arrow.up.circle") {
                showPushAfterCommit = true
                Task { await viewModel.commitAndPush() }
            },
            HelaiaMenuAction("Push", icon: "arrow.up") {
                Task { await viewModel.push() }
            }
        ]
    }

    // MARK: - Issue Picker

    private var filteredIssues: [LinkableIssue] {
        if issueSearchText.isEmpty { return viewModel.linkableIssues }
        let query = issueSearchText.lowercased()
        return viewModel.linkableIssues.filter {
            $0.title.lowercased().contains(query)
                || String($0.number).contains(query)
        }
    }

    private var issuePickerContent: some View {
        VStack(spacing: 0) {
            // Search field
            HelaiaTextField(
                title: "",
                text: $issueSearchText,
                placeholder: "Search issues…"
            )
            .padding(.horizontal, Spacing._2)
            .padding(.vertical, Spacing._1)

            Divider()

            // Issue list
            if viewModel.isLoadingIssues {
                HStack(spacing: Spacing._1) {
                    ProgressView().controlSize(.mini)
                    Text("Loading issues…")
                        .helaiaFont(.caption2)
                        .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                }
                .padding(Spacing._3)
            } else if filteredIssues.isEmpty {
                Text(issueSearchText.isEmpty ? "No open issues" : "No matches")
                    .helaiaFont(.caption2)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                    .padding(Spacing._3)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredIssues) { issue in
                            issueRow(issue)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .frame(width: 280)
    }

    // MARK: - Issue Row

    @ViewBuilder
    private func issueRow(_ issue: LinkableIssue) -> some View {
        HStack(spacing: Spacing._2) {
            Circle()
                .fill(issue.isOpen
                    ? SemanticColor.success(for: colorScheme)
                    : SemanticColor.textTertiary(for: colorScheme))
                .frame(width: 8, height: 8)

            Text("#\(issue.number)")
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))

            Text(issue.title)
                .helaiaFont(.caption2)
                .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                .lineLimit(1)
                .layoutPriority(-1)

            Spacer(minLength: Spacing._1)

            // Link pill
            HelaiaButton(
                "Link",
                variant: .ghost,
                size: .small
            ) {
                viewModel.appendIssueReference(issue.number)
                showIssuePicker = false
                issueSearchText = ""
            }

            // Close pill
            HelaiaButton(
                "Close",
                variant: .ghost,
                size: .small
            ) {
                viewModel.appendIssueClose(issue.number)
                showIssuePicker = false
                issueSearchText = ""
            }
        }
        .padding(.horizontal, Spacing._2)
        .padding(.vertical, Spacing._1)
    }
}

#Preview("CommitComposer — Dormant") {
    CommitComposer(viewModel: LocalGitPanelViewModel())
        .frame(width: 320)
        .environment(\.projectContext, .development)
}
