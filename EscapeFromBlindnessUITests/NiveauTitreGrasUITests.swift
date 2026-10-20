//
//  Created by Michael Martinez on 21/10/2026.
//  Copyright © 2026 michael-martinez. All rights reserved.
//

import XCTest

final class NiveauTitreGrasUITests: XCTestCase {

    private let timeout: TimeInterval = 10
    private let titleIdentifier = "levelSelectionSubtitle"
    private let expectedTitle = "Choisis ton niveau"

    override func setUp() {
        continueAfterFailure = false
    }

    /// Un joueur qui a déjà progressé arrive sur la sélection des niveaux au lancement : c'est le chemin habituel vers cet écran.
    private func launchLevelSelection() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-com.accessibility-toolbox.userdefaults.current-chapter-index", "1",
            "-com.accessibility-toolbox.userdefaults.current-level-index", "0",
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"
        ]
        app.launch()
        return app
    }

    func testTitreChoisisTonNiveauAffiche() {
        let app = launchLevelSelection()

        let title = app.descendants(matching: .any)[titleIdentifier]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, expectedTitle)

        AITaskerCapture.captureScreen(nodeId: "ChoixNiveau", action: "Écran affiché avec le titre en gras")
    }

}
