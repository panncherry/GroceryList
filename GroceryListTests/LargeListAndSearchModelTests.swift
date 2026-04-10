//
//  LargeListAndSearchModelTests.swift
//  GroceryListTests
//

import XCTest
@testable import GroceryList

@MainActor
final class LargeListAndSearchModelTests: XCTestCase {
    func testDataRevisionIncrementsOnMutation() {
        let store = GroceryListStore()
        XCTAssertEqual(store.dataRevision, 1)
        _ = store.addItem(rawName: "A", category: .dairy)
        XCTAssertEqual(store.dataRevision, 2)
        store.clearAll()
        XCTAssertEqual(store.dataRevision, 3)
    }

    func testFilterAndGroupLargeSnapshotPrefixConsistency() {
        let items = LargeListGroceryItemFactory.makeItems(count: 5_000)
        let grouped = GroceryListFiltering.filterAndGroup(
            items: items,
            searchText: "Item 1",
            category: nil
        )
        let flat = grouped.flatMap(\.1)
        XCTAssertFalse(flat.isEmpty)
        XCTAssertTrue(flat.allSatisfy { $0.name.hasPrefix("Item 1") })
    }

    func testSearchModelClearsDebounceWhenSearchEmptied() {
        let store = GroceryListStore(items: [GroceryItem(name: "Milk", category: .dairy)])
        let model = IngredientListSearchModel(debounceNanoseconds: 500_000_000)
        model.searchFieldText = "x"
        model.onSearchFieldChanged(store: store)
        XCTAssertTrue(model.isSearchDebouncePending)
        model.searchFieldText = "   "
        model.onSearchFieldChanged(store: store)
        XCTAssertFalse(model.isSearchDebouncePending)
        XCTAssertFalse(model.groupedSections.isEmpty)
    }

    func testLargeListAsyncFilterCompletes() async throws {
        let store = GroceryListStore.previewLargeList(itemCount: 11_000)
        let model = IngredientListSearchModel(debounceNanoseconds: 220_000_000, heavyListThreshold: 10_000)
        model.searchFieldText = "Item 100"
        model.recomputeImmediately(store: store)

        if model.isFilteringLargeList {
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }

        XCTAssertFalse(model.isFilteringLargeList, "Large-list filter should finish within timeout")
        XCTAssertFalse(model.groupedSections.isEmpty)
    }
}
