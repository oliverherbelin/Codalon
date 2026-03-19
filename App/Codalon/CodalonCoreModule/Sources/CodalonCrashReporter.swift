// Issue #256 — Local crash reporting via HelaiaLogger

import Foundation
import HelaiaLogger

// MARK: - CodalonCrashReporterProtocol

/// Protocol for Codalon's crash/error reporting service.
public protocol CodalonCrashReporterProtocol: Actor, Sendable {
    /// Records an error with optional context.
    func capture(_ error: Error, context: [String: String]?) async
    /// Records a message at a given severity level.
    func capture(message: String, level: HelaiaLogLevel) async
    /// Adds a breadcrumb for debugging context.
    func addBreadcrumb(_ message: String, category: String) async
    /// Returns URLs of available log files.
    func logFileURLs() async -> [URL]
}

// MARK: - CodalonCrashReporter

/// Local-only crash reporter that logs to HelaiaLogger with a persistent file sink.
/// Implements HelaiaErrorReporterProtocol so it can be injected into HelaiaLogger itself.
public actor CodalonCrashReporter: CodalonCrashReporterProtocol, HelaiaErrorReporterProtocol {

    private let logger: any HelaiaLoggerProtocol
    private let fileSink: HelaiaLogFileSink

    public init(
        logDirectory: URL,
        maxFileSizeBytes: Int = 5_000_000,
        maxFiles: Int = 5
    ) {
        self.fileSink = HelaiaLogFileSink(
            directory: logDirectory,
            maxFileSizeBytes: maxFileSizeBytes,
            maxFiles: maxFiles
        )
        self.logger = HelaiaLogger(
            subsystem: "com.helaia.codalon",
            category: "CrashReporter",
            fileSink: fileSink
        )
    }

    // MARK: - CodalonCrashReporterProtocol

    public func capture(_ error: Error, context: [String: String]?) async {
        let contextString = context?.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") ?? ""
        let message = "[\(type(of: error))] \(error.localizedDescription)"
            + (contextString.isEmpty ? "" : " | \(contextString)")
        logger.error(message, category: "crash")

        let event = HelaiaLogEvent.error(
            message,
            subsystem: .app,
            category: .lifecycle,
            metadata: context ?? [:]
        )
        await fileSink.write(event: event)
    }

    public func capture(message: String, level: HelaiaLogLevel) async {
        logger.log(message, level: level, category: "crash")

        let event = HelaiaLogEvent(
            level: level,
            subsystem: .app,
            category: .lifecycle,
            message: message
        )
        await fileSink.write(event: event)
    }

    public func addBreadcrumb(_ message: String, category: String) async {
        logger.log("[\(category)] \(message)", level: .debug, category: "breadcrumb")

        let event = HelaiaLogEvent.debug(
            "[\(category)] \(message)",
            subsystem: .app,
            category: .lifecycle,
            metadata: ["breadcrumb_category": category]
        )
        await fileSink.write(event: event)
    }

    public func logFileURLs() async -> [URL] {
        await fileSink.allLogURLs()
    }

    // MARK: - HelaiaErrorReporterProtocol

    nonisolated public func captureError(_ error: Error, context: [String: String]?) {
        Task { await capture(error, context: context) }
    }

    nonisolated public func captureMessage(_ message: String, level: HelaiaLogLevel) {
        Task { await capture(message: message, level: level) }
    }

    nonisolated public func addBreadcrumb(_ message: String, category: String, level: HelaiaLogLevel) {
        Task { await self.addBreadcrumb(message, category: category) }
    }
}
