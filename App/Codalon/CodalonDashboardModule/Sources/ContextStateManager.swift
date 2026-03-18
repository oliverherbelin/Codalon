// Issue #188 — Context state manager

import Foundation
import HelaiaEngine

// MARK: - ContextStateManagerProtocol

public protocol ContextStateManagerProtocol: Sendable {
    func evaluate(input: ContextDetectionInput) async -> CodalonContext
    func currentContext() async -> CodalonContext
}

// MARK: - ContextChangedEvent

public struct ContextChangedEvent: HelaiaEvent {
    public let projectID: UUID
    public let previousContext: CodalonContext
    public let newContext: CodalonContext
    public let timestamp: Date

    public init(
        projectID: UUID,
        previousContext: CodalonContext,
        newContext: CodalonContext,
        timestamp: Date = .now
    ) {
        self.projectID = projectID
        self.previousContext = previousContext
        self.newContext = newContext
        self.timestamp = timestamp
    }
}

// MARK: - ContextStateManager

/// Actor-isolated state manager for the active project context.
/// Evaluates detection rules and broadcasts changes via EventBus.
public actor ContextStateManager: ContextStateManagerProtocol {

    // MARK: - State

    private var context: CodalonContext = .development
    private let projectID: UUID
    private let eventBus: EventBus

    // MARK: - Init

    public init(projectID: UUID, eventBus: EventBus) {
        self.projectID = projectID
        self.eventBus = eventBus
    }

    // MARK: - Evaluate

    /// Evaluate the detection rules and update context if changed.
    /// Returns the new (or unchanged) context.
    @discardableResult
    public func evaluate(input: ContextDetectionInput) async -> CodalonContext {
        let detected = detectContext(from: input)
        if detected != context {
            let previous = context
            context = detected
            await MainActor.run {
                eventBus.publish(ContextChangedEvent(
                    projectID: projectID,
                    previousContext: previous,
                    newContext: detected
                ))
            }
        }
        return context
    }

    /// Returns the current context without re-evaluating.
    public func currentContext() -> CodalonContext {
        context
    }

    /// Force-set context (for manual override via ContextSwitcher).
    public func setContext(_ newContext: CodalonContext) async {
        if newContext != context {
            let previous = context
            context = newContext
            await MainActor.run {
                eventBus.publish(ContextChangedEvent(
                    projectID: projectID,
                    previousContext: previous,
                    newContext: newContext
                ))
            }
        }
    }
}
