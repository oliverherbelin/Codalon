// Issue #96 — GitHub issue detail panel

import SwiftUI
import HelaiaDesign
import HelaiaGit

// MARK: - GitHubIssueDetailView

struct GitHubIssueDetailView: View {

    // MARK: - Properties

    let issue: GitIssue
    @State private var viewModel: GitHubViewModel

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(issue: GitIssue, viewModel: GitHubViewModel) {
        self.issue = issue
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: CodalonSpacing.zoneGap) {
                    statusSection
                    bodySection
                    metadataSection
                }
                .padding(CodalonSpacing.cardPadding)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: Spacing._3) {
            HelaiaIconView(
                issue.state == "open" ? "circle.fill" : "checkmark.circle.fill",
                size: .sm,
                color: issue.state == "open"
                    ? SemanticColor.success(for: colorScheme)
                    : SemanticColor.textTertiary(for: colorScheme)
            )

            VStack(alignment: .leading, spacing: Spacing._1) {
                Text(issue.title)
                    .helaiaFont(.title3)
                Text("#\(issue.number)")
                    .helaiaFont(.caption1)
                    .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
            }

            Spacer()

            Button { dismiss() } label: {
                HelaiaIconView(
                    "xmark.circle.fill",
                    size: .sm,
                    color: SemanticColor.textTertiary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing._8)
        .padding(.vertical, Spacing._3)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("STATUS")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                HelaiaSettingsRow(
                    title: "State",
                    icon: issue.state == "open" ? "circle.fill" : "checkmark.circle.fill",
                    iconColor: issue.state == "open"
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme),
                    variant: .value(issue.state.capitalized)
                )
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var bodySection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("DESCRIPTION")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                if let body = issue.body, !body.isEmpty {
                    Text(body)
                        .helaiaFont(.body)
                        .foregroundStyle(SemanticColor.textPrimary(for: colorScheme))
                        .textSelection(.enabled)
                } else {
                    Text("No description provided")
                        .helaiaFont(.footnote)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Metadata

    @ViewBuilder
    private var metadataSection: some View {
        HelaiaCard(variant: .elevated) {
            VStack(alignment: .leading, spacing: Spacing._3) {
                Text("DETAILS")
                    .helaiaFont(.tag)
                    .tracking(0.5)
                    .helaiaForeground(.textSecondary)

                HelaiaSettingsRow(
                    title: "Created",
                    icon: "calendar",
                    variant: .info(issue.createdAt.formatted(date: .abbreviated, time: .shortened))
                )

                HelaiaSettingsRow(
                    title: "Updated",
                    icon: "clock",
                    variant: .info(issue.updatedAt.formatted(date: .abbreviated, time: .shortened))
                )
            }
        }
    }
}

// MARK: - Preview

private func previewIssue(_ json: [String: Any]) -> GitIssue {
    let data = try! JSONSerialization.data(withJSONObject: json)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(GitIssue.self, from: data)
}

#Preview("GitHubIssueDetailView — Open") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    )

    let issue = previewIssue([
        "id": 1, "number": 42,
        "title": "Fix login flow on macOS 15",
        "body": "The login flow crashes when the user enters an invalid token.\n\nSteps to reproduce:\n1. Open settings\n2. Enter invalid token\n3. App crashes",
        "state": "open",
        "created_at": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 3)),
        "updated_at": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
    ])

    return GitHubIssueDetailView(issue: issue, viewModel: vm)
        .frame(width: 550, height: 500)
}

#Preview("GitHubIssueDetailView — Closed") {
    let vm = GitHubViewModel(
        gitHubService: PreviewGitHubService(),
        projectID: UUID()
    )

    let issue = previewIssue([
        "id": 2, "number": 41,
        "title": "Add dark mode support",
        "state": "closed",
        "created_at": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 10)),
        "updated_at": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 2))
    ])

    return GitHubIssueDetailView(issue: issue, viewModel: vm)
        .frame(width: 550, height: 400)
}
