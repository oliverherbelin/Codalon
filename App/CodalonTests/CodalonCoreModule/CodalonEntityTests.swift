// Issue #21 — Encode/decode round-trip tests for all entities

import Foundation
import HelaiaCore
import Testing
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let encoder: JSONEncoder = {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    return enc
}()

@MainActor private let decoder: JSONDecoder = {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return dec
}()

@MainActor private func roundTrip<T: HelaiaRecord & Equatable>(_ record: T) throws -> T {
    let data = try encoder.encode(record)
    return try decoder.decode(T.self, from: data)
}

@MainActor private let fixedDate = Date(timeIntervalSince1970: 1_710_000_000)
@MainActor private let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
@MainActor private let milestoneID = UUID(uuidString: "00000002-0002-0002-0002-000000000002")!
@MainActor private let epicID = UUID(uuidString: "00000003-0003-0003-0003-000000000003")!
@MainActor private let releaseID = UUID(uuidString: "00000004-0004-0004-0004-000000000004")!

// MARK: - CodalonProject Tests

@Suite("CodalonProject")
@MainActor
struct CodalonProjectTests {

    @Test("round-trip encode/decode")
    func roundTripProject() throws {
        let project = CodalonProject(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            name: "Codalon",
            slug: "codalon",
            icon: "hammer.fill",
            color: "#4A90D9",
            platform: .macOS,
            projectType: .app,
            activeReleaseID: releaseID,
            linkedGitHubRepos: ["oliverherbelin/Codalon"],
            linkedASCApp: "com.helaia.Codalon",
            healthScore: 85.5
        )

        let decoded = try roundTrip(project)
        #expect(decoded == project)
        #expect(decoded.name == "Codalon")
        #expect(decoded.platform == .macOS)
        #expect(decoded.linkedGitHubRepos == ["oliverherbelin/Codalon"])
        #expect(decoded.isDeleted == false)
    }

    @Test("soft delete sets isDeleted")
    func softDelete() {
        var project = CodalonProject(name: "Test", slug: "test")
        #expect(project.isDeleted == false)
        project.deletedAt = Date()
        #expect(project.isDeleted == true)
    }
}

// MARK: - CodalonMilestone Tests

@Suite("CodalonMilestone")
@MainActor
struct CodalonMilestoneTests {

    @Test("round-trip encode/decode")
    func roundTripMilestone() throws {
        let milestone = CodalonMilestone(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            title: "MVP",
            summary: "Minimum viable product",
            dueDate: fixedDate,
            status: .active,
            priority: .high,
            progress: 0.65
        )

        let decoded = try roundTrip(milestone)
        #expect(decoded == milestone)
        #expect(decoded.status == .active)
        #expect(decoded.progress == 0.65)
    }
}

// MARK: - CodalonEpic Tests

@Suite("CodalonEpic")
@MainActor
struct CodalonEpicTests {

    @Test("round-trip encode/decode")
    func roundTripEpic() throws {
        let epic = CodalonEpic(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            milestoneID: milestoneID,
            title: "Domain Model",
            summary: "All entity definitions",
            status: .active,
            priority: .high
        )

        let decoded = try roundTrip(epic)
        #expect(decoded == epic)
        #expect(decoded.milestoneID == milestoneID)
    }
}

// MARK: - CodalonTask Tests

@Suite("CodalonTask")
@MainActor
struct CodalonTaskTests {

    @Test("round-trip encode/decode")
    func roundTripTask() throws {
        let task = CodalonTask(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            milestoneID: milestoneID,
            epicID: epicID,
            title: "Define CodalonProject entity",
            summary: "Conforms to HelaiaRecord",
            status: .inProgress,
            priority: .high,
            estimate: 2.0,
            dueDate: fixedDate,
            isBlocked: false,
            isLaunchCritical: true,
            waitingExternal: false,
            githubIssueRef: "oliverherbelin/Codalon#12"
        )

        let decoded = try roundTrip(task)
        #expect(decoded == task)
        #expect(decoded.isLaunchCritical == true)
        #expect(decoded.githubIssueRef == "oliverherbelin/Codalon#12")
    }

    @Test("blocked and waiting flags")
    func flags() {
        let task = CodalonTask(
            projectID: projectID,
            title: "Blocked task",
            isBlocked: true,
            waitingExternal: true
        )
        #expect(task.isBlocked == true)
        #expect(task.waitingExternal == true)
    }
}

// MARK: - CodalonRelease Tests

@Suite("CodalonRelease")
@MainActor
struct CodalonReleaseTests {

    @Test("round-trip encode/decode")
    func roundTripRelease() throws {
        let checklist = [
            CodalonChecklistItem(title: "Code ready", isComplete: true),
            CodalonChecklistItem(title: "QA completed", isComplete: false)
        ]

        let release = CodalonRelease(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            version: "1.4.0",
            buildNumber: "42",
            targetDate: fixedDate,
            status: .testing,
            readinessScore: 0.75,
            checklistItems: checklist,
            blockerCount: 2,
            linkedMilestoneID: milestoneID,
            linkedASCBuildRef: "abc123"
        )

        let decoded = try roundTrip(release)
        #expect(decoded == release)
        #expect(decoded.checklistItems.count == 2)
        #expect(decoded.checklistItems[0].isComplete == true)
        #expect(decoded.version == "1.4.0")
    }
}

// MARK: - CodalonInsight Tests

@Suite("CodalonInsight")
@MainActor
struct CodalonInsightTests {

    @Test("round-trip encode/decode")
    func roundTripInsight() throws {
        let insight = CodalonInsight(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            type: .anomaly,
            severity: .warning,
            source: .analytics,
            title: "Crash rate spike",
            message: "Crash rate increased 40% in last 24h",
            actionRoute: "/launch/crashes"
        )

        let decoded = try roundTrip(insight)
        #expect(decoded == insight)
        #expect(decoded.type == .anomaly)
        #expect(decoded.source == .analytics)
    }
}

// MARK: - CodalonAlert Tests

@Suite("CodalonAlert")
@MainActor
struct CodalonAlertTests {

    @Test("round-trip encode/decode")
    func roundTripAlert() throws {
        let alert = CodalonAlert(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            severity: .critical,
            category: .crash,
            title: "Fatal crash in launch",
            message: "EXC_BAD_ACCESS in AppDelegate",
            readState: .unread,
            actionRoute: "/launch/crashes/detail",
            distributionTargets: [.appStore, .testFlight]
        )

        let decoded = try roundTrip(alert)
        #expect(decoded == alert)
        #expect(decoded.readState == .unread)
        #expect(decoded.distributionTargets.contains(.appStore))
        #expect(decoded.distributionTargets.contains(.testFlight))
    }

    @Test("read state transitions")
    func readStateTransitions() {
        var alert = CodalonAlert(
            projectID: projectID,
            severity: .info,
            category: .general,
            title: "Test",
            message: "Test"
        )
        #expect(alert.readState == .unread)
        alert.readState = .read
        #expect(alert.readState == .read)
        alert.readState = .dismissed
        #expect(alert.readState == .dismissed)
    }
}

// MARK: - CodalonDecisionLogEntry Tests

@Suite("CodalonDecisionLogEntry")
@MainActor
struct CodalonDecisionLogEntryTests {

    @Test("round-trip encode/decode")
    func roundTripDecision() throws {
        let entry = CodalonDecisionLogEntry(
            createdAt: fixedDate,
            updatedAt: fixedDate,
            projectID: projectID,
            relatedObjectID: releaseID,
            category: .architecture,
            title: "HelaiaStorage only",
            note: "No SwiftData, no CoreData"
        )

        let decoded = try roundTrip(entry)
        #expect(decoded == entry)
        #expect(decoded.category == .architecture)
        #expect(decoded.relatedObjectID == releaseID)
    }
}

// MARK: - Enum Tests

@Suite("Shared Enums")
@MainActor
struct CodalonEnumTests {

    @Test("priority ordering")
    func priorityComparable() {
        #expect(CodalonPriority.low < CodalonPriority.medium)
        #expect(CodalonPriority.medium < CodalonPriority.high)
        #expect(CodalonPriority.high < CodalonPriority.critical)
    }

    @Test("severity ordering")
    func severityComparable() {
        #expect(CodalonSeverity.info < CodalonSeverity.warning)
        #expect(CodalonSeverity.warning < CodalonSeverity.error)
        #expect(CodalonSeverity.error < CodalonSeverity.critical)
    }

    @Test("all enums are Codable round-trip")
    func enumCodableRoundTrip() throws {
        let platform = try roundTripEnum(CodalonPlatform.macOS)
        #expect(platform == .macOS)

        let projectType = try roundTripEnum(CodalonProjectType.app)
        #expect(projectType == .app)

        let taskStatus = try roundTripEnum(CodalonTaskStatus.inProgress)
        #expect(taskStatus == .inProgress)

        let milestoneStatus = try roundTripEnum(CodalonMilestoneStatus.active)
        #expect(milestoneStatus == .active)

        let epicStatus = try roundTripEnum(CodalonEpicStatus.completed)
        #expect(epicStatus == .completed)

        let releaseStatus = try roundTripEnum(CodalonReleaseStatus.submitted)
        #expect(releaseStatus == .submitted)

        let insightType = try roundTripEnum(CodalonInsightType.anomaly)
        #expect(insightType == .anomaly)

        let insightSource = try roundTripEnum(CodalonInsightSource.ruleEngine)
        #expect(insightSource == .ruleEngine)

        let alertCategory = try roundTripEnum(CodalonAlertCategory.crash)
        #expect(alertCategory == .crash)

        let alertReadState = try roundTripEnum(CodalonAlertReadState.read)
        #expect(alertReadState == .read)

        let decisionCategory = try roundTripEnum(CodalonDecisionCategory.architecture)
        #expect(decisionCategory == .architecture)
    }

    @Test("checklist item round-trip")
    func checklistItemRoundTrip() throws {
        let item = CodalonChecklistItem(title: "Screenshots", isComplete: true)
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(CodalonChecklistItem.self, from: data)
        #expect(decoded == item)
        #expect(decoded.isComplete == true)
    }
}

@MainActor private func roundTripEnum<T: Codable & Equatable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

// MARK: - Schema Version Tests

@Suite("Schema Version Defaults")
@MainActor
struct SchemaVersionTests {

    @Test("all entities default to schema version 1")
    func defaultSchemaVersion() {
        let project = CodalonProject(name: "Test", slug: "test")
        #expect(project.schemaVersion == 1)

        let milestone = CodalonMilestone(projectID: projectID, title: "Test")
        #expect(milestone.schemaVersion == 1)

        let epic = CodalonEpic(projectID: projectID, title: "Test")
        #expect(epic.schemaVersion == 1)

        let task = CodalonTask(projectID: projectID, title: "Test")
        #expect(task.schemaVersion == 1)

        let release = CodalonRelease(projectID: projectID, version: "1.0")
        #expect(release.schemaVersion == 1)

        let insight = CodalonInsight(
            projectID: projectID,
            type: .suggestion,
            source: .system,
            title: "Test",
            message: "Test"
        )
        #expect(insight.schemaVersion == 1)

        let alert = CodalonAlert(
            projectID: projectID,
            severity: .info,
            category: .general,
            title: "Test",
            message: "Test"
        )
        #expect(alert.schemaVersion == 1)

        let decision = CodalonDecisionLogEntry(
            projectID: projectID,
            category: .other,
            title: "Test"
        )
        #expect(decision.schemaVersion == 1)
    }
}
