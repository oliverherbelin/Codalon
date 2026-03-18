// Issue #161 — Checklist panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitChecklistPanel

struct CockpitChecklistPanel: View {

    let release: CodalonRelease
    let viewModel: ReleaseViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(
            title: "Checklist",
            icon: "checklist",
            badgeCount: incompleteCount > 0 ? incompleteCount : nil
        ) {
            if release.checklistItems.isEmpty {
                Text("No checklist items")
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing._3)
            } else {
                VStack(spacing: Spacing._2) {
                    // Progress bar
                    HStack(spacing: Spacing._2) {
                        HelaiaProgressBar(
                            value: completionRatio,
                            height: .thin
                        )
                        Text("\(completedCount)/\(release.checklistItems.count)")
                            .helaiaFont(.caption1)
                            .codalonMonospaced()
                            .helaiaForeground(.textSecondary)
                    }

                    ForEach(release.checklistItems, id: \.id) { item in
                        checklistRow(item)
                    }
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func checklistRow(_ item: CodalonChecklistItem) -> some View {
        HStack(spacing: Spacing._2) {
            Button {
                Task { await viewModel.toggleChecklistItem(item.id) }
            } label: {
                HelaiaIconView(
                    item.isComplete ? "checkmark.circle.fill" : "circle",
                    size: .sm,
                    color: item.isComplete
                        ? SemanticColor.success(for: colorScheme)
                        : SemanticColor.textTertiary(for: colorScheme)
                )
            }
            .buttonStyle(.plain)

            Text(item.title)
                .helaiaFont(.subheadline)
                .strikethrough(item.isComplete)
                .foregroundStyle(
                    item.isComplete
                        ? SemanticColor.textTertiary(for: colorScheme)
                        : SemanticColor.textPrimary(for: colorScheme)
                )

            Spacer()
        }
    }

    // MARK: - Computed

    private var completedCount: Int {
        release.checklistItems.filter(\.isComplete).count
    }

    private var incompleteCount: Int {
        release.checklistItems.count - completedCount
    }

    private var completionRatio: Double {
        guard !release.checklistItems.isEmpty else { return 0 }
        return Double(completedCount) / Double(release.checklistItems.count)
    }
}

// MARK: - Preview

#Preview("CockpitChecklistPanel") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.selectedRelease = ReleasePreviewData.draftRelease

    return CockpitChecklistPanel(
        release: ReleasePreviewData.draftRelease,
        viewModel: vm
    )
    .padding()
    .frame(width: 400)
}
