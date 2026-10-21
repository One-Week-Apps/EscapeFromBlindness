//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class AccessibiliteVersionEtSousTitreUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "homeVersionLabel"
    private let subtitleIdentifier = "levelSelectionSubtitle"
    /// Libellé VoiceOver du bouton qui ramène d'un niveau à l'écran de chargement (`LevelBaseViewController`).
    private let menuLabel = "Menu"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur l'accueil, qui est l'écran de chargement de niveau.
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

    func testLireLaVersionEtLeSousTitreDuChargement() {
        let app = launchHome()

        let version = app.staticTexts[versionIdentifier]
        XCTAssertTrue(version.waitForExistence(timeout: timeout))
        XCTAssertEqual(version.elementType, .staticText)
        XCTAssertFalse(app.buttons[versionIdentifier].exists, "La version ne doit pas être annoncée comme un bouton")
        AITaskerCapture.captureScreen(nodeId: "Accueil", action: "Version lue comme un texte sur l'accueil")

        // Toucher le niveau 1 ouvre le niveau ; son bouton « Menu » ramène à l'écran de chargement de niveau.
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
