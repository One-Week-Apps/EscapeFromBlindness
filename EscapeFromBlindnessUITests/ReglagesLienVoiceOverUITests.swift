//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class ReglagesLienVoiceOverUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let lienVoiceOverIdentifier = "reglagesLienVoiceOver"
    private let aideVoiceOver = "Dans l’app Réglages, va dans Accessibilité puis VoiceOver pour activer le lecteur d’écran."

    override func setUp() {
        continueAfterFailure = false
    }

    func testOuvrirLeLienVoiceOverDesReglages() {
        let app = XCUIApplication()
        // `-UITestReglages` ouvre directement les Réglages, au-dessus de la sélection des niveaux.
        app.launchArguments = ["-UITestReglages", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let lien = app.descendants(matching: .any)[lienVoiceOverIdentifier]
        XCTAssertTrue(lien.waitForExistence(timeout: timeout))

        XCTAssertEqual(lien.label, "VoiceOver")
        XCTAssertEqual(lien.elementType, .button)
        XCTAssertTrue(app.buttons[lienVoiceOverIdentifier].isHittable)
        XCTAssertGreaterThanOrEqual(lien.frame.height, 44)

        // Le texte d'aide se lit comme un texte, jamais comme un bouton.
        XCTAssertTrue(app.staticTexts[aideVoiceOver].exists)
        XCTAssertFalse(app.buttons[aideVoiceOver].exists)

        AITaskerCapture.captureScreen(nodeId: "Reglages", action: "Lien VoiceOver affiché")
    }

}
