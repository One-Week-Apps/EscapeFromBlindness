//
//  SearchLevelLayoutUITests.swift
//

import XCTest

final class SearchLevelLayoutUITests: XCTestCase {

    private let timeout: TimeInterval = 10

    override func setUp() {
        continueAfterFailure = false
    }

    /// Chapter 4: the room description must start below the navigation bar, not under its buttons.
    func testRoomDescriptionStartsBelowTheNavigationBar() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "4",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ]
        app.launch()

        let tile = app.descendants(matching: .any)["tuileNiveau_4_1"]
        XCTAssertTrue(tile.waitForExistence(timeout: timeout))
        tile.tap()

        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: timeout))
        let description = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Tu approches'")).firstMatch
        XCTAssertTrue(description.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "NiveauRecherche", action: "Ouverture du premier niveau du chapitre 4")

        XCTAssertGreaterThanOrEqual(description.frame.minY, navigationBar.frame.maxY)
    }
}
