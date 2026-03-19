// Issues #241, #242, #243 — Codalon share service wrapping HelaiaShare

import Foundation
import HelaiaShare
import HelaiaLogger

// MARK: - CodalonShareServiceProtocol

/// Protocol for Codalon's export and sharing service.
public protocol CodalonShareServiceProtocol: Actor, Sendable {
    /// Exports content as Markdown data.
    func exportMarkdown(_ content: ShareableContent) async throws -> Data

    /// Exports content as PDF data.
    func exportPDF(_ content: ShareableContent) async throws -> Data

    /// Returns all registered format IDs.
    func availableFormats() async -> [String]

    /// Exports content in a specific format.
    func export(_ content: ShareableContent, as formatID: String) async throws -> ExportResult
}

// MARK: - CodalonShareService

/// Codalon-specific share service that wraps HelaiaShare's ExportEngine.
public actor CodalonShareService: CodalonShareServiceProtocol {

    private let engine: ExportEngine

    public init(logger: any HelaiaLoggerProtocol) {
        self.engine = ExportEngine(logger: logger)
    }

    public func exportMarkdown(_ content: ShareableContent) async throws -> Data {
        let result = try await engine.export(content, as: "markdown")
        return result.data
    }

    public func exportPDF(_ content: ShareableContent) async throws -> Data {
        let result = try await engine.export(content, as: "pdf")
        return result.data
    }

    public func availableFormats() async -> [String] {
        await engine.registeredFormatIDs()
    }

    public func export(
        _ content: ShareableContent,
        as formatID: String
    ) async throws -> ExportResult {
        try await engine.export(content, as: formatID)
    }
}
