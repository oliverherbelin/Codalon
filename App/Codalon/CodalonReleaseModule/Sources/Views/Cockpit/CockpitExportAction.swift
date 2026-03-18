// Issue #175 — Export/share action

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaShare

// MARK: - CockpitExportAction

struct CockpitExportAction: View {

    let release: CodalonRelease

    @Environment(\.colorScheme) private var colorScheme
    @State private var showSavePanel = false

    var body: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    "square.and.arrow.up",
                    size: .md,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Export Release Summary")
                        .helaiaFont(.headline)
                    Text("Export checklist and readiness as Markdown")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                Spacer()

                HelaiaButton("Export", icon: .sfSymbol("arrow.down.doc")) {
                    exportMarkdown()
                }
                .fixedSize()
            }
        }
    }

    // MARK: - Export

    private func exportMarkdown() {
        let content = buildShareableContent()
        let format = MarkdownExportFormat()

        Task {
            guard let data = try? await format.export(content),
                  let markdown = String(data: data, encoding: .utf8) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "release-\(release.version)-summary.md"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func buildShareableContent() -> ShareableContent {
        var body = ""

        // Readiness
        body += "## Readiness Score\n\n"
        body += "**\(Int(release.readinessScore))%** — "
        body += release.readinessScore >= 80 ? "Ready" : (release.readinessScore >= 50 ? "In Progress" : "Not Ready")
        body += "\n\n"

        // Blockers
        if !release.blockers.isEmpty {
            body += "## Blockers\n\n"
            for blocker in release.blockers {
                let status = blocker.isResolved ? "[x]" : "[ ]"
                body += "- \(status) \(blocker.title) (\(blocker.severity.rawValue))\n"
            }
            body += "\n"
        }

        // Checklist
        if !release.checklistItems.isEmpty {
            body += "## Checklist\n\n"
            for item in release.checklistItems {
                let status = item.isComplete ? "[x]" : "[ ]"
                body += "- \(status) \(item.title)\n"
            }
            body += "\n"
        }

        // Linked issues
        if !release.linkedGitHubIssueRefs.isEmpty {
            body += "## Linked GitHub Issues\n\n"
            for ref in release.linkedGitHubIssueRefs {
                body += "- \(ref)\n"
            }
            body += "\n"
        }

        var metadata: [String: String] = [
            "version": release.version,
            "build": release.buildNumber,
            "status": release.status.rawValue,
            "readiness": "\(Int(release.readinessScore))%",
        ]
        if let target = release.targetDate {
            metadata["target_date"] = target.formatted(date: .abbreviated, time: .omitted)
        }

        return ShareableContent(
            title: "Release v\(release.version) Summary",
            body: body,
            metadata: metadata,
            entityType: "CodalonRelease",
            entityID: release.id
        )
    }
}

// MARK: - Preview

#Preview("CockpitExportAction") {
    CockpitExportAction(release: ReleasePreviewData.draftRelease)
        .padding()
        .frame(width: 500)
}
