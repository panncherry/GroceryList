//
//  IngredientListSearchModel.swift
//  GroceryList
//

import Foundation
import Observation

/// Owns full-list search UX: debounces text-driven recomputes and moves heavy filter/group work off the main thread for large snapshots.
@MainActor
@Observable
final class IngredientListSearchModel {
    /// Bound to the search field; recomputation uses the value after debounce (or immediately when cleared).
    var searchFieldText: String = ""

    var selectedCategory: GroceryCategory?

    private(set) var groupedSections: [(GroceryCategory, [GroceryItem])] = []

    /// Items currently visible after search + category filter (flattened).
    var visibleItemCount: Int {
        groupedSections.reduce(0) { $0 + $1.1.count }
    }

    /// True while a large-list filter is running on a background executor.
    private(set) var isFilteringLargeList: Bool = false

    /// Search text is being edited; next debounced recompute is pending.
    private(set) var isSearchDebouncePending: Bool = false

    let debounceNanoseconds: UInt64
    let heavyListThreshold: Int

    private var debounceTask: Task<Void, Never>?
    private var computeTask: Task<Void, Never>?
    private var recomputeGeneration: UInt64 = 0

    init(
        debounceNanoseconds: UInt64 = 220_000_000,
        heavyListThreshold: Int = 10_000
    ) {
        self.debounceNanoseconds = debounceNanoseconds
        self.heavyListThreshold = heavyListThreshold
    }

    /// Call when the user edits the search field.
    func onSearchFieldChanged(store: GroceryListStore) {
        let trimmed = searchFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
        debounceTask?.cancel()

        if trimmed.isEmpty {
            isSearchDebouncePending = false
            performRecompute(store: store)
            return
        }

        isSearchDebouncePending = true
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }
            isSearchDebouncePending = false
            performRecompute(store: store)
        }
    }

    /// Call when the category filter changes or store data changes — no debounce.
    func recomputeImmediately(store: GroceryListStore) {
        debounceTask?.cancel()
        isSearchDebouncePending = false
        performRecompute(store: store)
    }

    private func performRecompute(store: GroceryListStore) {
        computeTask?.cancel()
        recomputeGeneration &+= 1
        let generation = recomputeGeneration

        let snapshot = store.items
        let query = searchFieldText
        let category = selectedCategory

        if snapshot.count < heavyListThreshold {
            groupedSections = GroceryListFiltering.filterAndGroup(
                items: snapshot,
                searchText: query,
                category: category
            )
            isFilteringLargeList = false
            return
        }

        isFilteringLargeList = true
        computeTask = Task { @MainActor [snapshot, query, category, generation] in
            let result = await Task.detached(priority: .userInitiated) {
                GroceryListFiltering.filterAndGroup(
                    items: snapshot,
                    searchText: query,
                    category: category
                )
            }.value
            guard generation == recomputeGeneration else { return }
            groupedSections = result
            isFilteringLargeList = false
        }
    }
}
