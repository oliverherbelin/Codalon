// Issues #139, #143, #146 — Alert view model tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Mock Repositories

private actor MockVMAlertRepo: AlertRepositoryProtocol {
    var alerts: [CodalonAlert] = []

    func save(_ alert: CodalonAlert) async throws {
        if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[index] = alert
        } else {
            alerts.append(alert)
        }
    }

    func load(id: UUID) async throws -> CodalonAlert {
        guard let alert = alerts.first(where: { $0.id == id }) else {
            throw VMTestError.notFound
        }
        return alert
    }

    func loadAll() async throws -> [CodalonAlert] { alerts }
    func delete(id: UUID) async throws { alerts.removeAll { $0.id == id } }

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID }
    }

    func fetchUnread(projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID && $0.readState == .unread }
    }

    func fetchByCategory(_ category: CodalonAlertCategory, projectID: UUID) async throws -> [CodalonAlert] {
        alerts.filter { $0.projectID == projectID && $0.category == category }
    }

    func markRead(id: UUID) async throws {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].readState = .read
        }
    }

    func dismiss(id: UUID) async throws {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].readState = .dismissed
        }
    }
}

private actor MockVMDismissalService: AlertDismissalServiceProtocol {
    func evaluateDismissals(projectID: UUID) async throws -> Int { 0 }
}

private enum VMTestError: Error { case notFound }

// MARK: - Tests

@Suite("AlertViewModelTests")
@MainActor
struct AlertViewModelTests {

    let projectID = UUID()

    private func makeRepo(alerts: [CodalonAlert]) async -> MockVMAlertRepo {
        let repo = MockVMAlertRepo()
        for alert in alerts {
            try? await repo.save(alert)
        }
        return repo
    }

    // MARK: - #139 — Load Alerts

    @Test("loads alerts from repository")
    func loadsAlerts() async throws {
        let repo = await makeRepo(alerts: [
            CodalonAlert(projectID: projectID, severity: .warning, category: .release, title: "A", message: "msg"),
            CodalonAlert(projectID: projectID, severity: .critical, category: .build, title: "B", message: "msg"),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        #expect(vm.alerts.count == 2)
    }

    // MARK: - #143 — Unread Count

    @Test("tracks unread count")
    func tracksUnreadCount() async throws {
        let repo = await makeRepo(alerts: [
            CodalonAlert(projectID: projectID, severity: .warning, category: .release, title: "A", message: "msg"),
            CodalonAlert(projectID: projectID, severity: .info, category: .general, title: "B", message: "msg", readState: .read),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        #expect(vm.unreadCount == 1)
    }

    @Test("marking read decrements unread count")
    func markReadDecrementsCount() async throws {
        let alert = CodalonAlert(projectID: projectID, severity: .warning, category: .release, title: "A", message: "msg")
        let repo = await makeRepo(alerts: [alert])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()
        #expect(vm.unreadCount == 1)

        await vm.markRead(id: alert.id)
        #expect(vm.unreadCount == 0)
    }

    // MARK: - #146 — Filters

    @Test("filters by severity")
    func filtersBySeverity() async throws {
        let repo = await makeRepo(alerts: [
            CodalonAlert(projectID: projectID, severity: .critical, category: .build, title: "A", message: "msg"),
            CodalonAlert(projectID: projectID, severity: .info, category: .general, title: "B", message: "msg"),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        vm.severityFilter = .critical
        #expect(vm.filteredAlerts.count == 1)
        #expect(vm.filteredAlerts[0].title == "A")
    }

    @Test("filters by category")
    func filtersByCategory() async throws {
        let repo = await makeRepo(alerts: [
            CodalonAlert(projectID: projectID, severity: .warning, category: .build, title: "Build", message: "msg"),
            CodalonAlert(projectID: projectID, severity: .warning, category: .release, title: "Release", message: "msg"),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        vm.categoryFilter = .build
        #expect(vm.filteredAlerts.count == 1)
        #expect(vm.filteredAlerts[0].title == "Build")
    }

    @Test("sorts by severity then date")
    func sortsBySeverityThenDate() async throws {
        let older = Date(timeIntervalSinceNow: -3600)
        let newer = Date()

        let repo = await makeRepo(alerts: [
            CodalonAlert(createdAt: newer, projectID: projectID, severity: .info, category: .general, title: "Info New", message: "msg"),
            CodalonAlert(createdAt: older, projectID: projectID, severity: .critical, category: .build, title: "Critical Old", message: "msg"),
            CodalonAlert(createdAt: newer, projectID: projectID, severity: .critical, category: .build, title: "Critical New", message: "msg"),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        let sorted = vm.filteredAlerts
        #expect(sorted[0].title == "Critical New")
        #expect(sorted[1].title == "Critical Old")
        #expect(sorted[2].title == "Info New")
    }

    @Test("clear filters resets all")
    func clearFiltersResetsAll() async throws {
        let repo = await makeRepo(alerts: [])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )

        vm.severityFilter = .critical
        vm.categoryFilter = .build
        vm.readStateFilter = .unread
        vm.searchQuery = "test"
        #expect(vm.hasActiveFilters)

        vm.clearFilters()
        #expect(!vm.hasActiveFilters)
    }

    // MARK: - #146 — Search

    @Test("search filters by title")
    func searchFiltersByTitle() async throws {
        let repo = await makeRepo(alerts: [
            CodalonAlert(projectID: projectID, severity: .warning, category: .build, title: "Build Failed", message: "CI error"),
            CodalonAlert(projectID: projectID, severity: .info, category: .review, title: "New Review", message: "4 stars"),
        ])

        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )
        await vm.loadAlerts()

        vm.searchQuery = "build"
        #expect(vm.filteredAlerts.count == 1)
        #expect(vm.filteredAlerts[0].title == "Build Failed")
    }

    // MARK: - #153 — Route

    @Test("parses alert route")
    func parsesAlertRoute() async throws {
        let releaseID = UUID()
        let alert = CodalonAlert(
            projectID: projectID,
            severity: .warning,
            category: .release,
            title: "Test",
            message: "msg",
            actionRoute: "release/\(projectID.uuidString)/\(releaseID.uuidString)"
        )

        let repo = await makeRepo(alerts: [alert])
        let vm = AlertViewModel(
            alertRepository: repo,
            dismissalService: MockVMDismissalService(),
            projectID: projectID
        )

        let route = vm.route(for: alert)
        #expect(route == .release(projectID: projectID, releaseID: releaseID))
    }
}
