// Issue #237 — Export roadmap as Markdown

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaShare

// MARK: - RoadmapExportAction

struct RoadmapExportAction: View {

    let milestones: [CodalonMilestone]
    let tasks: [UUID: [CodalonTask]]
    let projectName: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HelaiaCard(variant: .outlined) {
            HStack(spacing: Spacing._3) {
                HelaiaIconView(
                    "square.and.arrow.up",
                    size: .md,
                    color: SemanticColor.textSecondary(for: colorScheme)
                )

                VStack(alignment: .leading, spacing: Spacing._1) {
                    Text("Export Roadmap")
                        .helaiaFont(.headline)
                    Text("Export milestones and tasks as Markdown")
                        .helaiaFont(.caption1)
                        .helaiaForeground(.textSecondary)
                }

                Spacer()

                HelaiaButton("Markdown", icon: .sfSymbol("arrow.down.doc")) {
                    exportMarkdown()
                }
                .fixedSize()

                HelaiaButton("PDF", icon: .sfSymbol("doc.richtext"), variant: .secondary) {
                    exportPDF()
                }
                .fixedSize()
            }
        }
    }

    // MARK: - Export

    private func exportMarkdown() {
        let content = CodalonExportFormatter.roadmapContent(
            milestones: milestones,
            tasks: tasks,
            projectName: projectName
        )
        let format = MarkdownExportFormat()

        Task {
            guard let data = try? await format.export(content),
                  let markdown = String(data: data, encoding: .utf8) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-roadmap.md"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func exportPDF() {
        let content = CodalonExportFormatter.roadmapContent(
            milestones: milestones,
            tasks: tasks,
            projectName: projectName
        )
        let format = PDFExportFormat()

        Task {
            guard let data = try? await format.export(content) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(projectName.lowercased().replacingOccurrences(of: " ", with: "-"))-roadmap.pdf"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - Preview

#Preview("RoadmapExportAction") {
    RoadmapExportAction(
        milestones: CodalonMilestone.previewList,
        tasks: [CodalonMilestone.previewActive.id: CodalonTask.previewList],
        projectName: "Codalon"
    )
    .padding()
    .frame(width: 500)
}
