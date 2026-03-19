// Issues #227-#234 — Codalon analytics service

import Foundation
import HelaiaAnalytics
import HelaiaLogger

/// Protocol for Codalon's analytics service.
public protocol CodalonAnalyticsServiceProtocol: Actor, Sendable {
    /// Records an analytics event.
    func track(_ event: AnalyticsEvent) async

    /// Returns an aggregated summary for a period.
    func summary(period: AnalyticsPeriod) async -> AnalyticsSummary

    /// Returns all recorded events.
    func allEvents() async -> [AnalyticsEvent]

    /// Clears all events.
    func clear() async
}

/// Codalon-specific analytics service that wraps HelaiaAnalytics.
/// Maintains its own session and provides convenience methods for tracking events.
public actor CodalonAnalyticsService: CodalonAnalyticsServiceProtocol {

    private let analyticsService: LocalAnalyticsService
    private let session: AnalyticsSession

    /// Current session ID, cached at init for synchronous access.
    public nonisolated let sessionID: UUID

    public init(
        storageURL: URL? = nil,
        logger: any HelaiaLoggerProtocol
    ) {
        let id = UUID()
        self.sessionID = id
        self.session = AnalyticsSession(sessionID: id)
        self.analyticsService = LocalAnalyticsService(
            storageURL: storageURL,
            logger: logger
        )
    }

    public func track(_ event: AnalyticsEvent) async {
        await analyticsService.record(event)
    }

    public func summary(period: AnalyticsPeriod) async -> AnalyticsSummary {
        await analyticsService.summary(period: period)
    }

    public func allEvents() async -> [AnalyticsEvent] {
        await analyticsService.allEvents()
    }

    public func clear() async {
        await analyticsService.clear()
    }

    /// Convenience method to track events using the current session ID.
    /// Use this for events that don't need a specific session context.
    public func track(
        name: String,
        category: AnalyticsCategory,
        properties: [String: String] = [:]
    ) async {
        let event = AnalyticsEvent(
            name: name,
            category: category,
            properties: properties,
            sessionID: sessionID
        )
        await track(event)
    }

    /// Tracks a screen view in the current session.
    public func trackScreen(_ name: String) async {
        await session.trackScreen(name)
        await track(
            name: "screen_view",
            category: .navigation,
            properties: ["screen": name]
        )
    }

    /// Ends the current session and returns a summary.
    public func endSession() async -> AnalyticsSessionSummary {
        await session.end()
    }
}