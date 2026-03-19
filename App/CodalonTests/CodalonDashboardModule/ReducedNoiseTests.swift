// Issue #255 — Test reduced-noise mode

import Foundation
import Testing
@testable import Codalon

// MARK: - Reduced-Noise Mode Tests

@Suite("Reduced-Noise Mode")
@MainActor
struct ReducedNoiseTests {

    // MARK: - Development Context

    @Test("development context: essential widgets visible in reduced noise")
    func developmentEssentialVisible() {
        let essential = ReducedNoiseFilter.isVisible(
            widgetID: "milestoneFocus",
            context: .development,
            reducedNoise: true
        )
        #expect(essential == true)

        let gitActivity = ReducedNoiseFilter.isVisible(
            widgetID: "gitActivity",
            context: .development,
            reducedNoise: true
        )
        #expect(gitActivity == true)
    }

    @Test("development context: low-priority widgets hidden in reduced noise")
    func developmentLowPriorityHidden() {
        let alerts = ReducedNoiseFilter.isVisible(
            widgetID: "alerts",
            context: .development,
            reducedNoise: true
        )
        #expect(alerts == false)

        let insights = ReducedNoiseFilter.isVisible(
            widgetID: "insights",
            context: .development,
            reducedNoise: true
        )
        #expect(insights == false)
    }

    @Test("development context: standard widgets visible in reduced noise")
    func developmentStandardVisible() {
        let sprint = ReducedNoiseFilter.isVisible(
            widgetID: "sprintHorizon",
            context: .development,
            reducedNoise: true
        )
        #expect(sprint == true)
    }

    // MARK: - Release Context

    @Test("release context: readiness and blockers always visible")
    func releaseEssentialVisible() {
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "releaseReadiness", context: .release, reducedNoise: true
        ))
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "blockers", context: .release, reducedNoise: true
        ))
    }

    @Test("release context: insights hidden in reduced noise")
    func releaseInsightsHidden() {
        #expect(!ReducedNoiseFilter.isVisible(
            widgetID: "insights", context: .release, reducedNoise: true
        ))
    }

    // MARK: - Launch Context

    @Test("launch context: launch summary and crash rate always visible")
    func launchEssentialVisible() {
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "launchSummary", context: .launch, reducedNoise: true
        ))
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "crashRate", context: .launch, reducedNoise: true
        ))
    }

    // MARK: - Maintenance Context

    @Test("maintenance context: essential and standard widgets visible")
    func maintenanceVisibility() {
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "maintenanceSummary", context: .maintenance, reducedNoise: true
        ))
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "health", context: .maintenance, reducedNoise: true
        ))
        #expect(ReducedNoiseFilter.isVisible(
            widgetID: "insights", context: .maintenance, reducedNoise: true
        ))
    }

    @Test("maintenance context: attention hidden in reduced noise")
    func maintenanceAttentionHidden() {
        #expect(!ReducedNoiseFilter.isVisible(
            widgetID: "attention", context: .maintenance, reducedNoise: true
        ))
    }

    // MARK: - Noise Off

    @Test("all widgets visible when reduced noise is off")
    func allVisibleWhenNoiseOff() {
        let contexts: [CodalonContext] = [.development, .release, .launch, .maintenance]
        let widgetIDs = [
            "milestoneFocus", "gitActivity", "sprintHorizon",
            "attention", "alerts", "insights",
            "releaseReadiness", "blockers", "checklist",
            "launchSummary", "crashRate", "reviews",
            "maintenanceSummary", "health", "bugs",
        ]

        for context in contexts {
            for widgetID in widgetIDs {
                #expect(ReducedNoiseFilter.isVisible(
                    widgetID: widgetID,
                    context: context,
                    reducedNoise: false
                ))
            }
        }
    }

    // MARK: - Priority Ordering

    @Test("widget priority ordering is correct")
    func priorityOrdering() {
        #expect(WidgetPriority.lowPriority < .standard)
        #expect(WidgetPriority.standard < .essential)
        #expect(WidgetPriority.lowPriority < .essential)
    }

    @Test("unknown widget ID defaults to standard priority")
    func unknownWidgetDefaultsToStandard() {
        let priority = ReducedNoiseFilter.widgetPriority(
            "unknownWidget",
            context: .development
        )
        #expect(priority == .standard)
    }
}
