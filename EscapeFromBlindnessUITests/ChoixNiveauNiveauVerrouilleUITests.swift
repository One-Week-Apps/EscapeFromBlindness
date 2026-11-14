//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class ChoixNiveauNiveauVerrouilleUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    /// `-UITestChoixNiveau` opens the screen with level 1 of chapter 1 in progress: level 3 is locked.
    private let lockedLevelIdentifier = "levelSelection.level.1.3"

    override func setUp() {
        continueAfterFailure = false
    }

    func testNiveauVerrouilleEstAnnonceAvecSonNom() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestChoixNiveau", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let lockedLevel = app.descendants(matching: .any)[lockedLevelIdentifier]
        XCTAssertTrue(lockedLevel.waitForExistence(timeout: timeout))

        XCTAssertEqual(lockedLevel.label, "Niveau 3, verrouillé")
        XCTAssertTrue((lockedLevel.value as? String)?.isEmpty ?? true)
        XCTAssertEqual(lockedLevel.elementType, .staticText)
        XCTAssertFalse(app.buttons[lockedLevelIdentifier].exists)

        AITaskerCapture.captureScreen(nodeId: "ChoixNiveau", action: "Niveau verrouillé affiché")
    }

}
