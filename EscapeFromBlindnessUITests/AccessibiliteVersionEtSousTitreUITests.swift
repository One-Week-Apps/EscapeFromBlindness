//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class AccessibiliteVersionEtSousTitreUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let versionIdentifier = "homeVersionLabel"
    private let subtitleIdentifier = "levelSelectionSubtitle"

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

        let subtitle = app.descendants(matching: .any)[subtitleIdentifier]
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        AITaskerCapture.captureScreen(nodeId: "ChargementNiveau", action: "Sous-titre de l'écran de chargement de niveau présent")
    }

}
