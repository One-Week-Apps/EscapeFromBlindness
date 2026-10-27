//
//  Created by Michael Martinez on 23/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class ReglagesLienVoiceOverUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let boutonReglagesIdentifier = "activationVoiceOver.ouvrirReglages"
    private let consignesIdentifier = "activationVoiceOver.consignes"

    override func setUp() {
        continueAfterFailure = false
    }

    func testOuvrirLesReglagesDepuisVoiceOver() {
        let app = XCUIApplication()
        // `-UITestActivationVoiceOver` ouvre directement l'écran qui explique l'activation de VoiceOver.
        app.launchArguments = ["-UITestActivationVoiceOver", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let bouton = app.buttons[boutonReglagesIdentifier]
        XCTAssertTrue(bouton.waitForExistence(timeout: timeout))
        XCTAssertEqual(bouton.label, "Ouvrir les Réglages")
        XCTAssertGreaterThanOrEqual(bouton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(bouton.frame.height, 44)

        // Le texte explicatif se lit comme un texte, jamais comme un bouton, et le bouton vient dessous.
        let consignes = app.staticTexts[consignesIdentifier]
        XCTAssertTrue(consignes.exists)
        XCTAssertFalse(app.buttons[consignesIdentifier].exists)
        XCTAssertGreaterThan(bouton.frame.minY, consignes.frame.minY)

        AITaskerCapture.captureScreen(nodeId: "Reglages", action: "lien VoiceOver visible")
    }

}
