//
//  GroceryListStore.swift
//  GroceryList
//

import Foundation
import Observation

/// Single source of truth for list data. All mutations happen on the main actor so SwiftUI reads are race-free.
@MainActor
@Observable
final class GroceryListStore {
    /// Newest-first for O(1) “recent” previews without sorting on every access.
    private(set) var items: [GroceryItem] = []

    private var normalizedKeys: Set<String> = []

    /// Memoizes category tallies until the next mutation (add/delete/clear).
    @ObservationIgnored private var cachedCategoryTallies: [GroceryCategory: Int]?

    /// Bumps on every successful load/mutation so list UIs can coalesce expensive work (debounced search, async filter).
    private(set) var dataRevision: UInt64 = 0

    init(items: [GroceryItem] = []) {
        self.items = items.sorted { $0.createdAt > $1.createdAt }
        self.normalizedKeys = Set(self.items.map { GroceryItemNameNormalizer.normalizedKey(for: $0.name) })
        self.dataRevision = 1
    }

    @discardableResult
    func addItem(rawName: String, category: GroceryCategory) -> GroceryAddItemResult {
        guard let name = GroceryItemNameNormalizer.displayName(from: rawName) else {
            return .emptyName
        }
        let key = GroceryItemNameNormalizer.normalizedKey(for: rawName)
        guard !normalizedKeys.contains(key) else {
            return .duplicate
        }
        let item = GroceryItem(name: name, category: category)
        items.insert(item, at: 0)
        normalizedKeys.insert(key)
        noteItemsMutated()
        return .added
    }

    func toggleCompleted(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isCompleted.toggle()
        noteItemsMutated()
    }

    func deleteItem(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let key = GroceryItemNameNormalizer.normalizedKey(for: items[idx].name)
        items.remove(at: idx)
        normalizedKeys.remove(key)
        noteItemsMutated()
    }

    func deleteItems(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let idSet = Set(ids)
        let beforeCount = items.count
        items.removeAll { item in
            guard idSet.contains(item.id) else { return false }
            let key = GroceryItemNameNormalizer.normalizedKey(for: item.name)
            normalizedKeys.remove(key)
            return true
        }
        if items.count != beforeCount {
            noteItemsMutated()
        }
    }

    func clearAll() {
        guard !items.isEmpty else { return }
        items.removeAll(keepingCapacity: false)
        normalizedKeys.removeAll(keepingCapacity: false)
        noteItemsMutated()
    }

    /// Same order as `items`: newest additions first (no sort allocation).
    var recentItems: [GroceryItem] { items }

    var totalCount: Int { items.count }

    func count(for category: GroceryCategory) -> Int {
        categoryTallies()[category] ?? 0
    }

    var categoryCounts: [(GroceryCategory, Int)] {
        let tallies = categoryTallies()
        return GroceryCategory.allCases.compactMap { c in
            let n = tallies[c] ?? 0
            return n > 0 ? (c, n) : nil
        }
    }

    /// Number of categories represented in the list (for full-list header stats).
    var distinctCategoryCount: Int {
        categoryCounts.count
    }

    /// Short label for “Recent” stat in the full list header.
    var recentActivityHeadline: String {
        guard !items.isEmpty else { return "—" }
        let cal = Calendar.current
        return items.contains { cal.isDateInToday($0.createdAt) } ? "Today" : "—"
    }

    private func categoryTallies() -> [GroceryCategory: Int] {
        if let cachedCategoryTallies {
            return cachedCategoryTallies
        }
        guard !items.isEmpty else {
            let empty: [GroceryCategory: Int] = [:]
            cachedCategoryTallies = empty
            return empty
        }
        var tallies: [GroceryCategory: Int] = [:]
        tallies.reserveCapacity(GroceryCategory.allCases.count)
        for item in items {
            tallies[item.category, default: 0] += 1
        }
        cachedCategoryTallies = tallies
        return tallies
    }

    private func noteItemsMutated() {
        cachedCategoryTallies = nil
        dataRevision &+= 1
    }
}
