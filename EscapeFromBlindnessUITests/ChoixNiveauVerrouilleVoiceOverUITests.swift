//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class ChoixNiveauVerrouilleVoiceOverUITests: XCTestCase {

    private let timeout: TimeInterval = 5
    /// `-UITestChoixNiveau` ouvre l'écran avec le niveau 1 du chapitre 1 en cours : le niveau 3 est verrouillé.
    private let unlockedLevelIdentifier = "levelSelection.level.1.1"
    private let lockedLevelIdentifier = "levelSelection.level.1.3"

    override func setUp() {
        continueAfterFailure = false
    }

    func testNiveauVerrouilleLuVerrouille() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestChoixNiveau", "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let lockedLevel = app.descendants(matching: .any)[lockedLevelIdentifier]
        XCTAssertTrue(lockedLevel.waitForExistence(timeout: timeout))

        XCTAssertTrue(lockedLevel.label.contains("verrouillé"), lockedLevel.label)
        XCTAssertEqual(lockedLevel.label, "Niveau 3, verrouillé")
        XCTAssertNotEqual(lockedLevel.elementType, .button)
        XCTAssertFalse(app.buttons[lockedLevelIdentifier].exists)

        XCTAssertTrue(app.buttons[unlockedLevelIdentifier].exists)

        AITaskerCapture.captureScreen(nodeId: "ChoixNiveau", action: "Niveau verrouillé vérifié")
    }

}
