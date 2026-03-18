// Issue #153 — Alert route parsing tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Tests

@Suite("AlertRouteTests")
@MainActor
struct AlertRouteTests {

    let projectID = UUID()
    let releaseID = UUID()
    let milestoneID = UUID()
    let insightID = UUID()

    // MARK: - #153 — Route Parsing

    @Test("parses release route")
    func parsesReleaseRoute() {
        let route = AlertRoute.parse("release/\(projectID.uuidString)/\(releaseID.uuidString)")
        #expect(route == .release(projectID: projectID, releaseID: releaseID))
    }

    @Test("parses milestone route")
    func parsesMilestoneRoute() {
        let route = AlertRoute.parse("milestone/\(projectID.uuidString)/\(milestoneID.uuidString)")
        #expect(route == .milestone(projectID: projectID, milestoneID: milestoneID))
    }

    @Test("parses build route")
    func parsesBuildRoute() {
        let route = AlertRoute.parse("build/\(projectID.uuidString)")
        #expect(route == .build(projectID: projectID))
    }

    @Test("parses appstore route")
    func parsesAppStoreRoute() {
        let route = AlertRoute.parse("appstore/\(projectID.uuidString)")
        #expect(route == .appStore(projectID: projectID))
    }

    @Test("parses insight route")
    func parsesInsightRoute() {
        let route = AlertRoute.parse("insight/\(projectID.uuidString)/\(insightID.uuidString)")
        #expect(route == .insight(projectID: projectID, insightID: insightID))
    }

    @Test("parses settings route")
    func parsesSettingsRoute() {
        let route = AlertRoute.parse("settings")
        #expect(route == .settings)
    }

    @Test("returns nil for nil input")
    func returnsNilForNil() {
        let route = AlertRoute.parse(nil)
        #expect(route == nil)
    }

    @Test("returns nil for empty string")
    func returnsNilForEmpty() {
        let route = AlertRoute.parse("")
        #expect(route == nil)
    }

    @Test("returns unknown for unrecognized route")
    func returnsUnknownForUnrecognized() {
        let route = AlertRoute.parse("foobar/123")
        #expect(route == .unknown("foobar/123"))
    }

    @Test("returns unknown for malformed release route")
    func returnUnknownForMalformedRelease() {
        let route = AlertRoute.parse("release/not-a-uuid/also-not")
        #expect(route == .unknown("release/not-a-uuid/also-not"))
    }

    // MARK: - Route String Round-trip

    @Test("round-trips release route")
    func roundTripsRelease() {
        let original = AlertRoute.release(projectID: projectID, releaseID: releaseID)
        let parsed = AlertRoute.parse(original.routeString)
        #expect(parsed == original)
    }

    @Test("round-trips settings route")
    func roundTripsSettings() {
        let original = AlertRoute.settings
        let parsed = AlertRoute.parse(original.routeString)
        #expect(parsed == original)
    }
}
