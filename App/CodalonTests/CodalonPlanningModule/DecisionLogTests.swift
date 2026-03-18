// Issue #72 — Decision log tests

import Foundation
import Testing
@testable import Codalon

// MARK: - Test Helpers

@MainActor private let projectID = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!

// MARK: - Mock Repository

private actor MockDecisionLogRepository: DecisionLogRepositoryProtocol {
    var stored: [UUID: CodalonDecisionLogEntry] = [:]

    func save(_ entry: CodalonDecisionLogEntry) async throws {
        stored[entry.id] = entry
    }

    func load(id: UUID) async throws -> CodalonDecisionLogEntry {
        guard let e = stored[id] else {
            throw NSError(domain: "test", code: 404)
        }
        return e
    }

    func loadAll() async throws -> [CodalonDecisionLogEntry] { Array(stored.values) }
    func delete(id: UUID) async throws { stored.removeValue(forKey: id) }

    func fetchByProject(_ projectID: UUID) async throws -> [CodalonDecisionLogEntry] {
        stored.values.filter { $0.projectID == projectID }
    }

    func fetchByCategory(
        _ category: CodalonDecisionCategory,
        projectID: UUID
    ) async throws -> [CodalonDecisionLogEntry] {
        stored.values.filter { $0.projectID == projectID && $0.category == category }
    }

    func fetchByRelatedObject(_ objectID: UUID) async throws -> [CodalonDecisionLogEntry] {
        stored.values.filter { $0.relatedObjectID == objectID }
    }
}

// MARK: - DecisionLogEntry Tests

@Suite("CodalonDecisionLogEntry")
@MainActor
struct DecisionLogEntryTests {

    @Test("round-trip encode/decode")
    func roundTrip() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let entry = CodalonDecisionLogEntry(
            projectID: projectID,
            category: .architecture,
            title: "Use actors",
            note: "Thread safety via Swift actors"
        )

        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(CodalonDecisionLogEntry.self, from: data)

        #expect(decoded.projectID == entry.projectID)
        #expect(decoded.category == .architecture)
        #expect(decoded.title == "Use actors")
    }

    @Test("default values")
    func defaults() {
        let entry = CodalonDecisionLogEntry(
            projectID: projectID,
            category: .scope,
            title: "Defer companion"
        )

        #expect(entry.note == "")
        #expect(entry.relatedObjectID == nil)
        #expect(entry.deletedAt == nil)
        #expect(entry.schemaVersion == 1)
    }
}

// MARK: - DecisionLogViewModel Tests

@Suite("DecisionLogViewModel")
@MainActor
struct DecisionLogViewModelTests {

    private func makeViewModel() -> DecisionLogViewModel {
        let vm = DecisionLogViewModel(
            repository: MockDecisionLogRepository(),
            projectID: projectID
        )
        vm.entries = CodalonDecisionLogEntry.previewList
        return vm
    }

    @Test("filters by category")
    func filterByCategory() {
        let vm = makeViewModel()
        vm.categoryFilter = .architecture
        let filtered = vm.filteredEntries
        #expect(filtered.allSatisfy { $0.category == .architecture })
    }

    @Test("search by title")
    func searchByTitle() {
        let vm = makeViewModel()
        vm.searchQuery = "actor"
        let filtered = vm.filteredEntries
        #expect(filtered.allSatisfy {
            $0.title.lowercased().contains("actor")
                || $0.note.lowercased().contains("actor")
        })
    }

    @Test("sorts by date descending")
    func sortsByDate() {
        let vm = makeViewModel()
        let filtered = vm.filteredEntries
        guard filtered.count >= 2 else { return }
        #expect(filtered.first!.createdAt >= filtered.last!.createdAt)
    }

    @Test("excludes soft-deleted entries")
    func excludeDeleted() {
        let vm = makeViewModel()
        var deleted = CodalonDecisionLogEntry(
            projectID: projectID,
            category: .other,
            title: "Deleted"
        )
        deleted.deletedAt = Date()
        vm.entries.append(deleted)
        let filtered = vm.filteredEntries
        #expect(!filtered.contains { $0.title == "Deleted" })
    }
}
