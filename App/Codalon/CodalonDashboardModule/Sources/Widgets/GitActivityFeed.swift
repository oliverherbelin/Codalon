// Issue #125 — Git activity feed zone (Development Mode Canvas)

import SwiftUI
import HelaiaDesign

// MARK: - GitActivityFeed

struct GitActivityFeed: View {

    // MARK: - Properties

    let commits: [CommitRowData]
    let activeMilestoneTaskRefs: Set<String>
    let currentBranch: String
    var localUnstagedCount: Int = 0
    var localStagedCount: Int = 0
    var onOpenLocalPanel: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.projectContext) private var context

    // MARK: - Init

    init(
        commits: [CommitRowData] = [],
        activeMilestoneTaskRefs: Set<String> = [],
        currentBranch: String = "main",
        localUnstagedCount: Int = 0,
        localStagedCount: Int = 0,
        onOpenLocalPanel: (() -> Void)? = nil
    ) {
        self.commits = commits
        self.activeMilestoneTaskRefs = activeMilestoneTaskRefs
        self.currentBranch = currentBranch
        self.localUnstagedCount = localUnstagedCount
        self.localStagedCount = localStagedCount
        self.onOpenLocalPanel = onOpenLocalPanel
    }

    // MARK: - Body

    var body: some View {
        let tint = context.theme.color(for: colorScheme)

        HelaiaMaterial.ultraThin.apply(to:
            VStack(alignment: .leading, spacing: 0) {
                header(tint: tint)
                    .padding(.horizontal, CodalonSpacing.zoneGap)
                    .padding(.top, CodalonSpacing.zoneGap)
                    .padding(.bottom, Spacing._2)

                if commits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(commits) { commit in
                                commitRow(commit, tint: tint)
                            }
                        }
                    }
                }
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: CodalonRadius.zone)
                .stroke(Color.primary.opacity(0.06), lineWidth: BorderWidth.hairline)
        }
        .clipShape(RoundedRectangle(cornerRadius: CodalonRadius.zone))
    }

    // MARK: - Header

    @ViewBuilder
    private func header(tint: Color) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView("arrow.triangle.branch", size: .xs, color: tint)
            Text("GIT ACTIVITY")
                .helaiaFont(.tag)
                .tracking(0.5)
                .helaiaForeground(.textSecondary)
            Spacer()

            // Issue #280 — Local changes badge
            if let onOpen = onOpenLocalPanel {
                LocalChangesBadge(
                    unstagedCount: localUnstagedCount,
                    stagedCount: localStagedCount,
                    action: onOpen
                )
            }

            Button {
                onOpenLocalPanel?()
            } label: {
                Text(currentBranch)
                    .helaiaFont(.caption1)
                    .padding(.horizontal, Spacing._2)
                    .padding(.vertical, Spacing._1)
                    .background {
                        Capsule()
                            .fill(SemanticColor.surface(for: colorScheme))
                    }
            }
            .buttonStyle(.plain)
            .help("Open Git Panel")

            // Permanent panel trigger icon
            if onOpenLocalPanel != nil {
                Button {
                    onOpenLocalPanel?()
                } label: {
                    HelaiaIconView(
                        "sidebar.left",
                        size: .xs,
                        color: SemanticColor.textSecondary(for: colorScheme)
                    )
                }
                .buttonStyle(.plain)
                .help("Toggle Git Panel")
            }
        }
    }

    // MARK: - Commit Row

    @ViewBuilder
    private func commitRow(_ commit: CommitRowData, tint: Color) -> some View {
        let isMilestoneRelated = commit.relatedRefs.contains(where: {
            activeMilestoneTaskRefs.contains($0)
        })

        HStack(spacing: Spacing._3) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isMilestoneRelated ? tint : Color.clear)
                .frame(width: 3)

            Text(String(commit.hash.prefix(7)))
                .helaiaFont(.caption1)
                .codalonMonospaced()
                .helaiaForeground(.textSecondary)
                .frame(width: 56, alignment: .leading)

            Text(commit.message)
                .helaiaFont(.caption1)
                .lineLimit(1)

            Spacer()

            Text(commit.timeAgo)
                .helaiaFont(.caption2)
                .helaiaForeground(.textSecondary)
        }
        .frame(height: 32)
        .padding(.trailing, CodalonSpacing.zoneGap)
        .background {
            if isMilestoneRelated {
                RoundedRectangle(cornerRadius: CodalonRadius.row)
                    .fill(tint.opacity(0.05))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(commit.message), \(commit.timeAgo)")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Spacing._3) {
            HelaiaIconView(
                "arrow.triangle.branch",
                size: .xl,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
            Text("No git activity")
                .helaiaFont(.footnote)
                .helaiaForeground(.textSecondary)
            Text("Connect a repository in project settings")
                .helaiaFont(.caption1)
                .helaiaForeground(.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - CommitRowData

struct CommitRowData: Identifiable, Sendable, Equatable {
    let id: UUID
    let hash: String
    let message: String
    let timeAgo: String
    let relatedRefs: [String]

    init(
        id: UUID = UUID(),
        hash: String,
        message: String,
        timeAgo: String,
        relatedRefs: [String] = []
    ) {
        self.id = id
        self.hash = hash
        self.message = message
        self.timeAgo = timeAgo
        self.relatedRefs = relatedRefs
    }
}

// MARK: - Preview

#Preview("GitActivityFeed") {
    GitActivityFeed(
        commits: [
            CommitRowData(hash: "a1b2c3d", message: "Fix dashboard layout spacing", timeAgo: "2h", relatedRefs: ["#42"]),
            CommitRowData(hash: "e4f5g6h", message: "Add project health widget", timeAgo: "3h"),
            CommitRowData(hash: "i7j8k9l", message: "Refactor milestone service", timeAgo: "5h", relatedRefs: ["#42"]),
            CommitRowData(hash: "m0n1o2p", message: "Update HelaiaDesign tokens", timeAgo: "1d"),
            CommitRowData(hash: "q3r4s5t", message: "Initial commit", timeAgo: "3d")
        ],
        activeMilestoneTaskRefs: ["#42"],
        currentBranch: "feature/dashboard"
    )
    .frame(width: 350, height: 280)
    .padding()
    .environment(\.projectContext, .development)
}
