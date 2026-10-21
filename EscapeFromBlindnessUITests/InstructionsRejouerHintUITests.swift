//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class InstructionsRejouerHintUITests: XCTestCase {

    /// Le bouton n'apparaît qu'après le défilement des 6 instructions de fin (une toutes les 5 s).
    private let timeout: TimeInterval = 45
    private let replayButtonIdentifier = "instructions.replayButton"
    private let expectedLabel = "Rejouer !"
    private let lastParagraph = "Cela peut être un scénario totalement différent mais qui reste basé sur les modes de jeu auxquels tu as pu jouer !"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Ouvre directement l'écran des instructions de fin de jeu, celui qui propose « Rejouer ».
    private func launchInstructions() -> XCUIApplication {
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

    func testRejouerAUnIndiceVoiceOver() {
        let app = launchInstructions()

        let replayButton = app.buttons[replayButtonIdentifier]
        XCTAssertTrue(replayButton.waitForExistence(timeout: timeout))
        XCTAssertEqual(replayButton.identifier, replayButtonIdentifier)
        XCTAssertEqual(replayButton.label, expectedLabel)
        // XCUITest n'expose pas accessibilityHint : la valeur est couverte par InstructionsRejouerHintTests.

        XCTAssertTrue(app.staticTexts[lastParagraph].exists)
        XCTAssertFalse(app.buttons[lastParagraph].exists)

        AITaskerCapture.captureScreen(nodeId: "Instructions", action: "Écran des instructions affiché, bouton Rejouer avec indice VoiceOver")
    }

}
