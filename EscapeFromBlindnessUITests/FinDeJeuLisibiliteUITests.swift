//
//  Created by Michael Martinez on 06/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class FinDeJeuLisibiliteUITests: XCTestCase {

    /// Le bouton n'apparaît qu'après le défilement des consignes de fin : sous `-UITestGameEnd`, la cadence est réduite (quelques ms).
    private let timeout: TimeInterval = 5
    private let replayButtonIdentifier = "instructions.replayButton"
    private let lastInstructionIdentifier = "finDeJeu.derniereConsigne"
    private let expectedReplayLabel = "Rejouer !"
    private let lastInstruction = "Cela peut être un scénario totalement différent mais qui reste basé sur les modes de jeu auxquels tu as pu jouer !"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Ouvre directement l'écran de fin de jeu, en français.
    private func launchFinDeJeu() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR",
            "-UITestGameEnd"
        ]
        app.launch()
        return app
    }

    /// « Rejouer » n'apparaît qu'après la dernière consigne : toutes ont défilé, la dernière est posée.
    func testAfficherFinDeJeu() {
        let app = launchFinDeJeu()

        let replayButton = app.buttons[replayButtonIdentifier]
        XCTAssertTrue(replayButton.waitForExistence(timeout: timeout))
        XCTAssertEqual(replayButton.label, expectedReplayLabel)

        let lastInstructionElement = app.staticTexts[lastInstructionIdentifier]
        XCTAssertTrue(lastInstructionElement.waitForExistence(timeout: timeout))
        XCTAssertEqual(lastInstructionElement.label, lastInstruction)

        AITaskerCapture.captureScreen(nodeId: "FinDeJeu", action: "toutes les consignes affichées")
    }

}
