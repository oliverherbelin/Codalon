// Issue #72 — Decision log view model

import Foundation
import SwiftUI
import HelaiaEngine

// MARK: - DecisionLogViewModel

@Observable
final class DecisionLogViewModel {

    // MARK: - State

    var entries: [CodalonDecisionLogEntry] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery: String = ""
    var categoryFilter: CodalonDecisionCategory?

    // MARK: - Dependencies

    private let repository: any DecisionLogRepositoryProtocol
    private let projectID: UUID

    // MARK: - Init

    init(repository: any DecisionLogRepositoryProtocol, projectID: UUID) {
        self.repository = repository
        self.projectID = projectID
    }

    // MARK: - Load

    func loadEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await repository.fetchByProject(projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - CRUD

    func createEntry(_ entry: CodalonDecisionLogEntry) async {
        do {
            try await repository.save(entry)
            await loadEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEntry(_ entry: CodalonDecisionLogEntry) async {
        var updated = entry
        updated.updatedAt = Date()
        do {
            try await repository.save(updated)
            await loadEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEntry(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await loadEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered & Sorted

    var filteredEntries: [CodalonDecisionLogEntry] {
        var result = entries.filter { $0.deletedAt == nil }

        if let categoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                    || $0.note.lowercased().contains(query)
            }
        }

        result.sort { $0.createdAt > $1.createdAt }
        return result
    }
}
