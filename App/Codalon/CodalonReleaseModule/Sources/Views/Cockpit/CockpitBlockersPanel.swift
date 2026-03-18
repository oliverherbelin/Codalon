// Issue #159 — Blockers panel

import SwiftUI
import HelaiaDesign

// MARK: - CockpitBlockersPanel

struct CockpitBlockersPanel: View {

    let release: CodalonRelease
    let viewModel: ReleaseViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ReleaseCockpitPanel(
            title: "Blockers",
            icon: "xmark.octagon",
            badgeCount: activeBlockerCount
        ) {
            if release.blockers.isEmpty {
                Text("No blockers")
                    .helaiaFont(.subheadline)
                    .helaiaForeground(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing._3)
            } else {
                VStack(spacing: Spacing._2) {
                    ForEach(release.blockers) { blocker in
                        blockerRow(blocker)
                    }
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func blockerRow(_ blocker: CodalonReleaseBlocker) -> some View {
        HStack(spacing: Spacing._2) {
            HelaiaIconView(
                blocker.isResolved ? "checkmark.circle.fill" : "xmark.circle.fill",
                size: .sm,
                color: blocker.isResolved
                    ? SemanticColor.success(for: colorScheme)
                    : severityColor(blocker.severity)
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(blocker.title)
                    .helaiaFont(.subheadline)
                    .strikethrough(blocker.isResolved)
                if !blocker.source.isEmpty {
                    Text(blocker.source)
                        .helaiaFont(.caption1)
                        .foregroundStyle(SemanticColor.textTertiary(for: colorScheme))
                }
            }

            Spacer()

            if !blocker.isResolved {
                HelaiaButton.ghost("Resolve") {
                    Task { await viewModel.resolveBlocker(blocker.id) }
                }
                .fixedSize()
            }
        }
    }

    // MARK: - Helpers

    private var activeBlockerCount: Int {
        release.blockers.filter { !$0.isResolved }.count
    }

    private func severityColor(_ severity: CodalonSeverity) -> Color {
        switch severity {
        case .info: SemanticColor.info(for: colorScheme)
        case .warning: SemanticColor.warning(for: colorScheme)
        case .error, .critical: SemanticColor.error(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("CockpitBlockersPanel") {
    let vm = ReleaseViewModel(
        releaseService: PreviewReleaseService(),
        projectID: ReleasePreviewData.projectID
    )
    vm.selectedRelease = ReleasePreviewData.draftRelease

    return CockpitBlockersPanel(
        release: ReleasePreviewData.draftRelease,
        viewModel: vm
    )
    .padding()
    .frame(width: 400)
}
