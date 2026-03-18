// Issue #89 — Create GitHub issue from Codalon

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubCreateIssueView

struct GitHubCreateIssueView: View {

    // MARK: - State

    @State private var viewModel: GitHubViewModel
    @State private var titleInput = ""
    @State private var bodyInput = ""

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let owner: String
    let repo: String
    var prefillTitle: String?
    var prefillBody: String?

    // MARK: - Init

    init(
        viewModel: GitHubViewModel,
        owner: String,
        repo: String,
        prefillTitle: String? = nil,
        prefillBody: String? = nil
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.owner = owner
        self.repo = repo
        self.prefillTitle = prefillTitle
        self.prefillBody = prefillBody
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            form
        }
        .frame(minWidth: 500, minHeight: 350)
        .onAppear {
            if let prefillTitle { titleInput = prefillTitle }
            if let prefillBody { bodyInput = prefillBody }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                "plus.circle.fill",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("New Issue")
                .helaiaFont(.title3)

            Spacer()

            Text("\(owner)/\(repo)")
                .helaiaFont(.caption1)
                .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Form

    @ViewBuilder
    private var form: some View {
        VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
            HelaiaTextField(
                title: "Title",
                text: $titleInput,
                placeholder: "Issue title"
            )

            VStack(alignment: .leading, spacing: Spacing._2) {
                Text("Description")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textSecondary(for: colorScheme))
                TextEditor(text: $bodyInput)
                    .helaiaFont(.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing._2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(SemanticColor.background(for: colorScheme))
                    )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.error(for: colorScheme))
            }

            HStack(spacing: Spacing._3) {
                HelaiaButton("Create Issue", icon: .sfSymbol("plus")) {
                    Task {
                        let result = await viewModel.createIssue(
                            owner: owner,
                            repo: repo,
                            title: titleInput,
                            body: bodyInput.isEmpty ? nil : bodyInput
                        )
                        if result != nil { dismiss() }
                    }
                }
                .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isCreatingIssue)
                .fixedSize()

                if viewModel.isCreatingIssue {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()

                HelaiaButton.ghost("Cancel") { dismiss() }
                    .fixedSize()
            }
        }
        .padding(CodalonSpacing.cardPadding)
    }
}

// MARK: - Preview

#Preview("GitHubCreateIssueView") {
    GitHubCreateIssueView(
        viewModel: GitHubViewModel(
            gitHubService: PreviewGitHubService(),
            projectID: UUID()
        ),
        owner: "oliverherbelin",
        repo: "Codalon"
    )
    .frame(width: 550, height: 400)
}

#Preview("GitHubCreateIssueView — Prefilled") {
    GitHubCreateIssueView(
        viewModel: GitHubViewModel(
            gitHubService: PreviewGitHubService(),
            projectID: UUID()
        ),
        owner: "oliverherbelin",
        repo: "Codalon",
        prefillTitle: "Implement dashboard widget",
        prefillBody: "Created from CodalonTask: Build the main dashboard overview widget."
    )
    .frame(width: 550, height: 400)
}
