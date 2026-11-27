//
//  Created by Michael Martinez on 27/11/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class OpenAnswerTrimUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// `-UITestReponseOuverte` opens the first open question of chapter 3 directly (answer "heo" in French).
    /// A right answer opens the next question: that is the "correct answer" feedback of the game.
    func testReponseOuverteAvecEspacesEnTropEstAcceptee() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReponseOuverte", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let question = app.staticTexts["openQuestion.question"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
        let firstQuestion = question.label

        let answerField = app.textFields.firstMatch
        XCTAssertTrue(answerField.waitForExistence(timeout: 5))
        answerField.tap()
        answerField.typeText("  heo  \n")

        let nextQuestion = app.staticTexts.matching(identifier: "openQuestion.question")
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Hum. La porte d'entrée")).firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5))
        XCTAssertNotEqual(nextQuestion.label, firstQuestion)
        AITaskerCapture.captureScreen(nodeId: "ReponseOuverte", action: "Validation de « heo » entouré d'espaces : la question suivante s'affiche")
    }
}
