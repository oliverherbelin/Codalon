// Issue #164 — Linked GitHub issues panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitLinkedIssuesPanel

struct CockpitLinkedIssuesPanel: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(
            title: "Linked Issues",
            icon: "link",
            badgeCount: release.linkedGitHubIssueRefs.count > 0 ? release.linkedGitHubIssueRefs.count : nil
        ) {
            if release.linkedGitHubIssueRefs.isEmpty {
                Text("No GitHub issues linked")
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing._3)
            } else {
                VStack(spacing: Spacing._2) {
                    ForEach(release.linkedGitHubIssueRefs, id: \.self) { ref in
                        issueRow(ref)
                    }
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func issueRow(_ ref: String) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                "exclamationmark.circle",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )

            Text(ref)
                .helaiaFont(.subheadline)

            Spacer()

            HelaiaButton.ghost("Open") {
                openInGitHub(ref)
            }
            .fixedSize()
        }
    }

    // MARK: - Actions

    private func openInGitHub(_ ref: String) {
        // ref format: "owner/repo#123"
        let parts = ref.split(separator: "#")
        guard parts.count == 2,
              let issueNumber = parts.last,
              let repoPath = parts.first else { return }

        let urlString = "https://github.com/\(repoPath)/issues/\(issueNumber)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("CockpitLinkedIssuesPanel") {
    let release = CodalonRelease(
        projectID: UUID(),
        version: "1.0.0",
        linkedGitHubIssueRefs: ["oliverherbelin/Codalon#155", "oliverherbelin/Codalon#157"]
    )

    return CockpitLinkedIssuesPanel(release: release)
        .padding()
        .frame(width: 400)
}

#Preview("CockpitLinkedIssuesPanel — Empty") {
    CockpitLinkedIssuesPanel(release: ReleasePreviewData.draftRelease)
        .padding()
        .frame(width: 400)
}
