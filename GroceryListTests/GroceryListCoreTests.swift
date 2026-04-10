//
//  GroceryListCoreTests.swift
//  GroceryListTests
//

import XCTest
@testable import GroceryList

@MainActor
final class GroceryListCoreTests: XCTestCase {
    func testNormalizerTrimsAndCollapsesWhitespace() {
        XCTAssertEqual(GroceryItemNameNormalizer.normalizedKey(for: "  Milk "), "milk")
        XCTAssertEqual(GroceryItemNameNormalizer.normalizedKey(for: "Ice   Cream"), "ice cream")
    }

    func testDisplayNameRejectsEmptyOrWhitespace() {
        XCTAssertNil(GroceryItemNameNormalizer.displayName(from: ""))
        XCTAssertNil(GroceryItemNameNormalizer.displayName(from: "   \n\t "))
    }

    func testAddValidItem() {
        let store = GroceryListStore()
        XCTAssertEqual(store.addItem(rawName: "Milk", category: .dairy), GroceryAddItemResult.added)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.name, "Milk")
        XCTAssertEqual(store.items.first?.category, .dairy)
    }

    func testSequentialAddsPlaceNewestFirst() {
        let store = GroceryListStore()
        XCTAssertEqual(store.addItem(rawName: "First", category: .dairy), GroceryAddItemResult.added)
        XCTAssertEqual(store.addItem(rawName: "Second", category: .fruits), GroceryAddItemResult.added)
        XCTAssertEqual(store.items.map(\.name), ["Second", "First"])
    }

    func testRejectEmptyName() {
        let store = GroceryListStore()
        XCTAssertEqual(store.addItem(rawName: "", category: .dairy), GroceryAddItemResult.emptyName)
        XCTAssertEqual(store.addItem(rawName: "   ", category: .dairy), GroceryAddItemResult.emptyName)
    }

    func testDuplicatePreventionIsCaseAndWhitespaceInsensitive() {
        let store = GroceryListStore()
        XCTAssertEqual(store.addItem(rawName: "Milk", category: .dairy), GroceryAddItemResult.added)
        XCTAssertEqual(store.addItem(rawName: " milk ", category: .vegetables), GroceryAddItemResult.duplicate)
        XCTAssertEqual(store.items.count, 1)
    }

    func testRecentItemsNewestFirst() {
        let older = Date(timeIntervalSince1970: 100)
        let newer = Date(timeIntervalSince1970: 200)
        let store = GroceryListStore(items: [
            GroceryItem(name: "A", category: .dairy, createdAt: older),
            GroceryItem(name: "B", category: .fruits, createdAt: newer)
        ])
        XCTAssertEqual(store.recentItems.map(\.name), ["B", "A"])
    }

    func testDeleteSingleItem() throws {
        let store = GroceryListStore()
        _ = store.addItem(rawName: "Eggs", category: .dairy)
        let id = try XCTUnwrap(store.items.first?.id)
        store.deleteItem(id: id)
        XCTAssertTrue(store.items.isEmpty)
    }

    func testClearAll() {
        let store = GroceryListStore()
        _ = store.addItem(rawName: "A", category: .breads)
        _ = store.addItem(rawName: "B", category: .meats)
        store.clearAll()
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertEqual(store.addItem(rawName: "A", category: .breads), GroceryAddItemResult.added)
    }

    func testStatisticsCounts() {
        let store = GroceryListStore()
        _ = store.addItem(rawName: "Milk", category: .dairy)
        _ = store.addItem(rawName: "Cheese", category: .dairy)
        _ = store.addItem(rawName: "Carrot", category: .vegetables)
        XCTAssertEqual(store.totalCount, 3)
        XCTAssertEqual(store.count(for: .dairy), 2)
        XCTAssertEqual(store.count(for: .vegetables), 1)
        XCTAssertEqual(store.count(for: .fruits), 0)
    }

    func testSearchPrefixCaseInsensitive() {
        let items = [
            GroceryItem(name: "Milk", category: .dairy),
            GroceryItem(name: "Mint", category: .vegetables),
            GroceryItem(name: "Almond Milk", category: .dairy)
        ]
        let filtered = GroceryListFiltering.filter(items: items, searchText: "mi", category: nil)
        XCTAssertEqual(Set(filtered.map(\.name)), Set(["Milk", "Mint"]))
    }

    func testSearchEmptyRestoresAllSubjectToCategory() {
        let items = [
            GroceryItem(name: "A", category: .dairy),
            GroceryItem(name: "B", category: .vegetables)
        ]
        let all = GroceryListFiltering.filter(items: items, searchText: "", category: nil)
        XCTAssertEqual(all.count, 2)
    }

    func testCategoryFilter() {
        let items = [
            GroceryItem(name: "Milk", category: .dairy),
            GroceryItem(name: "Carrot", category: .vegetables)
        ]
        let veg = GroceryListFiltering.filter(items: items, searchText: "", category: .vegetables)
        XCTAssertEqual(veg.map(\.name), ["Carrot"])
    }

    func testCombinedSearchAndCategory() {
        let items = [
            GroceryItem(name: "Carrot", category: .vegetables),
            GroceryItem(name: "Cardamom", category: .vegetables),
            GroceryItem(name: "Cabbage", category: .vegetables)
        ]
        let result = GroceryListFiltering.filter(items: items, searchText: "car", category: .vegetables)
        XCTAssertEqual(Set(result.map(\.name)), Set(["Carrot", "Cardamom"]))
    }

    func testKeywordInferenceSelectsCategoryByLongestMatch() {
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "apple"), .fruits)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "Apple"), .fruits)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "milk"), .dairy)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "carrot"), .vegetables)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "beef"), .meats)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "bread"), .breads)
        XCTAssertEqual(GroceryKeywordInference.inferredCategory(for: "ice cream"), .dairy)
    }

    func testKeywordInferenceEmptyOrUnknownReturnsNil() {
        XCTAssertNil(GroceryKeywordInference.inferredCategory(for: ""))
        XCTAssertNil(GroceryKeywordInference.inferredCategory(for: "   "))
        XCTAssertNil(GroceryKeywordInference.inferredCategory(for: "xyz"))
    }

    func testToggleCompleted() {
        let store = GroceryListStore()
        _ = store.addItem(rawName: "Milk", category: .dairy)
        let id = store.items[0].id
        XCTAssertFalse(store.items[0].isCompleted)
        store.toggleCompleted(id: id)
        XCTAssertTrue(store.items[0].isCompleted)
        store.toggleCompleted(id: id)
        XCTAssertFalse(store.items[0].isCompleted)
    }

    func testGroupedByCategorySortsNames() {
        let items = [
            GroceryItem(name: "Zebra Milk", category: .dairy),
            GroceryItem(name: "Almond Milk", category: .dairy)
        ]
        let grouped = GroceryListFiltering.groupedByCategory(items)
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].1.map(\.name), ["Almond Milk", "Zebra Milk"])
    }
}
