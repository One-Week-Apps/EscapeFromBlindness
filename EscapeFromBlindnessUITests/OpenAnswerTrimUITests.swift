//
//  Created by Michael Martinez on 27/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

/// Réponse ouverte : des espaces en trop autour de la bonne réponse ne la rendent pas fausse.
final class OpenAnswerTrimUITests: XCTestCase {

    private let timeout: TimeInterval = 5
    private let answerFieldIdentifier = "openQuestion.answerField"
    private let verdictIdentifier = "openQuestion.verdict"

    override func setUp() {
        continueAfterFailure = false
    }

    /// `-UITestReponseOuverte` ouvre directement la première question ouverte du jeu (chapitre 3, réponse « heo » en français),
    /// champ de réponse déjà actif : sur le simulateur, un tap sur le champ ne lui donnait pas le focus clavier.
    func testReponseOuverteAvecEspacesEnTropEstAcceptee() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReponseOuverte", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let answerField = app.textFields[answerFieldIdentifier]
        XCTAssertTrue(answerField.waitForExistence(timeout: timeout))
        XCTAssertEqual(answerField.label, "Ta réponse")
        let hasFocus = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: answerField)
        XCTAssertEqual(XCTWaiter.wait(for: [hasFocus], timeout: timeout), .completed, "Le champ de réponse doit recevoir le focus clavier")
        answerField.typeText("  heo   ")
        answerField.typeText("\n")

        let verdict = app.staticTexts[verdictIdentifier]
        XCTAssertTrue(verdict.waitForExistence(timeout: timeout))
        XCTAssertEqual(verdict.label, "Réponse acceptée")

        AITaskerCapture.captureScreen(nodeId: "ReponseOuverte", action: "réponse avec espaces saisie et acceptée")
    }
}
