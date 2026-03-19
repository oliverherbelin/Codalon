// Issue #242 — Preview share service for SwiftUI previews

import Foundation
import HelaiaShare

// MARK: - PreviewShareService

/// Preview-only share service that returns sample data.
actor PreviewShareService: CodalonShareServiceProtocol {

    func exportMarkdown(_ content: ShareableContent) async throws -> Data {
        let markdown = "# \(content.title)\n\n\(content.body)"
        return Data(markdown.utf8)
    }

    func exportPDF(_ content: ShareableContent) async throws -> Data {
        Data()
    }

    func availableFormats() async -> [String] {
        ["markdown", "pdf", "json", "html", "csv"]
    }

    func export(
        _ content: ShareableContent,
        as formatID: String
    ) async throws -> ExportResult {
        ExportResult(
            formatID: formatID,
            data: Data("preview".utf8),
            suggestedFilename: "preview.\(formatID)"
        )
    }
}
