//
//  GroceryListFiltering.swift
//  GroceryList
//

import Foundation

/// Pure filtering and grouping. Marked `Sendable` with `nonisolated` entry points so work can be
/// offloaded (e.g. `Task.detached`) without crossing actors with mutable state.
enum GroceryListFiltering: Sendable {
    /// Case-insensitive prefix match on item display name. `searchText` is trimmed once by callers of `filter`.
    nonisolated static func matchesSearch(_ itemName: String, normalizedQuery: String) -> Bool {
        guard !normalizedQuery.isEmpty else { return true }
        return itemName.range(
            of: normalizedQuery,
            options: [.anchored, .caseInsensitive],
            range: nil,
            locale: .current
        ) != nil
    }

    nonisolated static func filter(
        items: [GroceryItem],
        searchText: String,
        category: GroceryCategory?
    ) -> [GroceryItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryFilter = category
        if categoryFilter == nil, q.isEmpty {
            return items
        }
        return items.filter { item in
            let categoryOK = categoryFilter.map { $0 == item.category } ?? true
            return categoryOK && matchesSearch(item.name, normalizedQuery: q)
        }
    }

    /// One-shot filter + group for background execution (e.g. `Task.detached`) on large snapshots.
    nonisolated static func filterAndGroup(
        items: [GroceryItem],
        searchText: String,
        category: GroceryCategory?
    ) -> [(GroceryCategory, [GroceryItem])] {
        let filtered = filter(items: items, searchText: searchText, category: category)
        return groupedByCategory(filtered)
    }

    /// Buckets items in a single pass, then sorts each bucket (O(n + k log k) per category, k ≤ n).
    nonisolated static func groupedByCategory(_ items: [GroceryItem]) -> [(GroceryCategory, [GroceryItem])] {
        var buckets: [GroceryCategory: [GroceryItem]] = [:]
        buckets.reserveCapacity(GroceryCategory.allCases.count)
        for item in items {
            buckets[item.category, default: []].append(item)
        }
        return GroceryCategory.allCases.compactMap { cat in
            guard var rows = buckets[cat], !rows.isEmpty else { return nil }
            rows.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return (cat, rows)
        }
    }
}
