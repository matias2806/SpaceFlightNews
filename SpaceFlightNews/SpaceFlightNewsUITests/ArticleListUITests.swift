// SpaceFlightNewsUITests/ArticleListUITests.swift
//
// Scope: only what is reliably testable without hardcoded accessibility
// identifiers. The search bar is the most stable signal because it only
// appears AFTER the first page loads (.success state).
//
// The "Cancel" button was removed from the search test: its label is
// locale-dependent ("Cancel" in English, "Cancelar" in Spanish) and
// varies with the simulator's system language. Verifying the typed text
// appears in the field is sufficient and locale-agnostic.

import XCTest

final class ArticleListUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Loading

    /// The search bar is injected only when state == .success.
    /// Its appearance proves the first page loaded and the splash dismissed.
    func test_articlesLoad_searchBarBecomesVisible() {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 15),
            "Search bar should appear once the first page of articles loads"
        )
    }

    // MARK: - Search interaction

    func test_search_typingTextAppearsInField() {
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 15) else {
            return XCTFail("Search bar did not appear — articles may not have loaded")
        }

        searchField.tap()
        searchField.typeText("space")

        XCTAssertEqual(
            searchField.value as? String, "space",
            "Typed text should appear in the search field"
        )
    }
}
