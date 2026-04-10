//
//  LargeListGroceryItemFactory.swift
//  GroceryList
//

import Foundation

/// Builds large in-memory lists for stress testing, previews, and performance tests.
enum LargeListGroceryItemFactory: Sendable {
    /// Deterministic names and category rotation for stable benchmarks.
    static func makeItems(
        count: Int,
        baseDate: Date = Date()
    ) -> [GroceryItem] {
        guard count > 0 else { return [] }
        let categories = GroceryCategory.allCases
        return (0..<count).map { index in
            GroceryItem(
                name: "Item \(index)",
                category: categories[index % categories.count],
                createdAt: baseDate.addingTimeInterval(-TimeInterval(index))
            )
        }
    }
}

extension GroceryListStore {
    /// MainActor: use from previews, tests, and debug menus — not from background threads.
    @MainActor
    static func previewLargeList(itemCount: Int) -> GroceryListStore {
        GroceryListStore(items: LargeListGroceryItemFactory.makeItems(count: itemCount))
    }
}
