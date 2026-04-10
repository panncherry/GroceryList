//
//  GroceryListUITests.swift
//  GroceryListUITests
//

import XCTest

final class GroceryListUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddItemNavigationSearchAndBack() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Grocery List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add New Item"].exists)

        let nameField = app.textFields["mainItemNameTextField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Milk")

        app.buttons["Vegetables category"].tap()
        app.buttons["Dairy category"].tap()

        app.buttons["Add Item"].tap()

        XCTAssertTrue(app.staticTexts["Milk"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Shopping Stats"].exists)
        XCTAssertTrue(app.staticTexts["Milk"].exists)

        app.buttons["View Full Grocery List"].tap()
        XCTAssertTrue(app.staticTexts["Full Grocery List"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Total Items"].exists)

        let searchField = app.textFields["fullListSearchTextField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("mi")
        // Search is debounced (~220ms); wait before asserting filtered rows.
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertTrue(app.staticTexts["Milk"].exists)

        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Add New Item"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
