//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class AccessibiliteVersionEtSousTitreUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let subtitleIdentifier = "levelSelectionSubtitle"
    /// VoiceOver label of the button that goes back from a level to the level loading screen (`LevelBaseViewController`).
    private let menuLabel = "Menu"

    override func setUp() {
        continueAfterFailure = false
    }

    /// A player who already made progress lands on the home screen, which is the level loading screen.
    private func launchHome() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ]
        app.launch()
        return app
    }

    // The version number left the home screen (#10): only the loading screen subtitle remains to check.
    func testLireLeSousTitreDuChargement() {
        let app = launchHome()

        // Tapping level 1 opens the level; its "Menu" button goes back to the level loading screen.
        let firstLevel = app.collectionViews.firstMatch.cells.element(boundBy: 0)
        XCTAssertTrue(firstLevel.waitForExistence(timeout: timeout))
        firstLevel.tap()

        let menuButton = app.navigationBars.buttons[menuLabel]
        XCTAssertTrue(menuButton.waitForExistence(timeout: timeout))
        menuButton.tap()

        let subtitle = app.descendants(matching: .any)[subtitleIdentifier]
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "ChargementNiveau", action: "Sous-titre de l'écran de chargement de niveau présent")
    }

}
