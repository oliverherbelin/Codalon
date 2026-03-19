// Issue #242 — Share button on dashboard

import SwiftUI
import UniformTypeIdentifiers
import HelaiaDesign
import HelaiaShare

// MARK: - DashboardShareButton

struct DashboardShareButton: View {

    let project: CodalonProject?
    let summary: ProjectSummary?
    let milestones: [CodalonMilestone]

    @Environment(\.colorScheme) private var colorScheme
    @State private var showShareOptions = false

    var body: some View {
        Menu {
            Button {
                exportMarkdown()
            } label: {
                Label("Export as Markdown", systemImage: "arrow.down.doc")
            }

            Button {
                exportPDF()
            } label: {
                Label("Export as PDF", systemImage: "doc.richtext")
            }
        } label: {
            HelaiaIconView(
                "square.and.arrow.up",
                size: .sm,
                color: SemanticColor.textSecondary(for: colorScheme)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(project == nil || summary == nil)
    }

    // MARK: - Export

    private func buildContent() -> ShareableContent? {
        guard let project, let summary else { return nil }
        return CodalonExportFormatter.projectSummaryContent(
            project: project,
            summary: summary,
            milestones: milestones
        )
    }

    private func exportMarkdown() {
        guard let content = buildContent() else { return }
        let format = MarkdownExportFormat()

        Task {
            guard let data = try? await format.export(content),
                  let markdown = String(data: data, encoding: .utf8) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(project?.slug ?? "project")-summary.md"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func exportPDF() {
        guard let content = buildContent() else { return }
        let format = PDFExportFormat()

        Task {
            guard let data = try? await format.export(content) else { return }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(project?.slug ?? "project")-summary.pdf"
            panel.canCreateDirectories = true

            let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
            if response == .OK, let url = panel.url {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - Preview

#Preview("DashboardShareButton") {
    DashboardShareButton(
        project: nil,
        summary: nil,
        milestones: []
    )
    .padding()
}
