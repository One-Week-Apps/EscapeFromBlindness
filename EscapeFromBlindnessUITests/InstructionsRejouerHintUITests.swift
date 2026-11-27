//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class InstructionsRejouerHintUITests: XCTestCase {

    /// Le bouton n'apparaît qu'après le défilement des 6 instructions de fin : sous `-UITestGameEnd`, la cadence est réduite (quelques ms).
    private let timeout: TimeInterval = 5
    private let replayButtonIdentifier = "instructions.replayButton"
    private let lastInstructionIdentifier = "finDeJeu.derniereConsigne"
    private let expectedLabel = "Rejouer !"
    private let lastParagraph = "Cela peut être un scénario totalement différent mais qui reste basé sur les modes de jeu auxquels tu as pu jouer !"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Opens the game end instructions screen directly, the one offering "Replay".
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
        // XCUITest does not expose accessibilityHint: the value is covered by InstructionsRejouerHintTests.

        let lastParagraphElement = app.staticTexts[lastInstructionIdentifier]
        XCTAssertTrue(lastParagraphElement.waitForExistence(timeout: timeout))
        XCTAssertEqual(lastParagraphElement.label, lastParagraph)
        XCTAssertFalse(app.buttons[lastParagraph].exists)

        AITaskerCapture.captureScreen(nodeId: "Instructions", action: "Écran des instructions affiché, bouton Rejouer avec indice VoiceOver")
    }

}
